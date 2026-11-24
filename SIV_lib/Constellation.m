classdef Constellation < handle
    properties (SetAccess = private)
        Satellites (1,:) GPSSatellite
    end
    properties
        Week (1,1) double = NaN
    end
    methods
        function obj = Constellation()
            [alm, tPar] = ReadGPSAlmanac();           % alm: 11×32, tPar: 2×32
            obj.Satellites = GPSSatellite.empty(1,0);
            for k = 1:32
                obj.Satellites(k) = GPSSatellite(k, alm(:,k), tPar);   % столбец + весь tPar
            end
            if ~isempty(tPar), obj.Week = tPar(1); end
        end
        function update(obj, t)
            for k = 1:numel(obj.Satellites)
                obj.Satellites(k).update(t);
            end
        end
        function sats = healthy(obj)
            sats = obj.Satellites([obj.Satellites.Health] == 0);
        end
    end
end