function report = run_konaet_tests(root, output_dir)
%RUN_KONAET_TESTS Contratos offline e integracao Git real, sem credenciais.
%   O gh e substituido por um fixture local; commits, fetches e pushes usam
%   repositorios Git bare temporarios. Nenhuma App real e simulada como ativa.
if nargin < 1, root = fileparts(fileparts(mfilename('fullpath'))); end
if nargin < 2, output_dir = fullfile(root, 'artifacts'); end
assert(isunix, 'Os testes de infraestrutura exigem Linux com Bash e Git.');
if ~isfolder(output_dir), mkdir(output_dir); end
started = tic;
cases = struct('name', {}, 'group', {}, 'passed', {}, 'seconds', {}, 'error', {}, 'error_id', {});
identity_names = {'valid-bot', 'wrong-slug', 'empty-slug', 'invalid-id', ...
    'wrong-login', 'user-is-not-bot', 'api-failure'};
proposal_names = {'no-change', 'new-proposal', 'delete-and-create', 'spaces', ...
    'outside-allowlist', 'staged-outside-allowlist', 'path-traversal', ...
    'path-magic', 'protected-branch', 'workflow-file', 'wrong-origin', ...
    'stale-branch', 'existing-pr', 'recover-after-api-failure', ...
    'concurrent-pr', 'literal-inputs', 'unexpected-pr-url', 'push-race', ...
    'empty-allowlist', 'wrong-push-url', 'newline-filename', 'unchanged-remote', ...
    'rename-within', 'rename-from-outside', 'hook-stages-outside', ...
    'author-environment', 'remote-outside-allowlist', 'recovery-outside-allowlist', ...
    'glob-path', 'merged-remote'};
for i = 1:numel(identity_names)
    name = identity_names{i};
    cases(end+1) = evaluate(name, 'identity-offline', @() identity_case(root, name)); %#ok<AGROW>
    if strcmp(cases(end).error_id, 'Konaet:FixtureTimeout'), break; end
end
if ~any(strcmp({cases.error_id}, 'Konaet:FixtureTimeout'))
    for i = 1:numel(proposal_names)
        name = proposal_names{i};
        cases(end+1) = evaluate(name, 'git-integration-offline', @() proposal_case(root, name)); %#ok<AGROW>
        if strcmp(cases(end).error_id, 'Konaet:FixtureTimeout'), break; end
    end
end
cases(end+1) = evaluate('registration-contract', 'matlab', @() registration_case(root));
report.schema_version = 1;
report.revision = getenv('GITHUB_SHA');
report.mode = 'offline-contract-and-real-local-git';
report.total = numel(cases);
report.planned = numel(identity_names) + numel(proposal_names) + 1;
report.complete = report.total == report.planned;
report.passed = sum([cases.passed]);
report.failed = report.total - report.passed;
report.seconds = toc(started);
report.cases = cases;
report.live_app.status = 'NOT_RUN';
report.live_app.reason = 'Sem credenciais de App; gh de teste nao faz chamadas de rede.';
report.generated_utc = char(datetime('now', 'TimeZone', 'UTC', ...
    'Format', "yyyy-MM-dd'T'HH:mm:ss'Z'"));
write_text(fullfile(output_dir, 'test-report.json'), jsonencode(report, PrettyPrint=true));
fprintf('\nKonaet: %d/%d cenarios aprovados; App real: NOT_RUN.\n', report.passed, report.total);
assert(report.failed == 0, 'Konaet:TestFailure', '%d cenario(s) falharam.', report.failed);
end

function item = evaluate(name, group, callback)
timer = tic;
item = struct('name', name, 'group', group, 'passed', false, 'seconds', 0, 'error', '', 'error_id', '');
try
    callback();
    item.passed = true;
    fprintf('[PASS] %s / %s\n', group, name);
catch problem
    item.error = problem.message;
    item.error_id = problem.identifier;
    fprintf('[FAIL] %s / %s: %s\n', group, name, problem.message);
end
item.seconds = toc(timer);
end

