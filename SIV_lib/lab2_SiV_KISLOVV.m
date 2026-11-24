clc; clear; close all;

%% Reading almanac
[almanac, tParameters] = ReadGPSAlmanac();

assert(isequal(size(almanac),[11 32]) && isequal(size(tParameters),[2 32]) && ndims(almanac)==2, ...
       'Неожиданные размеры almanac/tParameters');
fprintf('size(almanac)=%s  size(tParameters)=%s  ndims=%d  numel=%d  length=%d\n', ...
        mat2str(size(almanac)), mat2str(size(tParameters)), ...
        ndims(almanac), numel(almanac), length(almanac));

if almanac(3,1) > 0.3
    angleMode = 'rad_full';          
else
    angleMode = 'semicircles_deltaI'; 
end
fprintf('almanac(3,1)=%.6f -> angleMode=%s\n', almanac(3,1), angleMode);

%% Almanac of one satellite
nomer_sputnika = input('Введите номер спутника от 1 до 32: ');
validateattributes(nomer_sputnika,{'numeric'},{'scalar','integer','>=',1,'<=',32});

imena = ["Eccentricity";"Toa";"deltaI";"OmegaDot";"sqrtA"; ...
            "Omega0";"omega";"M0";"af0";"af1";"satNo"];
edinitsy= ["-";"s";"rad";"rad/s";"m^0.5";"rad";"rad";"rad";"s";"s/s";"-"];

fprintf('\nPRN %d:\n', nomer_sputnika);
for k = 1:11
    fprintf('%-14s %+ .6e  %s\n', imena(k), almanac(k,nomer_sputnika), edinitsy(k));
end
T = table(imena, almanac(:,nomer_sputnika), edinitsy, ...
          'VariableNames',{'Parameter','Value','Units'});
disp(T)

%% Almanac of four random satellites
indeksy = randperm(32,4);                     
a13 = reshape(almanac(:,indeksy), 11, 1, 4);     
a12_squeeze = squeeze(a13);
a12_reshape = reshape(a13, 11, 4);
fprintf('\nsqueeze == reshape : %d\n', isequal(a12_squeeze, a12_reshape));

%% ECC > 0.01
maska = almanac(1,:) > 0.01;
fprintf('\nСпутники с e>0.01: %s\n', mat2str(almanac(11,maska)));
fprintf('  e>0.01: %d ; e<=0.01: %d\n', sum(maska), sum(~maska));

%% Almanac time
gpsEpoch = datetime(1980,1,6,0,0,0,'TimeZone','UTC');
weekFull = tParameters(1,1);            % номер недели по модулю 1024
toa      = almanac(2,1);
assert(all(tParameters(1,:)==weekFull) && all(almanac(2,:)==toa), ...
       'weekNo или toa различаются между спутниками');

% Полный номер недели: цикл определяется датой скачивания файла.
% Для 2026 г. это 3-й цикл (2019-04-07 … 2038-11-20): weekCycle=2.
weekCycle = 2;
weekFullReal = weekCycle*1024 + weekFull;

alTime = [weekFull, toa]; 
alDate = gpsEpoch + days(7*weekFullReal) + seconds(toa);
alDate.Format = 'yyyy-MM-dd HH:mm:ss';
fprintf('\nalTime=[%d, %.1f] (mod 1024) ; полная неделя=%d ; дата альманаха: %s\n', ...
        alTime(1), alTime(2), weekFullReal, alDate);

%% User time
utcDate = '24/11/2026 10:14:00';
[weekGps, tow] = UtcToGps(utcDate);
usTime = [weekGps, tow];
fprintf('usTime=[%d, %.1f]\n', usTime(1), usTime(2));

% Контрольный пример из справки
[wRef,tRef] = UtcToGps('20/09/2020 14:57:00');
fprintf('Контроль UtcToGps: week=%d (ожид.76), tow=%.1f (ожид.53836)\n', wRef, tRef);
if wRef==76 && abs(tRef-53836) < 1
    fprintf('  -> совпадает со справкой\n');
else
    fprintf('  -> НЕ совпадает со справкой (расхождение %.1f с)\n', tRef-53836);
end

%% Diff time
isSameTime = (usTime == alTime);
dTime      = usTime - alTime;
fprintf('\nisSameTime=[%d %d] ; dTime=[%+d %+.1f]\n', ...
        isSameTime(1), isSameTime(2), dTime(1), dTime(2));
whos isSameTime dTime
switch dTime(1)
    case 0,      fprintf('Одна неделя — всё в порядке.\n');
    case {1,-1}, fprintf('Соседние недели — коррекция tk.\n');
    otherwise,   fprintf('|dWeek|>1 — альманах устарел.\n');
end

%% Mean anomaly calculation
mu = 3.986005e14;

% 10.1: Mk = [M0; e; sqrtA], 3x32
Mk = [almanac(8,:); almanac(1,:); almanac(5,:)];
% 10.2
A  = Mk(3,:).^2;
n0 = sqrt(mu ./ A.^3);
tk = (usTime(1)-alTime(1))*604800 + (usTime(2)-alTime(2));
tk = mod(tk + 302400, 604800) - 302400;
assert(abs(tk) <= 302400, 'tk вне допустимого диапазона');
fprintf('\nA(1)=%.0f м ; n0(1)=%.10e рад/с ; T(1)=%.2f с ; tk=%.1f с\n', ...
        A(1), n0(1), 2*pi/n0(1), tk);
% 10.3
Mk(4,:) = mod(Mk(1,:) + n0 .* tk, 2*pi);   % рад
% 10.4
Mk = Mk(4,:);
fprintf('size(Mk)=%s (1x32, средние аномалии в рад)\n', mat2str(size(Mk)));

%% Orbit inclination
if strcmp(angleMode,'rad_full')
    i_rad = almanac(3,:);
else
    i_rad = (0.3 + almanac(3,:)) * pi;
end
i_deg = i_rad * 180/pi;

i_manual = sum(i_deg)/numel(i_deg);
i_mean   = mean(i_deg);
fprintf('\nНаклонение PRN %d: %.4f°\n', nomer_sputnika, i_deg(nomer_sputnika));
fprintf('Среднее вручную=%.6f° ; mean=%.6f° ; разность=%e°\n', ...
        i_manual, i_mean, i_manual - i_mean);

unhealthy = tParameters(2,:) ~= 0;
fprintf('svHealth~=0: %d ; среднее i без них=%.6f°\n', ...
        sum(unhealthy), mean(i_deg(~unhealthy)));