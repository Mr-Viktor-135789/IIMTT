clc; clear; close all;
addpath(fullfile(pwd, 'SiV_lib'));
%% Initial data
S = load('sky24h.mat');
if isequal(size(S.el3),[32 1440]) && isequal(size(S.az3),[32 1440])
       fprintf('Размеры 32 на 1440\n')
end

mask = 10;
prn = (1:32).';

[lat, lon, h] = deal(S.lat, S.lon, S.h);

% --- наблюдатель на карте ---
figure('Name','geoscatter');
geoscatter(lat, lon, 80, 'r', 'filled');
geobasemap('streets'); title('Наблюдатель (geoscatter)');

figure('Name','geobubble');
geobubble(lat, lon, 80,  categorical("Наблюдатель"));
geobasemap('streets'); title('Наблюдатель (geobubble)');

%% Ground tracks
el0 = S.el3(:,1);  
prnTrack = find(el0> deg2rad(mask)).';
assert(numel(prnTrack)>= 3, 'Мало видимых спутников');

figure('Name','Ground tracks');
gx = geoaxes; 
hold(gx,'on');
C = lines(numel(prnTrack));
for k = 1:numel(prnTrack)
    prn = prnTrack(k);

    % --- Извлечение ECEF-координат ---
    ecef = reshape(S.svAll(:,prn,:), 3, []).';
    lla  = ecef2lla(ecef);

    latTr = lla(:,1).';   
    lonTr = lla(:,2).';   

    % --- Вставка NaN при скачке долготы (переход через ±180°) ---
    dLon = abs(diff(lonTr));
    jumpIdx = find(dLon > 180);                    
    for j = fliplr(jumpIdx)
        latTr = [latTr(1:j), NaN, latTr(j+1:end)];
        lonTr = [lonTr(1:j), NaN, lonTr(j+1:end)];
    end

    geoplot(gx, latTr, lonTr, 'Color', C(k,:), 'LineWidth',1.5, 'DisplayName', sprintf('PRN %d', prn));
    fprintf('PRN %2d: max lat =%.2f°, i=%.2f°\n', prn, max(abs(latTr)), rad2deg(S.almanac(3,prn)));
end
geoscatter(gx, lat, lon, 60, 'k', 'filled', 'DisplayName','Observer');
geobasemap(gx,'streets'); legend(gx,'Location','southoutside');
title(gx,'Трассы за сутки');


%% Sky plot
az1 = S.az3(:,1);
el1 = S.el3(:,1);
prn = (1:32).';
mask = 10; 

t = S.tUtc;   
figure('Name','Sky plot');
[pax, hSat, hText] = plotSky([], az1, el1, prn, mask);
title(pax, sprintf('%s, видимых: %d', string(t(1),'HH:mm'), sum(el1 > deg2rad(mask))));

%% Sky plot (bubble)
el_deg = rad2deg(S.el3(:,1));
az_deg = rad2deg(S.az3(:,1));

vis = el_deg > mask;
Re  = 6371;  Rorb = 26560;

% Дистанция до спутников (для размера пузырьков)
d   = sqrt(Rorb^2 - Re^2*cos(S.el3(vis,1)).^2) - Re*sin(S.el3(vis,1));
sz  = 50 + 350*(max(d) - d)/(max(d) - min(d));

figure('Name','Sky plot (bubble)');
pax = polaraxes;

% Радиус = 90 - элевация: зенит в центре, горизонт на краю
r_plot = 90 - el_deg(vis);
polarbubblechart(pax, az_deg(vis), r_plot, sz, [0 0.447 0.741]);

pax.ThetaZeroLocation = 'top';
pax.ThetaDir          = 'clockwise';
pax.RDir              = 'normal';      % 0 (зенит) в центре, 90 (горизонт) на краю
pax.RLim              = [0 90];
pax.RTick             = [0 30 60 90];
pax.RTickLabel        = {'90°','60°','30°','0°'}; % подписи элевации

hold(pax,'on');

polarplot(pax, linspace(0,2*pi,200), (90-mask)*ones(1,200), 'r--', 'LineWidth', 1.2);

idx = find(vis);

for k = 1:numel(idx)
    az = az_deg(idx(k));
    r_val    = (90 - el_deg(idx(k)));
    
    text(pax, deg2rad(az), r_val, num2str(prn(idx(k))), ...
        'HorizontalAlignment','left', ...
        'VerticalAlignment','middle', ...
        'FontSize', 8, ...
        'FontWeight','bold', ...
        'Color', 'k');
end

title(pax, sprintf('%s, видимых: %d', string(t(1),'HH:mm'), sum(vis)));

%% Graph with standard functions
sv = find(S.el3(:,1)>deg2rad(mask)).'; sv = sv(1:3);
tG = S.tUtc;
e1=rad2deg(S.el3(sv(1),:)); e2=rad2deg(S.el3(sv(2),:)); e3=rad2deg(S.el3(sv(3),:));
figure('Name','Elevation — standard');
plot(tG,e1,'k-','LineWidth',2); hold on;
plot(tG(1:10:end),e2(1:10:end),'r:*','LineWidth',2);
plot(tG(1:50:end),e3(1:50:end),'g-.s','LineWidth',2);
grid on;
xlabel('время, UTC','FontSize',18); ylabel('угол места, град','FontSize',18);
title(sprintf('SV numbers: %d, %d, %d',sv),'FontSize',18);
xlim([tG(1) tG(end)]); xticks(tG(1):hours(2):tG(end));
xticklabels(compose('%d ч',0:2:24)); ylim([0 90]);
legend(arrayfun(@(n)sprintf('PRN %d',n),sv,'UniformOutput',false),'Location','best');
fprintf('Объектов: %d\n', numel(findall(gcf)));

