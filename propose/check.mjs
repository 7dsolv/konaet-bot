import {execFileSync, spawnSync} from 'node:child_process';
import {containsCredential} from './detectors.mjs';

const maxCommits = 128;
const maxFileBytes = 8 * 1024 * 1024;
const maxBytes = 32 * 1024 * 1024;
const sensitiveFile = /(?:^|\/)(?:\.env(?:\.[^/]+)?|id_(?:rsa|dsa|ecdsa|ed25519)|[^/]+\.(?:pem|key|p12|pfx|kdbx))$/i;
const exampleFile = /(?:^|\/)\.env\.(?:example|sample|template)$/i;

class Rejected extends Error {}
const block = message => { throw new Rejected(message); };

function git(...args) {
  return execFileSync('git', args, {stdio: ['ignore', 'pipe', 'pipe'], maxBuffer: maxFileBytes + 1024});
}

function ensureText(text) {
  if (containsCredential(text)) block('Credencial detectada na proposta. Remova a credencial antes de publicar.');
}

function reviewDiff(from, to, reviewed, budget) {
  const entries = git('diff', '--raw', '--no-abbrev', '--no-renames', '--diff-filter=ACMT', '-z', from, to, '--')
    .toString('utf8').split('\0');
  for (let index = 0; index + 1 < entries.length; index += 2) {
    const header = entries[index].match(/^:\d{6} (\d{6}) [a-f0-9]+ ([a-f0-9]+) [ACMT]$/);
    if (!header) block('Não foi possível verificar o diff da proposta.');
    const [, mode, oid] = header;
    const file = entries[index + 1];
    ensureText(file);
    if (sensitiveFile.test(file) && !exampleFile.test(file)) block('A proposta contém um arquivo reservado para credenciais.');
    if (mode !== '100644' && mode !== '100755') block('A proposta contém um link simbólico ou submódulo.');
    if (reviewed.has(oid)) continue;
    const size = Number(git('cat-file', '-s', oid));
    if (!Number.isSafeInteger(size) || size < 0 || size > maxFileBytes || budget.bytes + size > maxBytes) {
      block('A proposta é grande demais para a inspeção. Divida as alterações e tente novamente.');
    }
    budget.bytes += size;
    const blob = git('cat-file', 'blob', oid);
    ensureText(blob.toString('utf8').replaceAll('\0', ' '));
    reviewed.add(oid);
  }
}

function verifyProposal() {
  for (const name of ['PR_TITLE', 'PR_BODY', 'COMMIT_MESSAGE', 'PROPOSAL_BRANCH', 'BASE_BRANCH', 'ALLOW_PATHS']) {
    ensureText(process.env[name] || '');
  }
  const [base, tip] = process.argv.slice(2);
  if (base === '--metadata' && tip === undefined) return;
  const hash = /^(?:[a-f0-9]{40}|[a-f0-9]{64})$/;
  if (!hash.test(base || '') || !hash.test(tip || '')) block('Referência inválida para verificar a proposta.');
  const commits = git('rev-list', `--max-count=${maxCommits + 1}`, `${base}..${tip}`).toString().trim().split(/\s+/).filter(Boolean);
  if (commits.length > maxCommits) block('A proposta tem muitos commits para inspeção. Divida as alterações.');
  const reviewed = new Set();
  const budget = {bytes: 0};
  for (const commit of commits) {
    ensureText(git('show', '-s', '--format=%B', commit).toString());
    const parents = git('show', '-s', '--format=%P', commit).toString().trim().split(/\s+/).filter(Boolean);
    if (!parents.length) block('Histórico incompleto para inspecionar a proposta.');
    const parent = parents.length > 1
      ? parents.find(candidate => spawnSync('git', ['merge-base', '--is-ancestor', candidate, base], {stdio: 'ignore'}).status === 0) || parents[0]
      : parents[0];
    reviewDiff(parent, commit, reviewed, budget);
  }
  reviewDiff(git('merge-base', base, tip).toString().trim(), tip, reviewed, budget);
  process.stdout.write('Verificação local da proposta aprovada.\n');
}

try {
  verifyProposal();
} catch (error) {
  process.stderr.write((error instanceof Rejected ? error.message : 'Não foi possível concluir a inspeção local da proposta.')+'\n');
  process.exitCode = 1;
}
