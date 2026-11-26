const PLACEHOLDER_RE=/^(?:\$\{\{?|\$\(|\$[A-Z_]+$|%[A-Z_]+%$|process\.env|os\.environ|getenv|env\.|secrets\.|vars\.|<[^>]*>|\{\{|\[[^\]]*\]$|x{4,}|\*{3,}|\.{3,}|change[-_ ]?me|example|exemplo|placeholder|your[-_ ]|seu[-_ ]|sua[-_ ]|dummy|sample|redacted|fake|todo|null|none|undefined|true|false|password|senha|secret|token)/i;
const isPlaceholder=v=>PLACEHOLDER_RE.test(v)||/^(.)\1+$/.test(v)||/^[a-z]+(?:[_-][a-z]+)*$/.test(v);

const rules=Object.freeze([
  {re:/-----BEGIN (?:[A-Z0-9]+ )*PRIVATE KEY(?: BLOCK)?-----[\s\S]{0,6000}?(?:-----END (?:[A-Z0-9]+ )*PRIVATE KEY(?: BLOCK)?-----|$)/g},
  {re:/(?<![A-Za-z0-9_])ghs_[A-Za-z0-9_.-]{36,2048}(?![A-Za-z0-9_.-])/g},
  {re:/(?<![A-Za-z0-9_])gh[pour]_[A-Za-z0-9_]{36,1024}(?![A-Za-z0-9_])/g},
  {re:/(?<![A-Za-z0-9_])github_pat_[A-Za-z0-9_]{60,1024}(?![A-Za-z0-9_])/g},
  {re:/(?<![A-Za-z0-9_])knt_(?:live|demo)_[a-f0-9]{12}_[A-Za-z0-9_-]{43}(?![A-Za-z0-9_-])/g},
  {re:/(?<![A-Za-z0-9_-])sk-ant-[A-Za-z0-9_-]{32,250}(?![A-Za-z0-9_-])/g},
  {re:/(?<![A-Za-z0-9_-])sk-(?:proj-|svcacct-|admin-)?[A-Za-z0-9_-]{32,250}(?![A-Za-z0-9_-])/g},
  {re:/(?<![A-Za-z0-9_])hf_[A-Za-z0-9]{30,64}(?![A-Za-z0-9_])/g},
  {re:/(?<![A-Z0-9])(?:AKIA|ASIA|ABIA|ACCA)[0-9A-Z]{16}(?![A-Z0-9])/g},
  {re:/aws_?secret_?access_?key["'\s]*[:=]\s*["']?([A-Za-z0-9/+=]{40})(?![A-Za-z0-9/+=])/gi,group:1},
  {re:/(?<![A-Za-z0-9_-])AIza[0-9A-Za-z_-]{35}(?![0-9A-Za-z_-])/g},
  {re:/(?<![A-Za-z0-9])xox[abposr]-[A-Za-z0-9-]{10,250}/g},
  {re:/https:\/\/hooks\.slack\.com\/services\/[A-Za-z0-9/_-]{20,200}/g},
  {re:/(?<![A-Za-z0-9_])(?:sk|rk)_live_[A-Za-z0-9]{20,250}(?![A-Za-z0-9_])/g},
  {re:/(?<![A-Za-z0-9_-])(?:APP_USR|TEST)-\d{6,20}-\d{6}-[0-9a-f]{32}-\d{5,12}(?![A-Za-z0-9_-])/g},
  {re:/(?<![A-Za-z0-9_])npm_[A-Za-z0-9]{36}(?![A-Za-z0-9_])/g},
  {re:/(?<![A-Za-z0-9_-])eyJ[A-Za-z0-9_-]{8,}\.eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}/g},
  {re:/\b[a-z][a-z0-9+.-]{1,20}:\/\/[^\s:/@"'<>]{1,100}:([^\s:/@"'<>]{3,200})@[^\s/"'<>]+/gi,group:1,validate:v=>!isPlaceholder(v)},
]);

// Patterns adapted from the KONAET Privacy Guard. Only a verdict leaves the scanner.
export function containsCredential(content) {
  for (const {re, group, validate} of rules) {
    re.lastIndex = 0;
    for (let match; (match = re.exec(content)); ) {
      if (!validate || validate(match[group])) return true;
    }
  }
  return false;
}
