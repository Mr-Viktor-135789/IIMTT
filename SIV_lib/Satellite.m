classdef Satellite < handle
    properties
        Position (3,1) double {mustBeReal} = NaN(3,1)
        Velocity (3,1) double {mustBeReal} = NaN(3,1)
        Time     (1,1) datetime            = NaT
    end
    properties (Dependent)
        PositionNorm
        Speed
        Altitude
    end
    properties (Constant, Access = protected)
        EarthRadius (1,1) double {mustBePositive} = 6371000
    end
    methods
        function obj = Satellite(position, velocity, time)
            if nargin >= 1, obj.Position = position; end
            if nargin >= 2, obj.Velocity = velocity; end
            if nargin >= 3, obj.Time     = time;     end
        end

        function set.Position(obj, value)
            if all(isfinite(value)) && norm(value) < obj.EarthRadius
                error('Satellite:underground', ...
                      'Положение под поверхностью Земли: |r| < R.');
            end
            obj.Position = value;
        end

        function set.Time(obj, value)
            if ~isnat(value), value.TimeZone = 'UTC'; end
            obj.Time = value;
        end

        function value = get.PositionNorm(obj), value = norm(obj.Position); end
        function value = get.Speed(obj),        value = norm(obj.Velocity); end
        function value = get.Altitude(obj),     value = obj.PositionNorm - obj.EarthRadius; end

        function vInertial = inertialVelocity(obj)
            omega = 7.2921150e-5;
            vInertial = obj.Velocity + cross([0;0;omega], obj.Position);
        end

        function disp(obj)
            if ~isscalar(obj)
                fprintf('Satellite array: %d objects\n', numel(obj));
                return;
            end
            fprintf('Satellite: altitude = %.3f km, speed = %.3f km/s\n', ...
                    obj.Altitude/1000, obj.Speed/1000);
        end
    end
end