function identity_case(root, name)
[f, guard] = fixture(root); %#ok<ASGLU>
script = extract_script(fullfile(root, 'action.yml'), 'identity');
setenv('APP_SLUG', 'konaet');
setenv('EXPECTED_SLUG', 'konaet');
record = sprintf('1234\tkonaet[bot]\tBot\n');
switch name
    case 'wrong-slug', setenv('EXPECTED_SLUG', 'outro');
    case 'empty-slug', setenv('EXPECTED_SLUG', '');
    case 'invalid-id', record = sprintf('bad\tkonaet[bot]\tBot\n');
    case 'wrong-login', record = sprintf('1234\toutro[bot]\tBot\n');
    case 'user-is-not-bot', record = sprintf('1234\tkonaet[bot]\tUser\n');
    case 'api-failure', write_text(fullfile(f.mock, 'api.fail'), '1');
end
write_text(fullfile(f.mock, 'identity.tsv'), record);
[status, ~] = execute(f, script);
if strcmp(name, 'valid-bot')
    assert(status == 0, 'Identidade valida foi recusada.');
    out = fileread(f.output);
    assert(contains(out, 'login=konaet[bot]') && contains(out, 'id=1234'));
    assert(contains(out, 'email=1234+konaet[bot]@users.noreply.github.com'));
else
    assert(status ~= 0, 'Identidade invalida foi aceita.');
    assert(~isfile(f.output) || ~contains(fileread(f.output), 'login='));
end
end

