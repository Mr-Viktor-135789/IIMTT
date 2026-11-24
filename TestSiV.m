classdef TestSiV < matlab.unittest.TestCase
    %TESTISV Модульные тесты ЛР6: calcSVCoord, Satellite, Observer.

    methods (Test)

        function testCalcSVCoord_PR01(tc)
            % Контрольный пример из ЛР3, шаг 9: PRN-01, week 74, tow 300000
            almTest = zeros(11,1);
            almTest(1:8) = [ 0.01008796692; ...
                             233472; ...
                             0.9811808504; ...
                            -0.7668890869e-8; ...
                             5153.658203; ...
                             1.195812551; ...
                             0.826152767; ...
                            -2.549961805 ];

            [xyz, info] = calcSVCoord(almTest, [74; 300000], 1, 74);

            expected = [14993845.115; -155639.007; 21715060.125];
            tc.verifyEqual(xyz(:), expected, 'AbsTol', 1e-3, ...
                'calcSVCoord должен совпасть с эталоном ЛР3 с точностью 1 мм');
            tc.verifyEqual(norm(xyz(:)), info.rk, 'AbsTol', 1e-6, ...
                '|r| должен совпасть с info.rk');
        end

        function testSatelliteUnderground(tc)
            % set.Position должен выбросить Satellite:underground при |r| < R
            s = Satellite();
            R = 6371000;
            pBad = [R - 1; 0; 0];
            tc.verifyError(@() assignPosition(s, pBad), ...
                'Satellite:underground');
        end

        function testSatelliteAltitude(tc)
            % Altitude для r = (R + 1000, 0, 0) должна быть 1000 м
            R = 6371000;
            s = Satellite([R + 1000; 0; 0]);
            tc.verifyEqual(s.Altitude, 1000, 'AbsTol', 1e-6);
        end

        function testObserverValueSemantics(tc)
            % Копирование value-объекта не меняет оригинал
            o1 = Observer(10, 20, 0);
            o2 = o1;
            o2.Lat = 0;

            tc.verifyEqual(o1.Lat, 10, 'Оригинал не должен меняться');
            tc.verifyEqual(o2.Lat, 0,  'Копия должна измениться');
            tc.verifyEqual(o1.Lon, 20);
            tc.verifyEqual(o2.Lon, 20);
        end
    end
end

function assignPosition(s, p)
    % Вспомогательная функция: присваивание Position (чтобы поймать error)
    s.Position = p;
end