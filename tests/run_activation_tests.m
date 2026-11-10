function report = run_activation_tests(root, output_dir)
%RUN_ACTIVATION_TESTS Chaves sinteticas locais; nunca autentica App real.
if nargin < 1, root = fileparts(fileparts(mfilename('fullpath'))); end
if nargin < 2, output_dir = fullfile(root,'artifacts'); end
addpath(root,fullfile(root,'activation'));
folder = tempname; mkdir(folder); guard = onCleanup(@() cleanup(folder)); %#ok<NASGU>
generator = java.security.KeyPairGenerator.getInstance('RSA');
generator.initialize(2048); pair = generator.generateKeyPair();
encoder = java.util.Base64.getEncoder();
pem = sprintf('-----BEGIN PRIVATE KEY-----\n%s\n-----END PRIVATE KEY-----\n', ...
    char(encoder.encodeToString(pair.getPrivate().getEncoded())));
app = struct('slug','konaet','id',5602778,'client_id','IvTestClient', ...
    'owner',struct('login','7dsolv'));
installation = struct('id',42,'app_id',5602778,'account',struct('login','7dsolv'), ...
    'permissions',struct('contents','write','pull_requests','write'),'suspended_at',[]);
items = {
    'rsa-pkcs8-signature-and-claims', @() signature_case(pem,pair);
    'rsa-pkcs1-signature', @() signature_case(pkcs1_pem(pair),pair);
    'invalid-pem', @() must_error(@() konaet_app_jwt('not a key','5602778'),'Konaet:InvalidPrivateKey');
    'encrypted-key-rejected', @() must_error(@() konaet_app_jwt('-----BEGIN ENCRYPTED PRIVATE KEY-----','5602778'),'Konaet:InvalidPrivateKey');
    'weak-rsa-rejected', @() weak_case();
    'issuer-injection-rejected', @() must_error(@() konaet_app_jwt(pem,'bad"issuer'),'Konaet:InvalidIssuer');
    'valid-activation-policy', @() valid_policy(app,installation);
    'wrong-app-rejected', @() changed_policy(app,installation,'app');
    'wrong-owner-rejected', @() changed_policy(app,installation,'owner');
    'insufficient-permissions-rejected', @() changed_policy(app,installation,'permissions');
    'foreign-installation-rejected', @() changed_policy(app,installation,'installation');
    'suspended-installation-rejected', @() changed_policy(app,installation,'suspended');
    'check-only-does-not-read-key-or-execute', @() discovery_case(folder);
    'missing-key-has-no-verified-status', @() missing_case(folder);
    'process-stdin-and-literal-path', @() process_case(folder);
    'process-environment-is-child-only', @() environment_case()
};
cases = struct('name',{},'passed',{},'error_id',{});
for k = 1:size(items,1)
    item = struct('name',items{k,1},'passed',false,'error_id','');
    try
        items{k,2}(); item.passed = true; fprintf('[PASS] activation / %s\n',item.name);
    catch problem
        item.error_id = problem.identifier;
        fprintf('[FAIL] activation / %s: %s\n',item.name,problem.message);
    end
    cases(end+1) = item; %#ok<AGROW>
end
report = struct('schema_version',1,'mode','offline-synthetic-keys-no-live-app', ...
    'source_revision',getenv('GITHUB_SHA'),'total',numel(cases), ...
    'passed',sum([cases.passed]),'cases',cases,'live_app','NOT_RUN');
if ~isfolder(output_dir), mkdir(output_dir); end
fid = fopen(fullfile(output_dir,'activation-test-report.json'),'w','n','UTF-8');
assert(fid >= 0); close_guard = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',jsonencode(report,PrettyPrint=true));
assert(report.passed == report.total,'Konaet:ActivationTestFailure','Ativacao: %d/%d passaram.',report.passed,report.total);
end

function signature_case(pem,pair)
epoch = 1794330000;
jwt = konaet_app_jwt(pem,'5602778',epoch);
parts = strsplit(jwt,'.'); assert(numel(parts) == 3 && ~contains(jwt,'='));
decoder = java.util.Base64.getUrlDecoder();
header_bytes = reshape(typecast(int8(decoder.decode(parts{1})),'uint8'),1,[]);
claims_bytes = reshape(typecast(int8(decoder.decode(parts{2})),'uint8'),1,[]);
header = jsondecode(native2unicode(header_bytes,'UTF-8'));
claims = jsondecode(native2unicode(claims_bytes,'UTF-8'));
assert(strcmp(header.alg,'RS256') && strcmp(claims.iss,'5602778'));
assert(claims.iat == epoch-60 && claims.exp == epoch+540);
verifier = java.security.Signature.getInstance('SHA256withRSA');
verifier.initVerify(pair.getPublic());
message = [parts{1} '.' parts{2}];
verifier.update(typecast(unicode2native(message,'UTF-8'),'int8'));
assert(verifier.verify(decoder.decode(parts{3})),'Assinatura RSA invalida.');
verifier.initVerify(pair.getPublic());
verifier.update(typecast(unicode2native([message 'x'],'UTF-8'),'int8'));
assert(~verifier.verify(decoder.decode(parts{3})),'Payload alterado foi aceito.');
end

