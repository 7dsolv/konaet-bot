function report = ativar_konaet(options)
%ATIVAR_KONAET Valida a App, configura Secrets e dispara verificacoes reais.
%   ativar_konaet procura a chave KONAET em Downloads. Nenhuma chave e criada,
%   publicada ou retornada. CheckOnly=true nao le a chave nem usa a rede.
arguments
    options.CheckOnly (1,1) logical = false
    options.PrivateKeyPath (1,:) char = ''
    options.GhExecutable (1,:) char = ''
    options.SearchDirectories cell = {}
end
root = fileparts(mfilename('fullpath')); addpath(fullfile(root,'activation'));
folders = options.SearchDirectories;
if isempty(folders)
    folders = {fullfile(getenv('USERPROFILE'),'Downloads'), ...
        fullfile(getenv('HOME'),'Downloads')};
end
candidates = struct('path',{},'date',{});
if ~isempty(options.PrivateKeyPath)
    assert(isfile(options.PrivateKeyPath),'Konaet:MissingPrivateKey','Arquivo de chave nao encontrado.');
    item = dir(options.PrivateKeyPath);
    candidates = struct('path',options.PrivateKeyPath,'date',item.datenum);
else
    for i = 1:numel(folders)
        if ~isfolder(folders{i}), continue; end
        files = dir(fullfile(folders{i},'*.pem'));
        for k = 1:numel(files)
            if ~files(k).isdir && ~isempty(regexpi(files(k).name,'^konaet(?:[._-]|$)','once'))
                path = fullfile(files(k).folder,files(k).name);
                if ~any(strcmp({candidates.path},path))
                    candidates(end+1) = struct('path',path,'date',files(k).datenum); %#ok<AGROW>
                end
            end
        end
    end
end
gh = resolve_gh(options.GhExecutable);
report = struct('status','NOT_VERIFIED','check_only',options.CheckOnly, ...
    'private_key_candidates',numel(candidates),'github_cli_available',~isempty(gh), ...
    'credentials_configured',false,'app_authenticated',false, ...
    'owner','7dsolv','repositories',{{'7dsolv/konaet-bot','7dsolv/RealidadeQuantica'}});
if isempty(candidates)
    report.status = 'MISSING_PRIVATE_KEY';
    fprintf('Chave KONAET ausente. Gere a chave em https://github.com/settings/apps/konaet e execute ativar_konaet novamente.\n');
    return
end
if isempty(gh), report.status = 'GITHUB_CLI_UNAVAILABLE'; return; end
if options.CheckOnly, report.status = 'READY_TO_VALIDATE'; return; end
[~,order] = sort([candidates.date],'descend');
authenticated = false;
for index = order(1:min(5,numel(order)))
    item = dir(candidates(index).path);
    if item.bytes > 65536, continue; end
    pem = fileread(candidates(index).path);
    try
        jwt = konaet_app_jwt(pem,'5602778');
        app = github_get('/app',jwt);
        installations = cell(1,2);
        for k = 1:2, installations{k} = github_get(['/repos/' report.repositories{k} '/installation'],jwt); end
        plan = konaet_activation_policy(app,installations);
        authenticated = true; break
    catch
        % Erros de rede e credenciais nao sao registrados com headers/JWT.
        clear pem jwt
    end
end
assert(authenticated,'Konaet:AppAuthentication', ...
    'Nenhuma chave validou a App KONAET e sua instalacao nos dois repositorios. Nenhum Secret alterado.');
report.app_authenticated = true;
token = getenv('GH_TOKEN');
if isempty(token)
    query = sprintf('protocol=https\nhost=github.com\nusername=7dsolv\n\n');
    env = struct('GIT_TERMINAL_PROMPT','0','GCM_INTERACTIVE','never');
    [status,credential] = konaet_process({'git','-c','credential.interactive=never', ...
        '-c','credential.username=7dsolv','credential','fill'},query,env);
    assert(status == 0,'Konaet:OwnerAuthentication','Login GitHub do proprietario indisponivel.');
    value = regexp(credential,'(?m)^password=([^\r\n]+)','tokens','once');
    assert(~isempty(value),'Konaet:OwnerAuthentication','Credencial do proprietario ausente.');
    token = value{1}; clear credential value
end
account = github_get('/user',token);
assert(strcmp(account.login,'7dsolv'),'Konaet:WrongOwner','A conta autenticada precisa ser 7dsolv.');
child = struct('GH_TOKEN',token,'GH_HOST','github.com','GH_PROMPT_DISABLED','1');
% Secrets primeiro; a variavel que habilita a App somente depois de ambos.
for k = 1:2
    [status,~] = konaet_process({gh,'secret','set','KONAET_APP_PRIVATE_KEY', ...
        '--repo',plan.repositories{k}},pem,child,90);
    assert(status == 0,'Konaet:SecretUpload','Falha ao enviar Secret criptografado. Nenhum valor foi registrado.');
end
for k = 1:2
    [status,~] = konaet_process({gh,'variable','set','KONAET_APP_CLIENT_ID', ...
        '--body',plan.client_id,'--repo',plan.repositories{k}},'',child,90);
    assert(status == 0,'Konaet:VariableUpload','Falha ao configurar a variavel da App.');
end
report.credentials_configured = true;
commands = {{gh,'workflow','run','verificar-identidade.yml','--repo','7dsolv/konaet-bot','--ref','main'}, ...
    {gh,'workflow','run','simulacoes.yml','--repo','7dsolv/RealidadeQuantica','--ref','main','--field','module=agent'}};
for k = 1:numel(commands)
    [status,~] = konaet_process(commands{k},'',child,60);
    assert(status == 0,'Konaet:WorkflowDispatch','Credenciais configuradas; nao foi possivel disparar a verificacao.');
end
report.status = 'VERIFICATION_REQUESTED'; report.client_id = plan.client_id;
report.installation_id = plan.installation_id;
clear pem jwt token child
fprintf('Credenciais configuradas em 7dsolv. Verificacoes reais solicitadas; confira as execucoes antes de declarar VERIFIED.\n');
end

function result = github_get(route,token)
headers = {'Authorization',['Bearer ' token];'Accept','application/vnd.github+json'; ...
    'X-GitHub-Api-Version','2022-11-28';'User-Agent','KONAET-Activation'};
try
    result = webread(['https://api.github.com' route],weboptions('HeaderFields',headers,'Timeout',30));
catch
    error('Konaet:GitHubRequest','Nao foi possivel verificar %s no GitHub.',route);
end
end

function gh = resolve_gh(explicit)
gh = '';
if ~isempty(explicit), if isfile(explicit), gh = explicit; end; return; end
paths = strsplit(getenv('PATH'),pathsep);
if ispc
    paths = [{fullfile(getenv('LOCALAPPDATA'),'Konaet','tools','gh_2.103.3','bin')} paths];
    name = 'gh.exe';
else, name = 'gh'; end
for k = 1:numel(paths)
    candidate = fullfile(paths{k},name);
    if isfile(candidate), gh = candidate; return; end
end
end