%% Graph with object properties 
figO = figure('Name','Elevation  objects','Position',[50 50 900 500]);
axO = axes(figO); hold(axO,'on');
h1=plot(axO,tG,e1,'k-'); h2=plot(axO,tG(1:10:end),e2(1:10:end),'r:*');
h3=plot(axO,tG(1:50:end),e3(1:50:end),'g-.s');
set([h1 h2 h3],'LineWidth',2);
axO.XLabel.String='время, UTC'; axO.XLabel.FontSize=18;
axO.YLabel.String='угол места, град'; axO.YLabel.FontSize=18;
axO.Title.String=sprintf('SV numbers: %d, %d, %d',sv); axO.Title.FontSize=18;
axO.XLim=[tG(1) tG(end)]; axO.XTick=tG(1):hours(2):tG(end);
axO.XTickLabel=compose('%d ч',0:2:24); axO.YLim=[0 90];
axO.XGrid='on'; axO.YGrid='on';
legend(axO,[h1 h2 h3],arrayfun(@(n)sprintf('PRN %d',n),sv,'UniformOutput',false));
set(findobj(axO,'Type','line'),'LineWidth',1);   % одной командой
delete(h2);                                       % легенда обновится
%%
figRef = figure;
plot(tG, e1, 'k-', 'LineWidth',2); hold on;
plot(tG(1:10:end), e2(1:10:end), 'r:*', 'LineWidth',2);
plot(tG(1:50:end), e3(1:50:end), 'g-.s','LineWidth',2);
grid on;
xlabel('время, UTC','FontSize',18);
ylabel('угол места, град','FontSize',18);
title(sprintf('SV numbers: %d, %d, %d',sv),'FontSize',18);
xlim([tG(1) tG(end)]);
xticks(tG(1):hours(2):tG(end));
xticklabels(compose('%d ч',0:2:24));
ylim([0 90]);
legend(arrayfun(@(n)sprintf('PRN %d',n),sv,'UniformOutput',false));

%% Dashboard
n5=sum(S.el3>deg2rad(5),1); n10=sum(S.el3>deg2rad(10),1); n15=sum(S.el3>deg2rad(15),1);
fprintf('nVis: mean=%.1f min=%d max=%d <4:%d\n',mean(n10),min(n10),max(n10),sum(n10<4));

figure('Name','Sky dashboard','Position',[100 100 1100 800]);
tl=tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
title(tl,'Небо над наблюдателем за сутки','FontSize',18);

nexttile; [~,iMin]=min(n10); polarplot(NaN,NaN); paxD=gca;
plotSky(paxD,S.az3(:,iMin),S.el3(:,iMin),prn,mask);
title(paxD,sprintf('Минимум видимых: %d',n10(iMin)));

nexttile; hold on;
stairs(tG,n5,'LineWidth',1.5); stairs(tG,n10,'LineWidth',1.5); stairs(tG,n15,'LineWidth',1.5);
yline(4,'k--'); grid on; legend({'5°','10°','15°'},'Location','best');
xlim([tG(1) tG(end)]); xticks(tG(1):hours(2):tG(end)); xticklabels(0:2:24);
xlabel('часы'); ylabel('спутников');

nexttile; histogram(n10,'BinMethod','integers'); xlabel('видимых (10°)'); grid on;

nexttile; elD=rad2deg(S.el3); elD(elD<0)=NaN;
imagesc(hours(tG-tG(1)),1:32,elD); set(gca,'YDir','normal','Color',[.85 .85 .85]);
colormap(parula); clim([0 90]); cb=colorbar; cb.Label.String='угол места, град';
xlabel('часы'); ylabel('номер спутника');

exportgraphics(gcf,'sky_dashboard.png','Resolution',200);




%% Animation — both modes in one loop
nFrames = size(S.az3,2);
maskRad = deg2rad(mask);

% Подготовка двух фигур
figS = figure('Name','Animation slow'); paxS = polaraxes;
figF = figure('Name','Animation fast'); paxF = polaraxes;
[~,hSat,hTxt] = plotSky(paxF, S.az3(:,1), S.el3(:,1), prn, mask);
hTitle = title(paxF,'');

tSlow = 0; tFast = 0;

for mode = 1:2
    tic;
    for k = 1:nFrames
        if mode == 1
            % --- SLOW ---
            cla(paxS);
            plotSky(paxS, S.az3(:,k), S.el3(:,k), prn, mask);
            title(paxS, string(tG(k),'HH:mm'));
            drawnow;
        else
            % --- FAST ---
            el = S.el3(:,k); az = S.az3(:,k); v = el > maskRad;
            th = nan(size(az)); rr = nan(size(el));
            th(v) = az(v); rr(v) = 90 - rad2deg(el(v));
            set(hSat,'ThetaData',th,'RData',rr);
            for j = 1:numel(hTxt)
                if v(j)
                    set(hTxt(j),'Position',[az(j)+deg2rad(6),(90-rad2deg(el(j)))+3,0],'Visible','on');
                else
                    set(hTxt(j),'Visible','off');
                end
            end
            set(hTitle,'String',string(tG(k),'HH:mm'));
            drawnow;
        end
    end
    if mode == 1, tSlow = toc; else, tFast = toc; end
end

fprintf('Slow: %.1f s, %.1f fps\n', tSlow, nFrames/tSlow);
fprintf('Fast: %.1f s, %.1f fps, ускорение %.1f×\n', tFast, nFrames/tFast, tSlow/max(tFast,eps));