function pem = pkcs1_pem(pair)
key = pair.getPrivate();
values = {java.math.BigInteger.ZERO,key.getModulus(),key.getPublicExponent(), ...
    key.getPrivateExponent(),key.getPrimeP(),key.getPrimeQ(), ...
    key.getPrimeExponentP(),key.getPrimeExponentQ(),key.getCrtCoefficient()};
body = uint8([]);
for k = 1:numel(values)
    bytes = reshape(typecast(int8(values{k}.toByteArray()),'uint8'),1,[]);
    body = [body uint8(2) length_bytes(numel(bytes)) bytes]; %#ok<AGROW>
end
der = [uint8(48) length_bytes(numel(body)) body];
encoder = java.util.Base64.getEncoder();
pem = sprintf('-----BEGIN RSA PRIVATE KEY-----\n%s\n-----END RSA PRIVATE KEY-----\n', ...
    char(encoder.encodeToString(typecast(der,'int8'))));
end

function bytes = length_bytes(n)
if n < 128, bytes = uint8(n); return; end
raw = uint8([]);
while n > 0, raw = [uint8(mod(n,256)) raw]; n = floor(n/256); end %#ok<AGROW>
bytes = [uint8(128+numel(raw)) raw];
end

function weak_case()
generator = java.security.KeyPairGenerator.getInstance('RSA'); generator.initialize(1024);
pair = generator.generateKeyPair(); encoder = java.util.Base64.getEncoder();
pem = sprintf('-----BEGIN PRIVATE KEY-----\n%s\n-----END PRIVATE KEY-----\n', ...
    char(encoder.encodeToString(pair.getPrivate().getEncoded())));
must_error(@() konaet_app_jwt(pem,'5602778'),'Konaet:WeakPrivateKey');
end

function valid_policy(app,installation)
plan = konaet_activation_policy(app,{installation,installation});
assert(strcmp(plan.owner,'7dsolv') && plan.installation_id == 42);
assert(isequal(plan.repositories,{'7dsolv/konaet-bot','7dsolv/RealidadeQuantica'}));
end

function changed_policy(app,installation,field)
other = installation;
switch field
    case 'app', app.slug = 'other'; expected = 'Konaet:WrongApp';
    case 'owner', app.owner.login = 'other'; expected = 'Konaet:WrongOwner';
    case 'permissions', other.permissions.contents = 'read'; expected = 'Konaet:MissingPermission';
    case 'installation', other.account.login = 'other'; expected = 'Konaet:WrongInstallation';
    case 'suspended', other.suspended_at = '2026-01-01'; expected = 'Konaet:SuspendedInstallation';
end
must_error(@() konaet_activation_policy(app,{installation,other}),expected);
end

function discovery_case(folder)
search = fullfile(folder,'downloads'); mkdir(search);
write(fullfile(search,'konaet.2026.private-key.pem'),'SENTINEL: check-only must not parse this');
fake = fullfile(folder,'gh-not-executable'); write(fake,'SENTINEL: do not execute');
r = ativar_konaet(CheckOnly=true,SearchDirectories={search},GhExecutable=fake);
assert(strcmp(r.status,'READY_TO_VALIDATE') && r.private_key_candidates == 1);
assert(~r.app_authenticated && ~r.credentials_configured && ~isfield(r,'jwt'));
end

function missing_case(folder)
search = fullfile(folder,'empty-downloads'); mkdir(search);
r = ativar_konaet(CheckOnly=true,SearchDirectories={search});
assert(strcmp(r.status,'MISSING_PRIVATE_KEY') && ~r.app_authenticated && ~r.credentials_configured);
end

function process_case(folder)
payload = sprintf('KONAET process fixture\n');
[status,a] = konaet_process({'git','hash-object','--stdin'},payload);
assert(status == 0);
path = fullfile(folder,'literal space; $() file.txt'); write(path,payload);
[status,b] = konaet_process({'git','hash-object','--',path});
assert(status == 0 && strcmp(strtrim(a),strtrim(b)));
end

function environment_case()
before = getenv('KONAET_ACTIVATION_FIXTURE');
[status,out] = konaet_process({'printenv','KONAET_ACTIVATION_FIXTURE'},'', ...
    struct('KONAET_ACTIVATION_FIXTURE','child-only'));
assert(status == 0 && strcmp(strtrim(out),'child-only'));
assert(strcmp(getenv('KONAET_ACTIVATION_FIXTURE'),before));
end

function must_error(callback,identifier)
caught = false;
try, callback(); catch problem, caught = strcmp(problem.identifier,identifier); end
assert(caught,'Konaet:ExpectedRejection','Esperava a rejeicao %s.',identifier);
end

function write(path,content)
fid = fopen(path,'w','n','UTF-8'); assert(fid >= 0);
guard = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s',content);
end

function cleanup(folder)
parent = char(java.io.File(tempdir).getCanonicalPath());
target = char(java.io.File(folder).getCanonicalPath());
assert(startsWith(target,[parent filesep]) && numel(target) > numel(parent)+1);
if isfolder(target), rmdir(target,'s'); end
end
