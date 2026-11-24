function [el, az, dist, fhAz, fhEl] = calcSVAzAndEl(svCoord, userCoord, lat, lon)
%CALCSVAZANDEL Углы места, азимут и дальность через ENU.

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
el = asin(U ./ dist);
az = mod(atan2(E, N), 2*pi);

fhAz = @calcAz;
fhEl = @calcEl;
end

function az = calcAz(E, N)
    az = mod(atan2(E, N), 2*pi);
end

function el = calcEl(U, R)
    el = asin(U ./ R);
end