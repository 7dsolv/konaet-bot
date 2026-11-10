function jwt = konaet_app_jwt(pem, issuer, now_seconds)
%KONAET_APP_JWT Assina com RSA da JVM; nao implementa criptografia propria.
%   Suporta PEM RSA PKCS#1 e PKCS#8 sem senha. Nunca grava a chave ou JWT.
if nargin < 3, now_seconds = floor(posixtime(datetime('now','TimeZone','UTC'))); end
pem = char(pem); issuer = char(issuer);
assert(~isempty(regexp(issuer, '^[A-Za-z0-9_-]{1,100}$', 'once')), ...
    'Konaet:InvalidIssuer', 'Identificador de App invalido.');
validateattributes(now_seconds, {'numeric'}, {'real','finite','scalar','positive'});
assert(numel(pem) <= 65536 && ~contains(pem,'ENCRYPTED'), ...
    'Konaet:InvalidPrivateKey', 'Use uma chave RSA PEM sem senha do cadastro da App.');
pkcs1 = contains(pem,'-----BEGIN RSA PRIVATE KEY-----');
if pkcs1, label = 'RSA PRIVATE KEY'; else, label = 'PRIVATE KEY'; end
pattern = ['^\s*-----BEGIN ' label '-----\s*([A-Za-z0-9+/=\s]+)' ...
    '\s*-----END ' label '-----\s*$'];
parts = regexp(pem, pattern, 'tokens', 'once');
assert(~isempty(parts), 'Konaet:InvalidPrivateKey', 'Arquivo nao e uma chave RSA privada PEM suportada.');
try
    decoder = java.util.Base64.getMimeDecoder();
    der = typecast(int8(decoder.decode(char(parts{1}))), 'uint8');
    der = reshape(der,1,[]);
    if pkcs1
        % Envelope PrivateKeyInfo (RFC 5208) para a chave PKCS#1 existente.
        algorithm = uint8([48 13 6 9 42 134 72 134 247 13 1 1 1 5 0]);
        octets = [uint8(4) der_length(numel(der)) der];
        body = [uint8([2 1 0]) algorithm octets];
        der = [uint8(48) der_length(numel(body)) body];
    end
    factory = java.security.KeyFactory.getInstance('RSA');
    spec = java.security.spec.PKCS8EncodedKeySpec(typecast(der,'int8'));
    key = factory.generatePrivate(spec);
catch
    error('Konaet:InvalidPrivateKey', 'A JVM recusou o formato da chave RSA.');
end
assert(key.getModulus().bitLength() >= 2048, ...
    'Konaet:WeakPrivateKey', 'RSA precisa ter pelo menos 2048 bits.');
header = jsonencode(struct('alg','RS256','typ','JWT'));
claims = jsonencode(struct('iat',floor(now_seconds)-60, ...
    'exp',floor(now_seconds)+540,'iss',issuer));
unsigned = [base64url(unicode2native(header,'UTF-8')) '.' ...
    base64url(unicode2native(claims,'UTF-8'))];
signature = java.security.Signature.getInstance('SHA256withRSA');
signature.initSign(key);
signature.update(typecast(unicode2native(unsigned,'UTF-8'),'int8'));
jwt = [unsigned '.' base64url(typecast(int8(signature.sign()),'uint8'))];
end

function result = base64url(bytes)
encoder = java.util.Base64.getUrlEncoder(); encoder = encoder.withoutPadding();
result = char(encoder.encodeToString(typecast(uint8(bytes),'int8')));
end

function encoded = der_length(n)
if n < 128, encoded = uint8(n); return; end
bytes = uint8([]);
while n > 0, bytes = [uint8(mod(n,256)) bytes]; n = floor(n/256); end %#ok<AGROW>
encoded = [uint8(128+numel(bytes)) bytes];
end