function proposal_case(root, name)
[f, guard] = fixture(root); %#ok<ASGLU>
script = extract_script(fullfile(root, 'propose', 'action.yml'), 'propose');
setenv('BOT_LOGIN', 'konaet[bot]'); setenv('BOT_ID', '1234');
setenv('ALLOW_PATHS', 'data'); setenv('PROPOSAL_BRANCH', 'konaet/updates');
setenv('BASE_BRANCH', 'main'); setenv('DEFAULT_BRANCH', 'main');
setenv('SERVER_URL', 'https://github.com');
setenv('PR_TITLE', 'Atualizar dados'); setenv('PR_BODY', 'Revisar os dados gerados.');
setenv('COMMIT_MESSAGE', 'Atualizar dados para revisao');
write_text(fullfile(f.work, 'data', 'value.txt'), 'updated');
expected_failure = false;
switch name
    case 'no-change'
        git(f, 'checkout -- data/value.txt');
    case 'unchanged-remote'
        git(f, 'checkout -- data/value.txt');
        git(f, 'push origin HEAD:refs/heads/konaet/updates');
    case 'merged-remote'
        git(f, 'checkout -- data/value.txt'); seed_proposal(f);
        prior = remote_head(f, 'konaet/updates');
        git(f, 'switch main'); git(f, 'merge --no-ff konaet/updates -m merge');
        git(f, 'push origin main');
    case 'glob-path'
        setenv('ALLOW_PATHS', 'data/*'); expected_failure = true;
    case 'rename-within'
        git(f, 'checkout -- data/value.txt');
        git(f, 'mv data/value.txt data/renamed.txt');
    case 'rename-from-outside'
        git(f, 'mv fixture-source.txt data/imported.txt'); expected_failure = true;
    case 'hook-stages-outside'
        hook_path = fullfile(f.work, '.git', 'hooks', 'pre-commit');
        write_text(hook_path, sprintf('#!/bin/sh\nprintf outside > hook-outside.txt\ngit add hook-outside.txt\n'));
        cmd(['chmod 700 ' q(hook_path)]); expected_failure = true;
    case 'author-environment'
        setenv('GIT_AUTHOR_NAME', 'Unexpected'); setenv('GIT_AUTHOR_EMAIL', 'unexpected@example.invalid');
        setenv('GIT_COMMITTER_NAME', 'Unexpected'); setenv('GIT_COMMITTER_EMAIL', 'unexpected@example.invalid');
    case {'remote-outside-allowlist', 'recovery-outside-allowlist'}
        git(f, 'checkout -- data/value.txt'); seed_proposal(f);
        write_text(fullfile(f.work, 'remote-outside.txt'), 'outside');
        git(f, 'add remote-outside.txt'); git(f, 'commit -m outside');
        git(f, 'push origin HEAD:refs/heads/konaet/updates');
        prior = remote_head(f, 'konaet/updates');
        if strcmp(name, 'remote-outside-allowlist')
            write_text(fullfile(f.work, 'data', 'value.txt'), 'third-update');
        end
        expected_failure = true;
    case 'empty-allowlist'
        setenv('ALLOW_PATHS', ''); expected_failure = true;
    case 'wrong-push-url'
        git(f, 'config remote.origin.pushurl https://github.com/outro/repositorio.git');
        expected_failure = true;
    case 'newline-filename'
        write_text(fullfile(f.work, 'data', sprintf('quebra\nlinha.txt')), 'newline');
        expected_failure = true;
    case 'delete-and-create'
        delete(fullfile(f.work, 'data', 'value.txt'));
        write_text(fullfile(f.work, 'data', 'new.txt'), 'new');
    case 'spaces'
        write_text(fullfile(f.work, 'data', 'novo arquivo.txt'), 'spaces');
    case 'outside-allowlist'
        write_text(fullfile(f.work, 'other.txt'), 'outside'); expected_failure = true;
    case 'staged-outside-allowlist'
        write_text(fullfile(f.work, 'other.txt'), 'outside');
        git(f, 'add other.txt'); expected_failure = true;
    case 'path-traversal'
        setenv('ALLOW_PATHS', '../data'); expected_failure = true;
    case 'path-magic'
        setenv('ALLOW_PATHS', ':(glob)**'); expected_failure = true;
    case 'protected-branch'
        setenv('PROPOSAL_BRANCH', 'main'); expected_failure = true;
    case 'workflow-file'
        mkdir(fullfile(f.work, '.github', 'workflows'));
        write_text(fullfile(f.work, '.github', 'workflows', 'bad.yml'), 'name: bad');
        setenv('ALLOW_PATHS', sprintf('data\n.github')); expected_failure = true;
    case 'wrong-origin'
        git(f, 'remote set-url origin https://github.com/outro/repositorio.git');
        expected_failure = true;
    case 'stale-branch'
        git(f, 'checkout -- data/value.txt');
        seed_proposal(f);
        prior = remote_head(f, 'konaet/updates');
        git(f, 'switch main');
        write_text(fullfile(f.work, 'data', 'value.txt'), 'local-new');
        expected_failure = true;
    case 'existing-pr'
        git(f, 'checkout -- data/value.txt'); seed_proposal(f);
        prior = remote_head(f, 'konaet/updates');
        write_text(fullfile(f.work, 'data', 'value.txt'), 'second-update');
        write_text(fullfile(f.mock, 'pr.tsv'), pr_record());
    case 'recover-after-api-failure'
        write_text(fullfile(f.mock, 'create.fail'), 'once');
    case 'concurrent-pr'
        write_text(fullfile(f.mock, 'create.fail'), 'once');
        write_text(fullfile(f.mock, 'race'), '1');
    case 'literal-inputs'
        sentinel = fullfile(f.work, 'INJECTION_EXECUTED');
        title = ['$(touch ' sentinel ')'];
        body = sprintf('`touch %s`\n$(touch %s)', sentinel, sentinel);
        setenv('PR_TITLE', title); setenv('PR_BODY', body);
    case 'unexpected-pr-url'
        write_text(fullfile(f.mock, 'pr.tsv'), sprintf('23\thttps://github.com/outro/repo/pull/23\n'));
        expected_failure = true;
    case 'push-race'
        git(f, 'checkout -- data/value.txt');
        other = git(f, 'commit-tree HEAD^{tree} -p HEAD -m concorrente');
        git(f, ['push origin ' other ':refs/heads/race-source']);
        hook = sprintf('#!/bin/sh\ngit --git-dir=%s update-ref refs/heads/konaet/updates %s\n', q(f.remote), other);
        hook_path = fullfile(f.work, '.git', 'hooks', 'pre-push');
        write_text(hook_path, hook); cmd(['chmod 700 ' q(hook_path)]);
        write_text(fullfile(f.work, 'data', 'value.txt'), 'racing-change');
        expected_failure = true;
end
base = bare_git(f, 'rev-parse refs/heads/main');
[status, log] = execute(f, script);
if strcmp(name, 'recover-after-api-failure')
    assert(status ~= 0 && ~isempty(remote_head(f, 'konaet/updates')), 'Falha da API nao exercitou push parcial.');
    pushed = remote_head(f, 'konaet/updates');
    [status, log] = execute(f, script);
    assert(status == 0, 'Recuperacao falhou: %s', log);
    assert(strcmp(pushed, remote_head(f, 'konaet/updates')), 'Recuperacao criou commit duplicado.');
    assert(contains(fileread(f.output), 'changed=false'));
