function [status, output] = konaet_process(command, stdin_text, environment, timeout_seconds)
%KONAET_PROCESS Processo sem shell: dados sensiveis entram somente por stdin.
if nargin < 2, stdin_text = ''; end
if nargin < 3, environment = struct(); end
if nargin < 4, timeout_seconds = 45; end
assert(iscell(command) && ~isempty(command), 'Konaet:InvalidCommand','Comando invalido.');
list = java.util.ArrayList();
for k = 1:numel(command), list.add(java.lang.String(char(command{k}))); end
builder = java.lang.ProcessBuilder(list); builder.redirectErrorStream(true);
env = builder.environment(); names = fieldnames(environment);
for k = 1:numel(names), env.put(names{k},char(environment.(names{k}))); end
try
    process = builder.start();
catch
    error('Konaet:ExecutableUnavailable','Nao foi possivel iniciar a ferramenta solicitada.');
end
guard = onCleanup(@() process.destroy()); %#ok<NASGU>
stream = process.getOutputStream();
bytes = unicode2native(char(stdin_text),'UTF-8');
if ~isempty(bytes), stream.write(typecast(bytes,'int8')); end
stream.close();
unit = java.util.concurrent.TimeUnit.SECONDS;
if ~process.waitFor(int64(timeout_seconds),unit)
    process.destroyForcibly();
    error('Konaet:ProcessTimeout','A ferramenta excedeu o tempo de espera.');
end
bytes = process.getInputStream().readAllBytes();
output = native2unicode(typecast(int8(bytes),'uint8'),'UTF-8');
output = char(reshape(output,1,[])); status = double(process.exitValue());
end
