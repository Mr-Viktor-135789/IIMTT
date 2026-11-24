function [x, y, z] = geodeticToECEF(lat, lon, h, inDegrees)
%GEODETICTOECEF Перевод геодезических координат в ECEF.
%   [X,Y,Z] = geodeticToECEF(LAT,LON,H) — углы в градусах.
%   [X,Y,Z] = geodeticToECEF(LAT,LON,H,false) — углы в радианах.

if nargin < 4
    inDegrees = true;
end

if inDegrees
    lat = deg2rad(lat);
    lon = deg2rad(lon);
end

a = 6378137;
b = 6356752.31424518;
f = 1 - b/a;
e2 = f*(2 - f);

N = a / sqrt(1 - e2*sin(lat)^2);

x = (N + h) * cos(lat) * cos(lon);
y = (N + h) * cos(lat) * sin(lon);
z = (N*(1 - e2) + h) * sin(lat);
end