elseif expected_failure
    assert(status ~= 0, 'Cenario adverso foi aceito.');
else
    assert(status == 0, 'Proposta falhou: %s', log);
end
assert(strcmp(base, bare_git(f, 'rev-parse refs/heads/main')), 'Branch base foi alterada.');
if ismember(name, {'no-change', 'unchanged-remote', 'merged-remote'})
    if strcmp(name, 'no-change')
        assert(isempty(remote_head(f, 'konaet/updates')));
    elseif strcmp(name, 'unchanged-remote')
        assert(strcmp(base, remote_head(f, 'konaet/updates')));
    else
        assert(strcmp(prior, remote_head(f, 'konaet/updates')));
    end
    assert(contains(fileread(f.output), 'changed=false'));
    assert(~isfile(fullfile(f.mock, 'gh.log')), 'Sem mudancas nao deveria chamar API.');
elseif ismember(name, {'stale-branch', 'remote-outside-allowlist', 'recovery-outside-allowlist'})
    assert(strcmp(prior, remote_head(f, 'konaet/updates')), 'Branch divergente foi sobrescrita.');
elseif strcmp(name, 'push-race')
    assert(strcmp(other, remote_head(f, 'konaet/updates')), 'Push sobrescreveu o commit concorrente.');
elseif expected_failure
    if ~strcmp(name, 'unexpected-pr-url')
        assert(isempty(remote_head(f, 'konaet/updates')), 'Uma validacao recusada enviou commit.');
    else
        assert(~contains(fileread(fullfile(f.mock, 'gh.log')), 'pr edit'), 'Proposta de outro repositorio foi editada.');
    end
else
    assert(contains(fileread(f.output), 'pr-url=https://github.com/konaet-tests/fixture/pull/23'));
    assert(strcmp(bare_git(f, 'show -s --format=%an refs/heads/konaet/updates'), 'konaet[bot]'));
    assert(strcmp(bare_git(f, 'show -s --format=%ae refs/heads/konaet/updates'), ...
        '1234+konaet[bot]@users.noreply.github.com'));
    assert(strcmp(bare_git(f, 'show -s --format=%cn refs/heads/konaet/updates'), 'konaet[bot]'));
    switch name
        case 'existing-pr'
            assert(~strcmp(prior, remote_head(f, 'konaet/updates')));
            calls = fileread(fullfile(f.mock, 'gh.log'));
            assert(contains(calls, 'pr edit') && ~contains(calls, 'pr create'));
        case 'delete-and-create'
            [missing, ~] = system(['git --git-dir=' q(f.remote) ' cat-file -e refs/heads/konaet/updates:data/value.txt 2>/dev/null']);
            assert(missing ~= 0, 'Arquivo removido permaneceu na proposta.');
            assert(strcmp(bare_git(f, 'show refs/heads/konaet/updates:data/new.txt'), 'new'));
        case 'spaces'
            assert(strcmp(bare_git(f, ['show ' q('refs/heads/konaet/updates:data/novo arquivo.txt')]), 'spaces'));
        case 'rename-within'
            assert(strcmp(bare_git(f, 'show refs/heads/konaet/updates:data/renamed.txt'), 'base'));
        case 'literal-inputs'
            assert(~isfile(sentinel), 'Entrada textual executou um comando.');
            assert(strcmp(fileread(fullfile(f.mock, 'title')), title));
            assert(strcmp(fileread(fullfile(f.mock, 'body')), [body newline]));
        case 'concurrent-pr'
            assert(contains(fileread(fullfile(f.mock, 'gh.log')), 'pr edit'));
    end
end
end

function registration_case(root)
addpath(root);
u = abrir_cadastro_konaet(false);
p = matlab.net.URI(u);
assert(strcmp(p.Host, 'github.com') && strcmp(p.Path(end), 'new'));
assert(contains(u, 'name=Konaet') && contains(u, 'public=true'));
assert(contains(u, 'webhook_active=false') && contains(u, 'contents=write') && contains(u, 'pull_requests=write'));
c = jsondecode(fileread(fullfile(root, 'github-app.json')));
assert(isequal(sort(fieldnames(c.default_permissions)), {'contents'; 'pull_requests'}));
assert(c.public && ~c.hook_attributes.active && isempty(c.default_events));
end

