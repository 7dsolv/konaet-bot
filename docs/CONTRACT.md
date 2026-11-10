# Contrato de automação

O pacote suporta runners Linux com Bash, Git e GitHub CLI no GitHub.com. A origem Git deve ser HTTPS e corresponder a `github.repository`. O mantenedor define o gerador e os arquivos que ele pode propor.

A origem efetiva de leitura e escrita é conferida novamente antes das operações
de rede. Reescritas de URL e múltiplos destinos não são aceitos. Uma PR somente
é usada depois de conferir repositório de origem, branches e SHA exato do commit;
forks com nome de branch igual são ignorados. A identidade é relida após criar a PR.

## Identidade — raiz do pacote

`client-id` e `private-key` são obrigatórios. `expected-slug` tem padrão `konaet`; outra App precisa do seu próprio slug. A Action compara slug e consulta ID, login e tipo `Bot` pela API. As saídas são `token`, `installation-id`, `app-slug`, `bot-login`, `bot-id` e `bot-email`.

O token tem acesso de escrita a conteúdo e pull requests apenas no repositório atual. Sua criação e revogação são feitas por `actions/create-github-app-token`, fixada por SHA no código. As credenciais devem vir dos Secrets do mantenedor.

## Proposta — módulo `propose`

| Entrada | Regra |
| --- | --- |
| `token`, `bot-login`, `bot-id` | Receba das saídas da Action de identidade. |
| `paths` | Um arquivo ou diretório por linha; relativo à raiz, literal, sem glob, `..` ou pathspec Git. Espaços são aceitos. |
| `branch` | Padrão `konaet/updates`; deve diferir da branch base e da branch padrão. |
| `base` | Padrão `main`; informe a branch padrão do seu projeto se for diferente. |
| `title`, `body`, `commit-message` | Texto passado como dados, sem avaliação como comando. |

As saídas são `changed`, `commit`, `pr-url` e `pr-number`. `changed=true` significa que a execução criou um commit. Uma recuperação de PR pode retornar `changed=false` com uma URL válida.

O módulo examina todo o diff contra `HEAD`, incluindo alterações staged e arquivos não rastreados que não estejam no `.gitignore`. Renomeações são tratadas como remoção e criação, para conferir os dois caminhos. Depois do commit, confere também o diff da proposta contra sua merge base, incluindo alterações introduzidas por hooks ou commits anteriores da branch. Qualquer caminho inesperado interrompe a operação antes de enviar novas mudanças. Arquivos em `.github/workflows/` são recusados porque o pacote não solicita permissão de escrita em workflows. Nomes de arquivo com quebra de linha não são suportados.

## Branch persistente e concorrência

Para atualizar a mesma proposta, faça checkout do último commit da branch remota **antes** de gerar os arquivos. Use `fetch-depth: 0` para disponibilizar a merge base. Se a branch já existe e não é ancestral do `HEAD` atual, a operação falha. O push é normal, sem `--force`; uma corrida posterior também deve ser recusada pelo Git. Os testes exercitam as duas situações com um remoto bare real.

Se a branch remota já contém alterações e a API falhou depois de um push, uma nova execução sem alterações locais pode criar ou recuperar a PR sem outro commit. A branch precisa continuar diferente da base. Uma corrida de criação de PR é resolvida consultando novamente a PR aberta.

Falhas depois do push são reportadas como falha, com o SHA enviado quando disponível. O módulo não promete uma transação atômica entre Git e a API. Ele não faz merge, apaga branches, resolve conflitos nem ignora proteções do repositório.

Use geradores e workflows confiáveis para as credenciais instaladas. O módulo controla os caminhos enviados; ele não examina a semântica de todo conteúdo nem substitui um scanner de segredos.
