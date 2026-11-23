// Copied verbatim from KONAET Revenue Engine src/privacy/detectors.js — keep both in sync (tests compare them).
/**
 * KONAET Privacy Guard — detectors for secrets and personal data.
 *
 * A finding never carries the raw value: only the rule, the position, a
 * SHA-256 fingerprint (first 16 hex chars, enough to compare two scans) and a
 * masked preview that keeps the public prefix of the token format.
 */
import {createHash} from 'node:crypto';

export const fingerprint=value=>createHash('sha256').update(String(value)).digest('hex').slice(0,16);

export function shannonEntropy(text) {
  if(!text) return 0;
  const counts=new Map();
  for(const ch of text) counts.set(ch,(counts.get(ch)||0)+1);
  let h=0;
  for(const n of counts.values()) {const p=n/text.length;h-=p*Math.log2(p);}
  return h;
}

const PLACEHOLDER_RE=/^(?:\$\{\{?|\$\(|\$[A-Z_]+$|%[A-Z_]+%$|process\.env|os\.environ|getenv|env\.|secrets\.|vars\.|<[^>]*>|\{\{|\[[^\]]*\]$|x{4,}|\*{3,}|\.{3,}|change[-_ ]?me|example|exemplo|placeholder|your[-_ ]|seu[-_ ]|sua[-_ ]|dummy|sample|redacted|fake|todo|null|none|undefined|true|false|password|senha|secret|token)/i;
const isPlaceholder=v=>PLACEHOLDER_RE.test(v)||/^(.)\1+$/.test(v)||/^[a-z]+(?:[_-][a-z]+)*$/.test(v);

function luhn(digits) {
  let sum=0,alt=false;
  for(let i=digits.length-1;i>=0;i--) {
    let n=digits.charCodeAt(i)-48;
    if(alt) {n*=2;if(n>9) n-=9;}
    sum+=n;alt=!alt;
  }
  return sum%10===0;
}
function validCard(raw) {
  const d=raw.replace(/[ -]/g,'');
  if(d.length<13||d.length>19||/^(\d)\1+$/.test(d)) return false;
  // Visa, Mastercard, Amex, Elo/Discover, Hipercard, Diners, JCB prefixes.
  if(!/^(?:4|5[1-5]|2[2-7]|3[47]|6|3(?:0[0-5]|[68])|35|606282|3841)/.test(d)) return false;
  return luhn(d);
}
function validCpf(raw) {
  const d=raw.replace(/\D/g,'');
  if(d.length!==11||/^(\d)\1{10}$/.test(d)) return false;
  const check=len=>{
    let s=0;for(let i=0;i<len;i++) s+=Number(d[i])*(len+1-i);
    const r=(s*10)%11;return r===10?0:r;
  };
  return check(9)===Number(d[9])&&check(10)===Number(d[10]);
}

/**
 * Rules are evaluated in order; when two matches overlap, the earlier rule wins.
 * `group` selects the capture group holding the sensitive value.
 */
export const RULES=Object.freeze([
  {id:'private-key',category:'secret',severity:'critical',title:'Chave privada (PEM/OpenSSH/PGP)',
    re:/-----BEGIN (?:[A-Z0-9]+ )*PRIVATE KEY(?: BLOCK)?-----[\s\S]{0,6000}?(?:-----END (?:[A-Z0-9]+ )*PRIVATE KEY(?: BLOCK)?-----|$)/g,prefix:'-----BEGIN'},
  {id:'github-token',category:'secret',severity:'critical',title:'Token do GitHub',re:/(?<![A-Za-z0-9_])gh[pousr]_[A-Za-z0-9]{36,251}(?![A-Za-z0-9_])/g,prefix:4},
  {id:'github-fine-grained-pat',category:'secret',severity:'critical',title:'Token fine-grained do GitHub',re:/(?<![A-Za-z0-9_])github_pat_[A-Za-z0-9_]{60,251}(?![A-Za-z0-9_])/g,prefix:11},
  {id:'konaet-api-key',category:'secret',severity:'critical',title:'Chave da API KONAET',re:/(?<![A-Za-z0-9_])knt_(?:live|demo)_[a-f0-9]{12}_[A-Za-z0-9_-]{43}(?![A-Za-z0-9_-])/g,prefix:9},
  {id:'anthropic-api-key',category:'secret',severity:'critical',title:'Chave de API Anthropic',re:/(?<![A-Za-z0-9_-])sk-ant-[A-Za-z0-9_-]{32,250}(?![A-Za-z0-9_-])/g,prefix:7},
  {id:'openai-api-key',category:'secret',severity:'critical',title:'Chave de API OpenAI',re:/(?<![A-Za-z0-9_-])sk-(?:proj-|svcacct-|admin-)?[A-Za-z0-9_-]{32,250}(?![A-Za-z0-9_-])/g,prefix:3},
  {id:'huggingface-token',category:'secret',severity:'critical',title:'Token do Hugging Face',re:/(?<![A-Za-z0-9_])hf_[A-Za-z0-9]{30,64}(?![A-Za-z0-9_])/g,prefix:3},
  {id:'aws-access-key-id',category:'secret',severity:'high',title:'ID de chave de acesso AWS',re:/(?<![A-Z0-9])(?:AKIA|ASIA|ABIA|ACCA)[0-9A-Z]{16}(?![A-Z0-9])/g,prefix:4},
  {id:'aws-secret-access-key',category:'secret',severity:'critical',title:'Chave secreta AWS',
    re:/aws_?secret_?access_?key["'\s]*[:=]\s*["']?([A-Za-z0-9/+=]{40})(?![A-Za-z0-9/+=])/gi,group:1,prefix:0},
  {id:'google-api-key',category:'secret',severity:'high',title:'Chave de API Google',re:/(?<![A-Za-z0-9_-])AIza[0-9A-Za-z_-]{35}(?![0-9A-Za-z_-])/g,prefix:4},
  {id:'slack-token',category:'secret',severity:'high',title:'Token do Slack',re:/(?<![A-Za-z0-9])xox[abposr]-[A-Za-z0-9-]{10,250}/g,prefix:5},
  {id:'slack-webhook',category:'secret',severity:'high',title:'Webhook do Slack',re:/https:\/\/hooks\.slack\.com\/services\/[A-Za-z0-9/_-]{20,200}/g,prefix:29},
  {id:'stripe-secret-key',category:'secret',severity:'critical',title:'Chave secreta Stripe',re:/(?<![A-Za-z0-9_])(?:sk|rk)_live_[A-Za-z0-9]{20,250}(?![A-Za-z0-9_])/g,prefix:8},
  {id:'npm-token',category:'secret',severity:'high',title:'Token do npm',re:/(?<![A-Za-z0-9_])npm_[A-Za-z0-9]{36}(?![A-Za-z0-9_])/g,prefix:4},
  {id:'jwt',category:'secret',severity:'high',title:'JSON Web Token',re:/(?<![A-Za-z0-9_-])eyJ[A-Za-z0-9_-]{8,}\.eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}/g,prefix:3},
  {id:'url-credentials',category:'secret',severity:'high',title:'Senha embutida em URL',
    re:/\b[a-z][a-z0-9+.-]{1,20}:\/\/[^\s:/@"'<>]{1,100}:([^\s:/@"'<>]{3,200})@[^\s/"'<>]+/gi,group:1,prefix:0,validate:v=>!isPlaceholder(v)},
  {id:'generic-secret',category:'secret',severity:'medium',title:'Segredo atribuído no código ou config',
    re:/(?<![A-Za-z0-9])(?:password|passwd|pwd|senha|secret|client[_-]?secret|api[_-]?key|apikey|access[_-]?token|auth[_-]?token|private[_-]?key|token)["']?\s*[:=]\s*["']([^"'\s]{8,200})["']/gi,
    group:1,prefix:0,validate:v=>!isPlaceholder(v)&&shannonEntropy(v)>=3},
  {id:'credit-card',category:'pii',severity:'high',title:'Número de cartão de pagamento',re:/(?<![\d-])(?:\d[ -]?){12,18}\d(?![\d-])/g,prefix:0,validate:validCard},
  {id:'cpf',category:'pii',severity:'medium',title:'CPF',re:/(?<!\d)\d{3}\.\d{3}\.\d{3}-\d{2}(?!\d)/g,prefix:0,validate:validCpf},
  {id:'email',category:'pii',severity:'low',title:'Endereço de e-mail',optional:'detectEmail',
    re:/(?<![A-Za-z0-9._%+-])[A-Za-z0-9._%+-]{1,64}@[A-Za-z0-9-]{1,63}(?:\.[A-Za-z0-9-]{1,63})*\.[A-Za-z]{2,24}(?![A-Za-z])/g,prefix:0}
]);
export const SEVERITY_RANK=Object.freeze({low:1,medium:2,high:3,critical:4});

export function mask(value,prefix=0) {
  const s=String(value);
  const keep=typeof prefix==='string'?prefix:s.slice(0,Math.min(prefix,Math.max(0,s.length-8)));
  return `${keep}…[${s.length} caracteres ocultos]`;
}

function lineIndex(text) {
  const starts=[0];
  for(let i=0;i<text.length;i++) if(text.charCodeAt(i)===10) starts.push(i+1);
  return offset=>{
    let lo=0,hi=starts.length-1;
    while(lo<hi) {const mid=(lo+hi+1)>>1;if(starts[mid]<=offset) lo=mid;else hi=mid-1;}
    return {line:lo+1,column:offset-starts[lo]+1};
  };
}

/**
 * Raw matches with spans. Internal: the returned objects include the secret value
 * and must not leave the Privacy Guard (use scanText for anything public).
 */
export function findMatches(text,{detectEmail=false,rules=RULES}={}) {
  const content=String(text??'');
  if(!content||content.includes('\u0000')) return [];
  const taken=[];const out=[];
  for(const rule of rules) {
    if(rule.optional==='detectEmail'&&!detectEmail) continue;
    rule.re.lastIndex=0;
    let m;
    while((m=rule.re.exec(content))!==null) {
      if(m[0].length===0) {rule.re.lastIndex++;continue;}
      const value=rule.group?m[rule.group]:m[0];
      if(!value) continue;
      const start=rule.group?m.index+m[0].indexOf(value):m.index;
      const end=start+value.length;
      if(rule.validate&&!rule.validate(value)) continue;
      if(taken.some(([a,b])=>start<b&&end>a)) continue;
      taken.push([start,end]);
      out.push({rule,value,start,end});
      if(out.length>=500) return out;
    }
  }
  return out.sort((a,b)=>a.start-b.start);
}

/** Public scan: findings with position, fingerprint and masked preview only. */
export function scanText(text,{path=null,detectEmail=false}={}) {
  const content=String(text??'');
  const at=lineIndex(content);
  return findMatches(content,{detectEmail}).map(({rule,value,start})=>({
    ruleId:rule.id,category:rule.category,severity:rule.severity,title:rule.title,
    path,...at(start),fingerprint:fingerprint(value),preview:mask(value,rule.prefix)
  }));
}

export function summarize(findings) {
  const bySeverity={critical:0,high:0,medium:0,low:0};const byRule={};
  for(const f of findings) {bySeverity[f.severity]=(bySeverity[f.severity]||0)+1;byRule[f.ruleId]=(byRule[f.ruleId]||0)+1;}
  return {total:findings.length,bySeverity,byRule};
}
