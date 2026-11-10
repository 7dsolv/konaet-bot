function [status, output] = konaet_process(command, stdin_text, environment, timeout_seconds)
%KONAET_PROCESS Processo sem shell com I/O privado e prazo para toda execucao.
if nargin < 2, stdin_text = ''; end
if nargin < 3, environment = struct(); end
if nargin < 4, timeout_seconds = 45; end
assert(iscell(command) && ~isempty(command), 'Konaet:InvalidCommand','Comando invalido.');
validateattributes(timeout_seconds,{'numeric'},{'scalar','real','finite','positive'});
bytes=unicode2native(char(stdin_text),'UTF-8');
assert(numel(bytes)<=65536,'Konaet:ProcessInputLimit','Entrada excede o limite de 64 KiB.');
% Redirected files avoid pipe deadlocks, including a child that never reads
% stdin. Restrict the directory BEFORE any sensitive bytes are written.
folder=tempname;mkdir(folder);process=[];
input_file=fullfile(folder,'stdin');output_file=fullfile(folder,'output');
guard=onCleanup(@finish); %#ok<NASGU>
private_directory(folder);
fid=fopen(input_file,'wb');assert(fid>=0);fwrite(fid,bytes,'uint8');fclose(fid);
list = java.util.ArrayList();
for k = 1:numel(command), list.add(java.lang.String(char(command{k}))); end
builder = java.lang.ProcessBuilder(list); builder.redirectErrorStream(true);
builder.redirectInput(java.io.File(input_file));
builder.redirectOutput(java.io.File(output_file));
env = builder.environment(); names = fieldnames(environment);
for k = 1:numel(names), env.put(names{k},char(environment.(names{k}))); end
try
    process = builder.start();
catch
    error('Konaet:ExecutableUnavailable','Nao foi possivel iniciar a ferramenta solicitada.');
end
unit = java.util.concurrent.TimeUnit.MILLISECONDS; started=tic;
while ~process.waitFor(int64(100),unit)
    if toc(started)>=timeout_seconds
        error('Konaet:ProcessTimeout','A ferramenta excedeu o tempo de espera.');
    end
    info=dir(output_file);
    if ~isempty(info) && info.bytes>2*1024^2
        error('Konaet:ProcessOutputLimit','Saida da ferramenta excedeu 2 MiB.');
    end
end
info=dir(output_file);
assert(info.bytes<=2*1024^2,'Konaet:ProcessOutputLimit','Saida da ferramenta excedeu 2 MiB.');
fid=fopen(output_file,'rb');assert(fid>=0);bytes=fread(fid,inf,'*uint8');fclose(fid);
output = native2unicode(bytes.','UTF-8');
output = char(reshape(output,1,[])); status = double(process.exitValue());
    function finish()
        if ~isempty(process),stop_process(process);end
        cleanup_files(folder,input_file,output_file);
    end
end

function private_directory(folder)
path=java.io.File(folder).toPath();
if ispc
    kind=java.lang.Class.forName('java.nio.file.attribute.AclFileAttributeView');
    view=java.nio.file.Files.getFileAttributeView(path,kind,javaArray('java.nio.file.LinkOption',0));
    lookup=path.getFileSystem().getUserPrincipalLookupService();
    owner=lookup.lookupPrincipalByName(java.lang.System.getProperty('user.name'));
    permissions=java.util.EnumSet.allOf(java.lang.Class.forName('java.nio.file.attribute.AclEntryPermission'));
    entry=java.nio.file.attribute.AclEntry.newBuilder().setType(java.nio.file.attribute.AclEntryType.ALLOW) ...
        .setPrincipal(owner).setPermissions(permissions).build();
    view.setAcl(java.util.Collections.singletonList(entry));
else
    permissions=java.nio.file.attribute.PosixFilePermissions.fromString('rwx------');
    java.nio.file.Files.setPosixFilePermissions(path,permissions);
end
end

function stop_process(process)
if process.isAlive()
    process.destroyForcibly();process.waitFor(int64(2000),java.util.concurrent.TimeUnit.MILLISECONDS);
end
end

function cleanup_files(folder,input_file,output_file)
if isfile(input_file),delete(input_file);end
if isfile(output_file),delete(output_file);end
if isfolder(folder),rmdir(folder);end
end