function [f, guard] = fixture(~)
f.folder = tempname;
mkdir(f.folder); f.remote = fullfile(f.folder, 'remote.git');
f.work = fullfile(f.folder, 'work'); f.mock = fullfile(f.folder, 'mock');
mkdir(f.mock); f.output = fullfile(f.folder, 'outputs');
names = {'PATH','GH_TOKEN','GH_HOST','GITHUB_REPOSITORY','GITHUB_OUTPUT', ...
    'MOCK_DIR','APP_SLUG','EXPECTED_SLUG','BOT_LOGIN','BOT_ID','ALLOW_PATHS', ...
    'PROPOSAL_BRANCH','BASE_BRANCH','DEFAULT_BRANCH','SERVER_URL','PR_TITLE','PR_BODY','COMMIT_MESSAGE', ...
    'GIT_AUTHOR_NAME','GIT_AUTHOR_EMAIL','GIT_COMMITTER_NAME','GIT_COMMITTER_EMAIL', ...
    'GIT_TERMINAL_PROMPT','BASH_ENV'};
old = cellfun(@getenv, names, UniformOutput=false);
guard = onCleanup(@() cleanup_fixture(f.folder, names, old));
% Um valor vazio restaurado por setenv ainda pode existir no ambiente do Git.
% O repositorio fixture sempre comeca com uma identidade explicita e isolada.
setenv('GIT_AUTHOR_NAME', 'Fixture'); setenv('GIT_AUTHOR_EMAIL', 'fixture@example.invalid');
setenv('GIT_COMMITTER_NAME', 'Fixture'); setenv('GIT_COMMITTER_EMAIL', 'fixture@example.invalid');
setenv('GIT_TERMINAL_PROMPT', '0'); setenv('BASH_ENV', '');
cmd(['git init --bare --initial-branch=main ' q(f.remote)]);
cmd(['git clone ' q(f.remote) ' ' q(f.work)]);
git(f, 'config user.name Fixture'); git(f, 'config user.email fixture@example.invalid');
mkdir(fullfile(f.work, 'data')); write_text(fullfile(f.work, 'data', 'value.txt'), 'base');
write_text(fullfile(f.work, 'fixture-source.txt'), 'source');
git(f, 'add data/value.txt fixture-source.txt'); git(f, 'commit -m base'); git(f, 'push -u origin main');
git(f, ['config ' q(['url.' f.remote '.insteadOf']) ' https://github.com/konaet-tests/fixture.git']);
git(f, 'remote set-url origin https://github.com/konaet-tests/fixture.git');
write_text(fullfile(f.mock, 'gh'), mock_gh());
cmd(['chmod 700 ' q(fullfile(f.mock, 'gh'))]);
setenv('PATH', [f.mock pathsep getenv('PATH')]);
setenv('GH_TOKEN', 'offline-fixture-not-a-token'); setenv('GH_HOST', 'github.com');
setenv('GITHUB_REPOSITORY', 'konaet-tests/fixture'); setenv('GITHUB_OUTPUT', f.output);
setenv('MOCK_DIR', f.mock);
end

function seed_proposal(f)
git(f, 'switch -c konaet/updates');
write_text(fullfile(f.work, 'data', 'value.txt'), 'first-update');
git(f, 'add data/value.txt'); git(f, 'commit -m first');
git(f, 'push origin HEAD:refs/heads/konaet/updates');
end

function [status, log] = execute(f, script)
write_text(fullfile(f.folder, 'step.bash'), script);
if isfile(f.output), delete(f.output); end
[status, log] = system(['cd ' q(f.work) ' && timeout --kill-after=5s 30s bash -x ' q(fullfile(f.folder, 'step.bash')) ' 2>&1']);
if ismember(status, [124 137])
    tail = log(max(1,end-6000):end);
    error('Konaet:FixtureTimeout', 'Script local excedeu 30 s. Ultimo trace:\n%s', tail);
end
end

