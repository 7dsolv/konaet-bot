# Evidências e limites dos testes

A suíte está em [`tests/run_konaet_tests.m`](../tests/run_konaet_tests.m). Ela extrai os scripts dos próprios arquivos `action.yml`, evitando manter uma segunda implementação do módulo nos testes.

A revisão `25cde3e41502023ea2c5c78730bc153bbdce2f96` completou **40/40 cenários offline**, com zero falhas. O [registro da execução](https://github.com/7dsolv/konaet-bot/actions/runs/41724466003) também contém o teste nativo do composite, a geração da vitrine com a marca KONAET e a verificação das mídias geradas. O campo `revision` do relatório identifica a origem dos números exibidos nas imagens.

| Grupo | O que é exercitado |
| --- | --- |
| Identidade offline | Bot válido; slug diferente ou vazio; ID inválido; login inesperado; conta `User`; erro da API. |
| Git local real | Commit e autoria, push, remoção e criação de arquivos, nomes com espaço, branch base preservada e ausência de alterações. |
| Recusas | Arquivo inesperado, staged inesperado, travessia, glob, pathspec, lista vazia, workflow, origem ou push URL de outro repositório e nomes com quebra de linha. |
| Diff completo | Renomeação dentro e fora da lista; hook que inclui arquivo inesperado; commits remotos fora da lista durante atualização ou recuperação. |
| Concorrência e recuperação | Branch divergente, corrida real durante o push, reaproveitamento de PR, corrida de criação e recuperação depois de falha da API. |
| Texto como dado | Título e corpo com sintaxe de shell permanecem texto. |
| Autoria | Autor e committer definidos pelo módulo, mesmo com variáveis Git externas diferentes. |
| Configuração MATLAB | Formulário oficial, permissões exatas e webhook desativado. |

Os remotos são repositórios Git bare em diretórios temporários. O comando `gh` é um fixture local que registra chamadas e produz respostas controladas. Os testes não usam credenciais nem fazem chamadas ao GitHub. Cada cenário registra resultado e duração no [relatório da vitrine](../assets/test-report.json); a revisão testada fica no campo `revision`.

O CI também executa o módulo composite diretamente no runner, com outro remoto bare local e API de teste, para conferir entradas e saídas da integração do GitHub Actions. Essa checagem é independente da chamada de subprocessos pelo MATLAB. Actionlint/ShellCheck verificam os workflows e o contrato JSON é conferido. O renderer verifica a quantidade e o tamanho uniforme dos quadros do GIF e impõe orçamento de 8 MiB para a animação.

A marca é o cubo roxo original de `7dsolv/konaet-cover`, com origem fixada em revisão e SHA-256. O CI confere esse hash, a identificação **KONAET** no manifesto e a igualdade byte a byte entre o ícone publicado e o arquivo de origem. A capa, o diagrama e a animação usam a mesma imagem; a composição final também foi inspecionada visualmente.

## Verificação real separada

Registro e instalação da App, emissão/revogação de token no GitHub e criação de PR com a identidade oficial não são demonstrados pelo fixture. O relatório os marca como **NOT_RUN**. Depois de configurar a App, execute **Actions → Verificar identidade real da App** e depois o workflow manual de proposta para conferir a integração real.

A suíte não mede superioridade frente a outros produtos, inteligência geral ou desempenho de um modelo neural. Duração de teste é diagnóstico da execução no runner, não benchmark de latência do serviço GitHub.
