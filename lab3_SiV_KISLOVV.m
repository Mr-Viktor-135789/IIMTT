clc; clear; close all;
addpath(fullfile(pwd, 'SiV_lib'));   % ← при необходимости SIV_lib

%% User coordinates
lat = 1.289987;
lon = 103.850281;
h   = 0;

[xu, yu, zu] = geodeticToECEF(lat, lon, h);
userCoord = [xu; yu; zu];

pLib  = lla2ecef([lat, lon, h]);
dECEF = norm([xu, yu, zu] - pLib);
fprintf('Расхождение с lla2ecef: %.3e м\n', dECEF);

%% Reading almanac
[almanac, tParameters] = ReadGPSAlmanac();
fprintf('Альманах: week = %d, toa = %.1f\n', tParameters(1,1), almanac(2,1));

%% Utc Time — 22.11.2026, 00:00 UTC
utcTime = datetime(2026, 11, 22, 0, 0, 0, 'TimeZone', 'UTC');
fprintf('Момент наблюдения: %s\n', string(utcTime));

[weekGps, tow] = UtcToGps(utcTime);
fprintf('weekGps = %d, tow = %.3f\n', weekGps, tow);

% Диагностика шага 1 с
[~, tow1] = UtcToGps(utcTime + seconds(1));
fprintf('dtow = %.6f (должно быть 1.000000)\n', tow1 - tow);

% Возраст альманаха
dWeek = mod(weekGps - tParameters(1,1) + 512, 1024) - 512;
tk    = dWeek*604800 + (tow - almanac(2,1));
fprintf('dWeek = %d, tk = %.1f с\n', dWeek, tk);
if abs(dWeek) > 1
    warning('Альманах устарел: dWeek = %d', dWeek);
end

%% Satellite Coordinates (10 спутников)
nSat = 10;
svCoord = zeros(nSat, 3);
for iSat = 1:nSat
    [xyz, ~] = calcSVCoord(almanac, [weekGps; tow], iSat, tParameters);
    svCoord(iSat,:) = xyz;
end

%% Satellite Angles
el0 = zeros(1,nSat);
az0 = zeros(1,nSat);
for iSat = 1:nSat
    [el0(iSat), az0(iSat)] = CalcSVAzimuthAndElevation( ...
        svCoord(iSat,1), svCoord(iSat,2), svCoord(iSat,3), ...
        userCoord(1), userCoord(2), userCoord(3));
end

[el, az, dist, fhAz, fhEl] = calcSVAzAndEl(svCoord.', userCoord, lat, lon);

fprintf('\nPRN   az_custom   el_custom   dist_km   az_teach   el_teach\n');
for iSat = 1:nSat
    fprintf('%3d %10.4f %11.4f %10.2f %10.4f %10.4f\n', ...
        iSat, rad2deg(az(iSat)), rad2deg(el(iSat)), dist(iSat)/1000, ...
        rad2deg(az0(iSat)), rad2deg(el0(iSat)));
end

dAz = mod(rad2deg(az) - rad2deg(az0) + 180, 360) - 180;
dEl = rad2deg(el) - rad2deg(el0);
fprintf('\nPRN   dAz, deg   dEl, deg\n');
for iSat = 1:nSat
    fprintf('%3d %10.4f %10.4f\n', iSat, dAz(iSat), dEl(iSat));
end

[elN, azN] = calcSVAzAndElNested(svCoord.', userCoord, lat, lon);
fprintf('проверка вложенной версии: max|dEl| = %.3e, max|dAz| = %.3e\n', ...
    max(abs(elN - el)), max(abs(azN - az)));

%% Sky for 24 hours
nSatAll = size(almanac, 2);
Nt = 1440;

towAll  = tow + (0:Nt-1)*60;
weekArr = weekGps + floor(towAll/604800);
towArr  = mod(towAll, 604800);
tUtc    = utcTime + minutes(0:Nt-1);

%% T1 — наивная
el1 = []; az1 = [];
tic
for it = 1:Nt
    [xuIt, yuIt, zuIt] = geodeticToECEF(lat, lon, h);
    userCoordIt = [xuIt; yuIt; zuIt];
    for is = 1:nSatAll
        [xyz, ~] = calcSVCoord(almanac, [weekArr(it); towArr(it)], is, tParameters);
        [elIt, azIt] = CalcSVAzimuthAndElevation( ...
            xyz(1), xyz(2), xyz(3), ...
            userCoordIt(1), userCoordIt(2), userCoordIt(3));
        el1(is,it) = elIt;
        az1(is,it) = azIt;
    end
end
T1 = toc;

%% T2 — предвыделение
el2 = zeros(nSatAll, Nt);
az2 = zeros(nSatAll, Nt);
tic
for it = 1:Nt
    for is = 1:nSatAll
        [xyz, ~] = calcSVCoord(almanac, [weekArr(it); towArr(it)], is, tParameters);
        [el2(is,it), az2(is,it)] = CalcSVAzimuthAndElevation( ...
            xyz(1), xyz(2), xyz(3), ...
            userCoord(1), userCoord(2), userCoord(3));
    end
end
T2 = toc;

%% T3 — векторизация
svAll = zeros(3, nSatAll, Nt);
tic
for it = 1:Nt
    for is = 1:nSatAll
        [xyz, ~] = calcSVCoord(almanac, [weekArr(it); towArr(it)], is, tParameters);
        svAll(:,is,it) = xyz(:);
    end
end
T3c = toc;

tic
[el3, az3, dist3] = calcSVAzAndEl(reshape(svAll, 3, []), userCoord, lat, lon);
el3   = reshape(el3,   nSatAll, Nt);
az3   = reshape(az3,   nSatAll, Nt);
dist3 = reshape(dist3, nSatAll, Nt);
T3a = toc;
T3 = T3c + T3a;

fprintf('\nT1 = %.1f s, T2 = %.1f s, T3c = %.1f s, T3a = %.1f s, T3 = %.1f s\n', ...
    T1, T2, T3c, T3a, T3);

%% Видимые спутники
nVis = sum(el3 > deg2rad(10), 1);
fprintf('Видимых спутников: min=%d, max=%d, mean=%.2f\n', ...
    min(nVis), max(nVis), mean(nVis));

%% Сохранение
save('sky24h.mat', 'tUtc', 'el3', 'az3', 'dist3', 'svAll', ...
    'lat', 'lon', 'h', 'almanac', 'tParameters');

fprintf('\nsky24h.mat сохранён: tUtc(1) = %s, tUtc(end) = %s\n', ...
    string(tUtc(1)), string(tUtc(end)));