function script = extract_script(path, id)
lines = splitlines(string(fileread(path)));
start = find(strtrim(lines) == "id: " + string(id), 1);
assert(~isempty(start), 'Step nao encontrado: %s', id);
run = start - 1 + find(strtrim(lines(start:end)) == "run: |", 1);
assert(~isempty(run), 'Script ausente: %s', id);
indent = strlength(lines(run)) - strlength(strip(lines(run), 'left'));
body = strings(0,1);
for i = run+1:numel(lines)
    line = char(lines(i));
    if isempty(strtrim(line)), body(end+1,1) = ""; continue; end %#ok<AGROW>
    leading = numel(line) - numel(strtrim_left(line));
    if leading <= indent, break; end
    assert(leading >= indent + 2, 'Indentacao inesperada no script.');
    body(end+1,1) = string(line(indent+3:end)); %#ok<AGROW>
end
script = char(join(body, newline) + newline);
end

function s = strtrim_left(s)
s = regexprep(s, '^\s+', '');
end

function result = git(f, args)
result = cmd(['git -C ' q(f.work) ' ' args]);
end

function result = bare_git(f, args)
result = cmd(['git --git-dir=' q(f.remote) ' ' args]);
end

function sha = remote_head(f, branch)
[status, value] = system(['git --git-dir=' q(f.remote) ' rev-parse --verify ' q(['refs/heads/' branch]) ' 2>/dev/null']);
if status == 0, sha = strtrim(value); else, sha = ''; end
end

function value = cmd(command)
[status, value] = system(['timeout --kill-after=5s 20s ' command ' 2>&1']);
assert(status == 0, 'Comando falhou: %s\n%s', command, value);
value = strtrim(value);
end

function quoted = q(value)
single_quote = char(39); double_quote = char(34);
quoted = [single_quote strrep(char(value), single_quote, ...
    [single_quote double_quote single_quote double_quote single_quote]) single_quote];
end

function write_text(path, value)
fid = fopen(path, 'w', 'n', 'UTF-8'); assert(fid >= 0, 'Falha ao abrir %s.', path);
guard = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', char(value));
end

function cleanup_fixture(folder, names, values)
for i = 1:numel(names), setenv(names{i}, values{i}); end
assert(startsWith(folder, tempdir) && numel(folder) > numel(tempdir));
if isfolder(folder), rmdir(folder, 's'); end
end

function record = pr_record()
record = sprintf('23\thttps://github.com/konaet-tests/fixture/pull/23\n');
end

function script = mock_gh()
lines = [
"#!/usr/bin/env bash"
"set -euo pipefail"
"printf '%s\n' ""$*"" >> ""$MOCK_DIR/gh.log"""
"if [ ""$1"" = api ]; then"
"  [ ! -f ""$MOCK_DIR/api.fail"" ] || exit 41"
"  cat ""$MOCK_DIR/identity.tsv""; exit 0"
"fi"
"[ ""$1"" = pr ] || exit 90"
"sub=""$2""; shift 2"
"save_fields() {"
"  while [ ""$#"" -gt 0 ]; do"
"    case ""$1"" in"
"      --title) printf '%s' ""$2"" > ""$MOCK_DIR/title""; shift 2 ;;"
"      --body-file) cp ""$2"" ""$MOCK_DIR/body""; shift 2 ;;"
"      *) shift ;;"
"    esac"
"  done"
"}"
"case ""$sub"" in"
"  list) [ ! -f ""$MOCK_DIR/pr.tsv"" ] || cat ""$MOCK_DIR/pr.tsv"" ;;"
"  create)"
"    if [ -f ""$MOCK_DIR/create.fail"" ]; then"
"      rm ""$MOCK_DIR/create.fail"""
"      if [ -f ""$MOCK_DIR/race"" ]; then"
"        printf '23\thttps://github.com/konaet-tests/fixture/pull/23\n' > ""$MOCK_DIR/pr.tsv"""
"      fi"
"      exit 42"
"    fi"
"    save_fields ""$@"""
"    printf '23\thttps://github.com/konaet-tests/fixture/pull/23\n' > ""$MOCK_DIR/pr.tsv"""
"    printf 'https://github.com/konaet-tests/fixture/pull/23\n'"
"    ;;"
"  edit) save_fields ""$@"" ;;"
"  *) exit 91 ;;"
"esac"
];
script = char(join(lines, newline) + newline);
end
