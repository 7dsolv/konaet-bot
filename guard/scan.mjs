#!/usr/bin/env node
// KONAET Guard — finds leaked secrets in the repository checked out by GitHub Actions.
// Runs entirely inside the workflow: no server, no API key, nothing is sent anywhere.
// Raw secret values are never printed: annotations show only a masked preview and a fingerprint.
import {execFileSync} from 'node:child_process';
import fs from 'node:fs';
import {scanText,SEVERITY_RANK,summarize} from './detectors.mjs';

const env=k=>(process.env[k]||'').trim();
const mode=env('GUARD_MODE')||'changed';
const failOn=env('GUARD_FAIL_ON')||'high';
const detectEmail=env('GUARD_DETECT_EMAIL')==='true';
const base=env('GUARD_BASE');const head=env('GUARD_HEAD')||'HEAD';
const excludes=env('GUARD_EXCLUDE').split(/\r?\n/).map(s=>s.trim()).filter(Boolean);
const MAX_BYTES=1024*1024;
const SKIP=/(?:^|\/)(?:node_modules|vendor|dist|build|\.git)\//;

const git=(...args)=>execFileSync('git',args,{encoding:'utf8',maxBuffer:256*1024*1024});
const gitBuf=(...args)=>{try {return execFileSync('git',args,{maxBuffer:64*1024*1024,stdio:['ignore','pipe','ignore']});} catch {return null;}};
const excluded=p=>SKIP.test(p)||excludes.some(e=>e.endsWith('/')?p.startsWith(e):p===e);

let files;
if(mode==='all'||!base) files=git('ls-files','-z').split('\0').filter(Boolean);
else files=git('diff','--name-only','-z','--diff-filter=ACMR',`${base}...${head}`).split('\0').filter(Boolean);
files=files.filter(f=>!excluded(f));

const findings=[];let scanned=0;
for(const file of files) {
  let stat;try {stat=fs.statSync(file);} catch {continue;}
  if(!stat.isFile()||stat.size>MAX_BYTES) continue;
  const text=fs.readFileSync(file,'utf8');
  if(text.includes('\u0000')) continue;
  scanned++;
  let found=scanText(text,{path:file,detectEmail});
  if(mode!=='all'&&base) {
    // Report only what this change introduced; a secret that already existed is not new.
    const before=gitBuf('show',`${base}:${file}`);
    if(before) {
      const old=new Set(scanText(before.toString('utf8'),{path:file,detectEmail}).map(f=>`${f.ruleId}:${f.fingerprint}`));
      found=found.filter(f=>!old.has(`${f.ruleId}:${f.fingerprint}`));
    }
  }
  findings.push(...found);
}

const threshold=failOn==='never'?Infinity:SEVERITY_RANK[failOn]??SEVERITY_RANK.high;
const blocking=findings.filter(f=>SEVERITY_RANK[f.severity]>=threshold);
const esc=s=>String(s).replace(/%/g,'%25').replace(/\r/g,'%0D').replace(/\n/g,'%0A').replace(/:/g,'%3A').replace(/,/g,'%2C');
for(const f of findings.slice(0,200)) {
  const level=SEVERITY_RANK[f.severity]>=threshold?'error':'warning';
  console.log(`::${level} file=${esc(f.path)},line=${f.line},col=${f.column},title=${esc(`KONAET Guard: ${f.title}`)}::${f.severity} · ${f.preview} · impressão ${f.fingerprint}. Revogue a credencial e remova do histórico.`);
}
const s=summarize(findings);
const lines=['## KONAET Guard',`${scanned} arquivo(s) verificado(s) (${mode==='all'||!base?'repositório inteiro':'arquivos alterados'}) · ${s.total} achado(s) · ${blocking.length} bloqueante(s) (limite: ${failOn})`,''];
if(findings.length) {
  lines.push('| Severidade | Tipo | Arquivo | Linha | Prévia mascarada |','|---|---|---|---|---|');
  for(const f of findings.slice(0,100)) lines.push(`| ${f.severity} | ${f.title} | \`${f.path}\` | ${f.line} | \`${f.preview}\` |`);
} else lines.push('Nenhum segredo encontrado. ✅');
lines.push('','<sub>Nenhum valor secreto é exibido ou enviado: só prévia mascarada e impressão SHA-256.</sub>');
if(process.env.GITHUB_STEP_SUMMARY) fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY,lines.join('\n')+'\n');
if(process.env.GITHUB_OUTPUT) fs.appendFileSync(process.env.GITHUB_OUTPUT,`findings=${s.total}\nblocking=${blocking.length}\nscanned=${scanned}\n`);
console.log(`KONAET Guard: ${scanned} arquivo(s), ${s.total} achado(s), ${blocking.length} bloqueante(s).`);
if(blocking.length) process.exitCode=1;
