function summary = verify_konaet_assets(folder)
%VERIFY_KONAET_ASSETS Confere as midias versionadas e a evidencia que exibem.
required = {'konaet-cover.png', 'konaet-app-icon.png', ...
    'konaet-architecture.svg', 'konaet-architecture.png', ...
    'konaet-flow.gif', 'konaet-flow-preview.png', ...
    'showcase-manifest.json', 'test-report.json'};
for i = 1:numel(required)
    assert(isfile(fullfile(folder, required{i})), 'Midia ausente: %s', required{i});
end
r = jsondecode(fileread(fullfile(folder, 'test-report.json')));
m = jsondecode(fileread(fullfile(folder, 'showcase-manifest.json')));
brand = konaet_brand();
assert(strcmp(m.brand.name, brand.name) && m.brand.icon_preserves_source_bytes);
assert(strcmp(m.brand.source_url, brand.source_url));
assert(strcmp(m.brand.source_revision, brand.source_revision));
assert(strcmp(m.brand.source_sha256, brand.sha256));
source_id = fopen(brand.file, 'rb'); assert(source_id >= 0);
source_guard = onCleanup(@() fclose(source_id));
icon_id = fopen(fullfile(folder, 'konaet-app-icon.png'), 'rb'); assert(icon_id >= 0);
icon_guard = onCleanup(@() fclose(icon_id));
assert(isequal(fread(source_id, inf, '*uint8'), fread(icon_id, inf, '*uint8')), ...
    'O icone publicado precisa conservar a marca original.');
clear source_guard icon_guard;
assert(r.complete && r.failed == 0 && r.passed == r.total && r.total == r.planned);
assert(m.test_passed == r.passed && m.test_total == r.total);
assert(strcmp(m.revision, r.revision) && strcmp(m.test_mode, r.mode));
assert(~m.animation.live_telemetry && strcmp(m.real_app_status, r.live_app.status));
frames = imfinfo(fullfile(folder, 'konaet-flow.gif'));
assert(numel(frames) == m.animation.frames && numel(frames) >= 24);
assert(all([frames.Width] == m.animation.width) && all([frames.Height] == m.animation.height));
gif = dir(fullfile(folder, 'konaet-flow.gif'));
assert(gif.bytes == m.animation.bytes && gif.bytes < 8*1024*1024);
cover = imfinfo(fullfile(folder, 'konaet-cover.png'));
icon = imfinfo(fullfile(folder, 'konaet-app-icon.png'));
assert(cover.Width >= 1500 && icon.Width >= 400 && icon.Height >= 400);
svg = lower(fileread(fullfile(folder, 'konaet-architecture.svg')));
assert(contains(svg, '<svg') && ~contains(svg, '<script') && ~contains(svg, '<foreignobject'));
summary.tested_revision = r.revision;
summary.offline_cases = r.total;
summary.frames = numel(frames);
summary.gif_bytes = gif.bytes;
summary.brand = brand.name;
summary.brand_sha256 = brand.sha256;
fprintf('Midias verificadas: %d cenarios de origem, %d quadros, %.2f MiB.\n', ...
    r.total, numel(frames), gif.bytes/1024^2);
end
