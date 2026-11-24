clc; clear; close all;
addpath(fullfile(pwd, 'SiV_lib'));

%% 1) Загрузка эталона (ЛР3)
S = load('sky24h.mat');
fprintf('sky24h: tUtc(1) = %s\n', string(S.tUtc(1)));
fprintf('sky24h: lat = %.6f, lon = %.6f, h = %.1f\n', S.lat, S.lon, S.h);

t = S.tUtc(1); t.TimeZone = 'UTC';

%% 2) Группировка и обновление
c = Constellation();
c.update(t);
disp(c.Satellites(15));

%% 3) Наблюдатель
obs = Observer(S.lat, S.lon, S.h);

%% 4) Видимые спутники
[visSats, T] = obs.visible(c.Satellites, deg2rad(10));
disp(T);

%% 5) Сверка углов с sky24h.mat
[az, el, dist] = obs.look(c.Satellites);

if max(abs(S.el3(:))) > 2
    elRef = deg2rad(S.el3(:,1));
    azRef = deg2rad(S.az3(:,1));
    fprintf('S.el3/S.az3 — в ГРАДУСАХ, переводим в радианы\n');
else
    elRef = S.el3(:,1);
    azRef = S.az3(:,1);
    fprintf('S.el3/S.az3 — в РАДИАНАХ\n');
end

dEl = el(:) - elRef;
dAz = mod(az(:) - azRef + pi, 2*pi) - pi;
fprintf('max |dEl| = %.3e рад, max |dAz| = %.3e рад\n', ...
        max(abs(dEl)), max(abs(dAz)));
assert(max(abs(dEl)) <= 1e-6 && max(abs(dAz)) <= 1e-6, ...
       'Сверка с sky24h.mat не пройдена');

%% 6) Диагностика
fprintf('\n--- ДИАГНОСТИКА ---\n');
r_ours = c.Satellites(15).Position;
r_ref  = S.svAll(:,15,1);
fprintf('||r_ours - r_ref|| = %.6e м\n', norm(r_ours - r_ref));
fprintf('|r_ours| = %.3f км, |r_ref| = %.3f км\n', ...
        norm(r_ours)/1000, norm(r_ref)/1000);
fprintf('Velocity PRN 15 = %.3f м/с (ожидается ~3874)\n', ...
        norm(c.Satellites(15).Velocity));

[w, tow]   = UtcToGps(t);
[w1, tow1] = UtcToGps(t + seconds(1));
fprintf('dw = %d, dtow = %.6f (ожидается 0 и 1)\n', ...
        w1 - w, tow1 - tow);

%% 7) Число видимых
fprintf('\nВидимых спутников (маска 10°): %d\n', height(T));
assert(height(T) >= 4, 'Меньше 4 видимых — проверьте альманах/время');

%% 8) Запуск тестов 
 results = runtests('TestSiV');
 disp(table(results));