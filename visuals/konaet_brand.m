function brand = konaet_brand()
%KONAET_BRAND Carrega a marca original e confere sua procedencia.
folder = fullfile(fileparts(mfilename('fullpath')), 'brand');
brand = jsondecode(fileread(fullfile(folder, 'source.json')));
assert(strcmp(brand.name, 'KONAET'), 'Nome de marca inesperado.');
brand.file = fullfile(folder, brand.asset);
fid = fopen(brand.file, 'rb'); assert(fid >= 0, 'Logo original ausente.');
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
bytes = fread(fid, inf, '*uint8');
digest = java.security.MessageDigest.getInstance('SHA-256');
digest.update(bytes);
actual = lower(reshape(dec2hex(typecast(digest.digest(), 'uint8'), 2).', 1, []));
assert(strcmp(actual, brand.sha256), 'Logo diferente da origem registrada.');
brand.rgb = imread(brand.file);
assert(isequal(size(brand.rgb), [512 512 3]), 'Dimensoes da logo inesperadas.');
end
