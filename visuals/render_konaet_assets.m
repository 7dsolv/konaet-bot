function manifest = render_konaet_assets(output_dir, report)
%RENDER_KONAET_ASSETS Vitrine MATLAB com a marca original KONAET.
%   Gera PNG, SVG e GIF. A animacao ilustra o protocolo, nao trafego ao vivo.
assert(report.failed == 0, 'A vitrine so pode usar um relatorio aprovado.');
if ~isfolder(output_dir), mkdir(output_dir); end
brand = konaet_brand();
C.brand = brand.rgb;
C.bg = [13 5 22]/255; C.panel = [0.066 0.040 0.105];
C.line = [0.19 0.21 0.30]; C.white = [0.94 0.93 0.88];
C.muted = [0.68 0.64 0.77]; C.violet = [0.76 0.27 1.0];
C.lime = [0.81 0.65 1.0]; C.copper = [0.98 0.65 0.92];

[f, ax] = canvas(1600, 800, C);
guard = onCleanup(@() close_figure(f));
for x = 70:100:1570
    line(ax, [x x], [80 730], Color=C.bg + 0.025, LineWidth=0.4);
end
label(ax, 80, 724, 'AUTOMAÇÃO / IDENTIDADE / REVISÃO', 17, C.muted, 'normal');
label(ax, 80, 550, 'KONAET', 88, C.white, 'bold');
label(ax, 84, 458, 'SUA IDENTIDADE. SEU FLUXO.', 21, C.lime, 'bold');
label(ax, 84, 365, 'Identidade verificável.', 26, C.white, 'bold');
label(ax, 84, 309, 'Mudanças revisáveis.', 26, C.white, 'bold');
label(ax, 84, 238, 'Do token limitado ao diff que o mantenedor pode revisar.', 18, C.muted, 'normal');
emblem(ax, 1170, 444, 285, C);
chips = {'ESCOPO DO REPOSITÓRIO', 'DIFF PERMITIDO', 'REVISÃO HUMANA'};
for i = 1:3
    x = 84 + (i-1)*500;
    line(ax, [x x+428], [125 125], Color=C.line, LineWidth=1.1);
    label(ax, x, 82, sprintf('0%d', i), 17, C.copper, 'bold');
    label(ax, x+42, 82, chips{i}, 19, C.white, 'bold');
end
exportgraphics(ax, fullfile(output_dir, 'konaet-cover.png'), Resolution=110, BackgroundColor=C.bg);
close(f); clear guard;

[f, ax] = canvas(1600, 860, C);
guard = onCleanup(@() close_figure(f));
label(ax, 70, 800, 'KONAET / Arquitetura de uma proposta', 38, C.white, 'bold');
emblem(ax, 1480, 784, 53, C);
label(ax, 70, 749, 'Identidade, dados e decisão humana atravessam fronteiras diferentes.', 20, C.muted, 'normal');
xs = [70 610 1150]; widths = [380 410 380];
headers = {'01 / GITHUB APP', '02 / RUNNER DO PROJETO', '03 / REPOSITÓRIO'};
for i = 1:3
    card(ax, xs(i), 177, widths(i), 520, C.panel, C.line);
    label(ax, xs(i)+22, 658, headers{i}, 18, C.muted, 'bold');
end
node(ax, 95, 516, 330, 80, 'CHAVE DA APP', 'Secret do mantenedor', C.violet, C);
node(ax, 95, 366, 330, 80, 'TOKEN TEMPORÁRIO', 'Token deste repositório', C.violet, C);
node(ax, 95, 220, 330, 80, 'IDENTIDADE CONFERIDA', 'Slug + ID + tipo Bot', C.violet, C);
connector(ax, [260 260], [516 446], C.violet);
connector(ax, [260 260], [366 300], C.violet);
node(ax, 638, 516, 354, 80, 'GERADOR DO PROJETO', 'Arquivos gerados pelo projeto', C.lime, C);
node(ax, 638, 366, 354, 80, 'DIFF PERMITIDO', 'Somente arquivos permitidos', C.lime, C);
node(ax, 638, 220, 354, 80, 'COMMIT + PUSH', 'Sem sobrescrever a branch', C.lime, C);
connector(ax, [815 815], [516 446], C.lime);
connector(ax, [815 815], [366 300], C.lime);
node(ax, 1175, 516, 330, 80, 'BRANCH DE PROPOSTA', 'Destino separado da base', C.copper, C);
node(ax, 1175, 366, 330, 80, 'PULL REQUEST', 'Criar, atualizar ou recuperar', C.copper, C);
node(ax, 1175, 220, 330, 80, 'MANTENEDOR', 'Revisa e decide o merge', C.copper, C);
connector(ax, [1340 1340], [516 446], C.copper);
connector(ax, [1340 1340], [366 300], C.copper);
connector(ax, [425 505 505 638], [406 406 260 260], C.violet);
label(ax, 463, 465, 'token', 17, C.violet, 'bold');
connector(ax, [992 1080 1080 1175], [260 260 556 556], C.lime);
label(ax, 1040, 609, 'diff', 17, C.lime, 'bold');
label(ax, 70, 112, sprintf('%d/%d cenários offline aprovados | Git local real | API gh substituída por fixture', report.passed, report.total), 17, C.white, 'bold');
label(ax, 70, 68, 'App real: NOT_RUN no relatório de teste. Instalação e autenticação são verificadas em workflow separado.', 14, C.muted, 'normal');
exportgraphics(ax, fullfile(output_dir, 'konaet-architecture.png'), Resolution=110, BackgroundColor=C.bg);
exportgraphics(ax, fullfile(output_dir, 'konaet-architecture.svg'), BackgroundColor=C.bg);
close(f); clear guard;

