# Evidências e limites dos testes

A suíte está em [`tests/run_konaet_tests.m`](../tests/run_konaet_tests.m). Ela extrai os scripts dos próprios arquivos `action.yml`, evitando manter uma segunda implementação do módulo nos testes.

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

O CI também executa actionlint/ShellCheck e verifica a configuração JSON. O renderer verifica a quantidade e o tamanho uniforme dos quadros do GIF e impõe orçamento de 8 MiB para a animação.

## Verificação real separada

Registro e instalação da App, emissão/revogação de token no GitHub e criação de PR com a identidade oficial não são demonstrados pelo fixture. O relatório os marca como **NOT_RUN**. Depois de configurar a App, execute **Actions → Verificar identidade real da App** e depois o workflow manual de proposta para conferir a integração real.

A suíte não mede superioridade frente a outros produtos, inteligência geral ou desempenho de um modelo neural. Duração de teste é diagnóstico da execução no runner, não benchmark de latência do serviço GitHub.
