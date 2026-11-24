classdef Observer
    properties
        Lat (1,1) double {mustBeInRange(Lat,-90, 90)}  = 0
        Lon (1,1) double {mustBeInRange(Lon,-180,180)} = 0
        H   (1,1) double {mustBeReal}                  = 0
    end
    properties (Dependent)
        ECEF (3,1) double
    end
    methods
        function obj = Observer(lat, lon, h)
            if nargin >= 1, obj.Lat = lat; end
            if nargin >= 2, obj.Lon = lon; end
            if nargin >= 3, obj.H   = h;   end
        end

        function value = get.ECEF(obj)
            [x, y, z] = geodeticToECEF(obj.Lat, obj.Lon, obj.H);
            value = [x; y; z];
        end

        function [az, el, dist] = look(obj, sats)
            n = numel(sats);
            svCoord = zeros(3, n);
            for k = 1:n
                svCoord(:, k) = sats(k).Position(:);
            end
            % ВАЖНО: calcSVAzAndEl возвращает [el, az, dist].
            [el_c, az_c, dist_c] = calcSVAzAndEl( ...
                svCoord, obj.ECEF, obj.Lat, obj.Lon);
            az   = az_c(:);
            el   = el_c(:);
            dist = dist_c(:);
        end

        function [visSats, T] = visible(obj, sats, mask)
            if nargin < 3, mask = 0; end
            [az, el, dist] = obj.look(sats);

            idx     = find(el >= mask);
            visSats = sats(idx);

            n = numel(idx);
            prnCol = zeros(n, 1);
            for k = 1:n
                prnCol(k) = visSats(k).Prn;
            end

            T = table( ...
                prnCol, ...
                rad2deg(az(idx)), ...
                rad2deg(el(idx)), ...
                dist(idx)/1000, ...
                'VariableNames', ...
                {'PRN','Azimuth_deg','Elevation_deg','Range_km'});

            [~, order] = sort(T.Elevation_deg, 'descend');
            T = T(order, :);
            visSats = visSats(order);
        end
    end
end