# KONAET Guard e KONAET Impact

Dois módulos novos do konaet-bot. Nenhum deles faz merge, altera `.github/workflows` ou envia valores secretos para fora do workflow.

| Módulo | Onde roda | Precisa de chave? | O que faz |
|---|---|---|---|
| `guard` | no seu workflow | não | Procura tokens, chaves privadas e dados pessoais introduzidos pela mudança. Falha o job conforme a severidade. |
| `impact` | API KONAET | sim (`knt_live_…`) | Relatório causal da PR: o que mudou, quais arquivos e contratos são afetados, quais testes rodar. Comenta na PR e falha só por política verificável. |
| `api` | API KONAET | sim | Abre PRs com a identidade do bot. Operações críticas esperam aprovação humana no painel. |

## Guard — grátis, sem servidor

```yaml
name: KONAET Guard
on: [pull_request, push]
permissions:
  contents: read
jobs:
  guard:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: 7dsolv/konaet-bot/guard@<sha-da-release>
        with:
          fail-on: high        # critical | high | medium | low | never
          # mode: all          # varre o repositório inteiro
```

- Em PRs e pushes, só reporta segredos **introduzidos** pela mudança (compara a impressão SHA-256 com a versão anterior do arquivo).
- As anotações mostram só uma prévia mascarada (`ghp_…[40 caracteres ocultos]`) e a impressão; o valor nunca aparece no log.
- Detecta: tokens do GitHub (clássico, fine-grained, App), chaves KONAET, AWS, Google, Slack, Stripe, npm, Hugging Face, OpenAI, Anthropic, JWT, chaves privadas PEM/OpenSSH/PGP, senha em URL, segredos atribuídos em configuração, cartão (Luhn) e CPF (dígitos verificadores).

Achou um segredo? **Revogue primeiro**, depois remova do código. Apagar o arquivo não apaga o histórico Git.

## Impact — relatório verificável da PR

```yaml
name: KONAET Impact
on: pull_request
permissions:
  contents: read
jobs:
  impact:
    runs-on: ubuntu-latest
    steps:
      - uses: 7dsolv/konaet-bot/impact@<sha-da-release>
        with:
          api-key: ${{ secrets.KONAET_API_KEY }}
          api-url: ${{ vars.KONAET_API_URL }}
```

Com a App KONAET instalada, o mesmo relatório já é publicado automaticamente em toda PR (comentário + check `KONAET Causal Engine`), sem workflow nenhum. O módulo serve para quem quer a decisão como etapa do próprio CI.

O relatório é assinado com Ed25519. Para conferir: `POST <api-url>/attestations/verify` com o envelope, ou baixe a chave pública em `<api-url>/attestation-key`.

### Políticas

Regras que podem bloquear: `breaking-contract`, `secret-in-change`, `broken-import`, `sensitive-change-without-tests`. Regras de aviso: `workflow-change`, `blast-radius`, `untested-change`, `dependency-change`, `schema-migration`.

Versione a política no repositório em `.konaet/policy.json`:

```json
{
  "blockOn": ["breaking-contract", "secret-in-change", "broken-import"],
  "maxBlastRadius": 40,
  "sensitivePatterns": ["auth", "payment", "billing", "crypto"],
  "ignorePaths": ["docs/", "examples/"]
}
```

### Limites honestos

- Grafo estático de JavaScript/TypeScript, Python e C/C++: imports montados em tempo de execução não são seguidos.
- A KONAET não executa o código do seu repositório. Ela escolhe os testes afetados e acompanha o resultado do seu CI.
- O risco é uma soma de fatores determinísticos; cada ponto aponta a evidência. Nenhuma IA decide o bloqueio.
