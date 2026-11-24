function [pax, hSat, hText] = plotSky(pax, az, el, prn, mask)
%PLOTSKY Полярная диаграмма неба: только видимые спутники.

if isempty(pax) || ~isvalid(pax)
    pax = polaraxes;
end

az  = az(:); el = el(:); prn = prn(:);

hold(pax, 'on');

% --- настройка полярных осей ---
pax.ThetaZeroLocation = 'top';       
pax.ThetaDir          = 'clockwise'; 
pax.RDir              = 'normal';   % Центр = 90, край = 0
pax.RLim              = [0 90];
pax.ThetaTick         = 0:30:330;
pax.ThetaTickLabel    = {'С 0°','30°','60°','В 90°','120°','150°', ...
                         'Ю 180°','210°','240°','З 270°','300°','330°'};
pax.RTick             = [0 30 60 90];
pax.RTickLabel        = {'90°','60°','30°','0°'};   

% --- отбор видимых (внутри круга) ---
vis = el > deg2rad(mask);   
r   = 90 - rad2deg(el);     % Правильный пересчет радиуса для графика

% --- окружность маски (граница видимой зоны) ---
th = linspace(0, 2*pi, 361);
% ВАЖНО: рисуем на радиусе 90 - mask (для mask=10 это 80)
plot(pax, th, (90 - mask) * ones(size(th)), '--r', 'LineWidth', 1.5);

% --- scatter ТОЛЬКО для видимых ---
hSat = scatter(pax, az(vis), r(vis), 60, 'filled', ...
               'MarkerFaceColor', [0 0.45 0.74], ...
               'MarkerEdgeColor', 'k');

% --- подписи ТОЛЬКО для видимых ---
hText = gobjects(0);
idxVis = find(vis);
for k = 1:numel(idxVis)
    i = idxVis(k);
    hText(end+1) = text(pax, az(i), r(i), " " + string(prn(i)), ...
                        'HorizontalAlignment', 'left', ...
                        'VerticalAlignment',   'bottom', ...
                        'FontSize', 9);
end

% Принудительно фиксируем пределы осей (чтобы MATLAB не масштабировал их сам)
pax.RLim = [0 90]; 

title(pax, 'Диаграмма неба');
end