% O icone publicado conserva exatamente os bytes da marca original.
copyfile(brand.file, fullfile(output_dir, 'konaet-app-icon.png'));

gif_file = fullfile(output_dir, 'konaet-flow.gif');
frame_file = fullfile(output_dir, 'frame-preview.png');
frame_count = 48;
[palette, lookup] = palette_map();
[f, ax] = canvas(1160, 620, C);
guard = onCleanup(@() close_figure(f));
titles = {'APP', 'IDENTIDADE', 'DIFF', 'PUSH', 'REVISÃO'};
subtitles = {'Token limitado', 'Slug / ID / Bot', 'Somente paths', 'Sem force push', 'Criar ou atualizar PR'};
details = {'O segredo gera um token temporário para um repositório.', ...
    'A API precisa confirmar o login e o tipo de conta Bot.', ...
    'O diff completo da proposta precisa respeitar os caminhos permitidos.', ...
    'Uma branch que avançou não é substituída pela automação.', ...
    'Falha depois do push pode ser recuperada sem outro commit.'};
for frame = 1:frame_count
    cla(ax); hold(ax, 'on');
    background(ax, 1160, 620, C);
    progress = (frame-1)/frame_count;
    stage = min(5, floor(progress*5)+1);
    label(ax, 56, 558, 'KONAET / FLOW TRACE', 26, C.white, 'bold');
    label(ax, 56, 514, 'Demonstração do protocolo de proposta', 16, C.muted, 'normal');
    emblem(ax, 1050, 543, 56, C);
    centers = 142:218:1014;
    plot(ax, [centers(1) centers(end)], [360 360], Color=C.line, LineWidth=2);
    for i = 1:5
        active = i <= stage;
        edge = C.line; if active, edge = C.lime; end
        if i == stage, edge = C.copper; end
        card(ax, centers(i)-88, 304, 176, 112, C.panel, edge);
        label(ax, centers(i)-70, 384, sprintf('0%d', i), 12, edge, 'bold');
        label(ax, centers(i)-70, 351, titles{i}, 16, C.white, 'bold');
        label(ax, centers(i)-70, 326, subtitles{i}, 12, C.muted, 'normal');
        if i < stage, dot(ax, centers(i)+66, 387, 4, C.lime); end
    end
    local = mod(progress*5, 1);
    if stage < 5
        x = centers(stage) + local*(centers(stage+1)-centers(stage));
        y = 441 + 18*sin(local*pi);
        plot(ax, [centers(stage) centers(stage+1)], [441 441], Color=C.violet, LineWidth=1.2);
        dot(ax, x, y, 6, C.lime);
    end
    card(ax, 56, 69, 1048, 165, C.panel, C.line);
    label(ax, 80, 195, sprintf('ETAPA %02d / %s', stage, titles{stage}), 15, C.copper, 'bold');
    label(ax, 80, 155, details{stage}, 18, C.white, 'normal');
    label(ax, 80, 107, sprintf('%d/%d cenários offline aprovados  |  App real: NOT_RUN', report.passed, report.total), 14, C.muted, 'normal');
    label(ax, 56, 33, 'FLUXO ILUSTRADO / NÃO É TELEMETRIA AO VIVO / GERADO EM MATLAB', 11.5, C.muted, 'normal');
    drawnow;
    exportgraphics(ax, frame_file, Resolution=95, BackgroundColor=C.bg);
    rgb = imread(frame_file);
    r = lookup.red(double(rgb(:,:,1))+1);
    g = lookup.green(double(rgb(:,:,2))+1);
    b = lookup.blue(double(rgb(:,:,3))+1);
    indexed = uint8(r*32 + g*4 + b);
    if frame == 1
        imwrite(indexed, palette, gif_file, 'gif', LoopCount=inf, DelayTime=0.12);
    else
        imwrite(indexed, palette, gif_file, 'gif', WriteMode='append', DelayTime=0.12);
    end
