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

## Ativador MATLAB / 16 verificações adicionais

A [execução em `main`](https://github.com/7dsolv/konaet-bot/actions/runs/42880475117), na revisão `6da1e1d7a6c250a548c29cb4f52b416dd8c16075`, passou novamente nos 40 cenários anteriores e em **16 verificações do ativador**. O [relatório adicional](../assets/activation-test-report.json) registra os casos e a origem.

As verificações adicionais usam chaves RSA sintéticas: assinaturas PKCS#1/PKCS#8, claims e adulteração do payload; rejeição de chaves fracas, cifradas ou inválidas; conta/App/instalação incorretas; permissões insuficientes e suspensão. Também exercitam a descoberta apenas de metadados e processos reais com stdin, caminhos literais e ambiente restrito ao filho.

Esses testes não enviam Secrets nem autenticam a App real. `NOT_RUN` continua explícito no relatório adicional. [Procedimento de ativação](ACTIVATION.md).

## Verificação real separada

Em **10/11/2026**, a [execução real `42883494662`](https://github.com/7dsolv/konaet-bot/actions/runs/42883494662) autenticou a App KONAET. O GitHub confirmou `konaet[bot]`, ID `352182232`, e um token de instalação com acesso somente a `7dsolv/konaet-bot`. O [registro público](../assets/live-app.json) está em `VERIFIED`, com `fixture_used=false` e revisão de origem. O workflow também concluiu sua etapa de encerramento do token.

Os relatórios dos testes offline continuam com **NOT_RUN** para a App real, pois usam fixtures e chaves sintéticas. Eles preservam o que cada suíte efetivamente executou. A autenticação real tem seu próprio workflow e sua própria evidência; criar/revisar uma PR e publicar o laboratório são operações verificadas à parte.

O [teste real de proposta](https://github.com/7dsolv/konaet-bot/actions/runs/42884367354) também passou: `konaet[bot]` criou o commit `e6d4e5b` e a [PR #2](https://github.com/7dsolv/konaet-bot/pull/2), alterando somente `state/konaet-status.txt`. A [suíte da PR](https://github.com/7dsolv/konaet-bot/actions/runs/42884414001) passou; a proposta foi revisada pela conta `7dsolv` e incorporada. Esse arquivo é um registro demonstrativo do fluxo Git, não uma medida de inteligência.

A suíte não mede superioridade frente a outros produtos, inteligência geral ou desempenho de um modelo neural. Duração de teste é diagnóstico da execução no runner, não benchmark de latência do serviço GitHub.
