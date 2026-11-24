classdef GPSSatellite < Satellite
    properties (SetAccess = private)
        Prn (1,1) double {mustBeInteger, mustBeInRange(Prn,1,32)} = 1
    end
    properties (Access = private)
        Almanac (11,1) double = NaN(11,1)
        TParameters (:, :) double = []
    end
    properties (SetAccess = private)
        Health      (1,1) double = 0
        AlmanacWeek (1,1) double = NaN
    end
    methods
        function obj = GPSSatellite(prn, almColumn, tPar)
            obj@Satellite();
            if nargin >= 1 && ~isempty(prn),       obj.Prn = prn;              end
            if nargin >= 2 && ~isempty(almColumn), obj.Almanac = almColumn(:); end
            if nargin >= 3 && ~isempty(tPar)
                obj.TParameters = tPar;
                obj.AlmanacWeek = tPar(1);
            end
        end

        function update(obj, t)
            t = datetime(t, 'TimeZone', 'UTC');
            [w,   tow]   = UtcToGps(t);
            [wp,  towp]  = UtcToGps(t + seconds(1));
            [wm,  towm]  = UtcToGps(t - seconds(1));

            % satNo = 1, т.к. Almanac — 11×1
            r0 = calcSVCoord(obj.Almanac, [w;  tow],  1, obj.TParameters);
            rp = calcSVCoord(obj.Almanac, [wp; towp], 1, obj.TParameters);
            rm = calcSVCoord(obj.Almanac, [wm; towm], 1, obj.TParameters);

            obj.Position = r0(:);
            obj.Velocity = (rp(:) - rm(:)) / 2;
            obj.Time     = t;

            if obj.Health ~= 0
                warning('GPSSatellite:unhealthy', ...
                        'PRN %d неисправен (Health = %g).', obj.Prn, obj.Health);
            end
        end
    end
end