end
close(f); clear guard;
copyfile(frame_file, fullfile(output_dir, 'konaet-flow-preview.png'));
delete(frame_file);
info = imfinfo(gif_file);
assert(numel(info) == frame_count && all([info.Width] == info(1).Width) && ...
    all([info.Height] == info(1).Height), 'Quadros do GIF inconsistentes.');
gif_info = dir(gif_file); assert(gif_info.bytes < 8*1024*1024, 'GIF excede o orcamento de 8 MiB.');
hero = imfinfo(fullfile(output_dir, 'konaet-cover.png'));
assert(hero.Width >= 1500, 'Capa abaixo da resolucao prevista.');
manifest.generator = 'visuals/render_konaet_assets.m';
manifest.revision = report.revision;
manifest.test_mode = report.mode;
manifest.test_passed = report.passed;
manifest.test_total = report.total;
manifest.animation.frames = frame_count;
manifest.animation.delay_seconds = 0.12;
manifest.animation.width = info(1).Width;
manifest.animation.height = info(1).Height;
manifest.animation.bytes = gif_info.bytes;
manifest.animation.live_telemetry = false;
manifest.real_app_status = report.live_app.status;
manifest.brand.name = brand.name;
manifest.brand.source_url = brand.source_url;
manifest.brand.source_revision = brand.source_revision;
manifest.brand.source_sha256 = brand.sha256;
manifest.brand.icon_preserves_source_bytes = true;
fid = fopen(fullfile(output_dir, 'showcase-manifest.json'), 'w', 'n', 'UTF-8');
assert(fid >= 0); cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', jsonencode(manifest, PrettyPrint=true));
fprintf('Vitrine: %d quadros, %.2f MiB; PNG e SVG gerados.\n', frame_count, gif_info.bytes/1024^2);
end

function [f, ax] = canvas(width, height, C)
f = figure(Visible='off', Color=C.bg, Units='pixels', ...
    Position=[40 40 width height], InvertHardcopy='off');
ax = axes(f, Position=[0 0 1 1], Color=C.bg, XLim=[0 width], ...
    YLim=[0 height], XTick=[], YTick=[], XColor=C.bg, YColor=C.bg);
axis(ax, 'manual'); axis(ax, 'off'); hold(ax, 'on');
background(ax, width, height, C);
end

function background(ax, width, height, C)
% Um objeto de fundo explicito preserva o canvas no recorte do exportgraphics.
rectangle(ax, Position=[1 1 width-2 height-2], FaceColor=C.bg, ...
    EdgeColor=C.line*0.55, LineWidth=0.6);
end

function label(ax, x, y, content, size, color, weight)
text(ax, x, y, content, FontName='DejaVu Sans', FontSize=size, ...
    Color=color, FontWeight=weight, Interpreter='none', VerticalAlignment='middle');
end

function card(ax, x, y, w, h, face, edge)
rectangle(ax, Position=[x y w h], Curvature=0.08, ...
    FaceColor=face, EdgeColor=edge, LineWidth=1.1);
end

function node(ax, x, y, w, h, title, detail, accent, C)
card(ax, x, y, w, h, C.bg, accent);
label(ax, x+16, y+h-25, title, 22, C.white, 'bold');
label(ax, x+16, y+24, detail, 18, C.muted, 'normal');
end

function connector(ax, xs, ys, color)
plot(ax, xs, ys, Color=color, LineWidth=1.6);
dot(ax, xs(end), ys(end), 3.4, color);
end

function dot(ax, x, y, radius, color)
rectangle(ax, Position=[x-radius y-radius radius*2 radius*2], ...
    Curvature=[1 1], FaceColor=color, EdgeColor='none');
end

function emblem(ax, cx, cy, scale, C)
% Eixo Y crescente para cima: a primeira linha da imagem fica no topo.
image(ax, XData=[cx-scale cx+scale], YData=[cy+scale cy-scale], CData=C.brand);
end

function [map, lookup] = palette_map()
levels = [0 .045 .08 .14 .24 .40 .65 1];
blue = [.055 .14 .40 1];
index = (0:255).';
map = [reshape(levels(floor(index/32)+1), [], 1), ...
    reshape(levels(mod(floor(index/4),8)+1), [], 1), ...
    reshape(blue(mod(index,4)+1), [], 1)];
values = (0:255)'/255;
[~, r] = min(abs(values-levels), [], 2);
[~, b] = min(abs(values-blue), [], 2);
lookup.red = reshape(r-1, 256, 1);
lookup.green = lookup.red;
lookup.blue = reshape(b-1, 256, 1);
end

function close_figure(f)
if isgraphics(f), close(f); end
end
