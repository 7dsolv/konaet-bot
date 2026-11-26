import assert from 'node:assert/strict';
import {execFileSync, spawnSync} from 'node:child_process';
import {mkdtempSync, rmSync, writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {test} from 'node:test';
import {fileURLToPath} from 'node:url';

const guard = fileURLToPath(new URL('../propose/check.mjs', import.meta.url));
const sample = ['ghs', 'eyJzdWJqZWN0IjoiZml4dHVyZSJ9', 'bG9jYWwtb25seS10ZXN0.U2lnbmF0dXJlLWZpeHR1cmU'].join('_');

function fixture(t) {
  const cwd = mkdtempSync(join(tmpdir(), 'konaet-proposal-'));
  t.after(() => rmSync(cwd, {recursive:true, force:true}));
  const git = (...args) => execFileSync('git', ['-c', 'core.hooksPath=.git/konaet-test-hooks', ...args], {cwd, encoding:'utf8', stdio:['ignore','pipe','pipe']}).trim();
  const write = (file, content) => writeFileSync(join(cwd, file), content);
  const commit = () => {
    git('add', '-A');
    git('commit', '-m', 'Update fixture');
    return git('rev-parse', 'HEAD');
  };
  git('init', '-q');
  git('config', 'user.email', 'fixture@example.invalid');
  git('config', 'user.name', 'KONAET Test');
  git('config', 'commit.gpgsign', 'false');
  write('catalog.txt', 'base');
  const base = commit();
  const check = (tip, body = '') => spawnSync(process.execPath, [guard, base, tip], {cwd, encoding:'utf8', env:{...process.env, PR_TITLE:'Resultado verificado', PR_BODY:body, COMMIT_MESSAGE:'Update fixture'}});
  return {base, check, commit, git, write};
}

function assertBlocked(run, message) {
  assert.equal(run.status, 1);
  assert.match(run.stderr, message);
  assert.equal((run.stdout + run.stderr).includes(sample), false);
}

test('allows regular generated content and a placeholder environment example', t => {
  const {write,commit,check} = fixture(t);
  write('catalog.txt', 'Produto verificado\n');
  write('.env.example', 'GITHUB_TOKEN=example\n');
  const run = check(commit());
  assert.equal(run.status, 0, run.stderr);
});

test('blocks credentials in committed content without disclosing them', t => {
  const {write,commit,check} = fixture(t);
  write('catalog.txt', sample);
  assertBlocked(check(commit()), /Credencial detectada/);
});

test('blocks credentials retained in history after a later commit removes them', t => {
  const {write,commit,check} = fixture(t);
  write('catalog.txt', sample);
  commit();
  write('catalog.txt', 'final content');
  assertBlocked(check(commit()), /Credencial detectada/);
});

test('checks proposal metadata before opening a PR', t => {
  const {write,commit,check} = fixture(t);
  write('catalog.txt', 'approved');
  assertBlocked(check(commit(), sample), /Credencial detectada/);
});

test('blocks reserved files and gitlinks', t => {
  const {base,write,commit,git,check} = fixture(t);
  write('.env.local', 'PORT=3000');
  assertBlocked(check(commit()), /arquivo reservado/);
  git('reset', '--hard', base);
  git('update-index', '--add', '--cacheinfo', '160000,'+base+',module');
  git('commit', '-m', 'Gitlink fixture');
  assertBlocked(check(git('rev-parse', 'HEAD')), /submódulo/);
});
