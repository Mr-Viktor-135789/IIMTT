function [el, az, dist, fhAz, fhEl] = calcSVAzAndElNested(svCoord, userCoord, lat, lon)
%CALCSVAZANDELNESTED Вложенные функции для расчёта углов через ENU.

if nargin < 4
    [lat, lon, ~] = ecef2lla(userCoord(:)');
end

lat = deg2rad(lat);
lon = deg2rad(lon);

D = svCoord - userCoord;

sinL = sin(lon);  cosL = cos(lon);
sinB = sin(lat);  cosB = cos(lat);

R = [ -sinL,             cosL,             0;
      -sinB*cosL, -sinB*sinL,       cosB;
       cosB*cosL,  cosB*sinL,       sinB ];

enu = R * D;

E = enu(1,:);
N = enu(2,:);
U = enu(3,:);

dist = sqrt(sum(D.^2, 1));

el = calcEl();
az = calcAz();

fhAz = @calcAz;
fhEl = @calcEl;

    function azOut = calcAz()
        azOut = mod(atan2(E, N), 2*pi);
    end

    function elOut = calcEl()
        elOut = asin(U ./ dist);
    end
end