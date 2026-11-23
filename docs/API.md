# KONAET API: Pull Requests sem chave de App no seu repositório

A Action principal (`7dsolv/konaet-bot`) usa a **sua** GitHub App. O módulo `api` faz o caminho inverso: o seu workflow só envia os arquivos, e a API KONAET abre a Pull Request com a identidade `konaet[bot]`.

| | Action principal + `propose` | Módulo `api` |
| --- | --- | --- |
| Credencial no seu repositório | Client ID e chave privada da sua App | Uma chave `knt_live_…` |
| Identidade da PR | A sua App | `konaet[bot]` |
| Onde roda o Git | No runner | No servidor KONAET |
| Plano | Grátis, sem limite da KONAET | Free, Pro, Team ou Business |

## Como usar

1. Instale a [App KONAET](https://github.com/apps/konaet) na conta e nos repositórios que receberão as propostas.
2. Entre no painel KONAET, abra **Chaves de API** e crie uma chave. Você pode limitar a chave a repositórios e a caminhos (`relatorios/`, por exemplo).
3. Guarde a chave no segredo `KONAET_API_KEY` e o endereço na variável `KONAET_API_URL` (`https://<domínio>/v1`).

```yaml
name: Propor resultados pela API
on: [workflow_dispatch]
permissions:
  contents: read

jobs:
  propor:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7
        with:
          persist-credentials: false
      - name: Gerar arquivo
        run: |
          mkdir -p relatorios
          date -u '+Execucao em %Y-%m-%dT%H:%M:%SZ' > relatorios/estado.txt
      - uses: 7dsolv/konaet-bot/api@<SHA_DO_COMMIT> # fixe pelo SHA da release
        id: konaet
        with:
          api-key: ${{ secrets.KONAET_API_KEY }}
          api-url: ${{ vars.KONAET_API_URL }}
          paths: relatorios/estado.txt
          title: 'KONAET: revisar resultado gerado'
      - run: echo "PR: ${{ steps.konaet.outputs.pr-url }}"
```

O workflow não precisa de `contents: write`: quem escreve é a App, no servidor.

## O que o módulo garante

- Envia só os arquivos listados em `paths` (arquivos ou pastas, um por linha, sem glob). Links simbólicos, `..` e caminhos absolutos são recusados.
- A API recusa `.git/` e `.github/workflows/`, repositórios de outra conta e caminhos fora da lista da chave.
- Cada envio leva uma `Idempotency-Key` única por execução. Se a rede cair e o `curl` repetir, a API devolve a mesma proposta em vez de abrir outra.
- A PR sai numa branch nova `konaet/api/<id>`, sem push forçado. O merge é sempre do mantenedor.

## Saídas

`proposal-id`, `pr-url` (vazio quando nada mudou), `state` (`completed`, `failed`, `unknown`) e `changed`.

Um status `unknown` faz o passo falhar: confira se a branch `konaet/api/*` foi criada antes de repetir com outra chave de idempotência.

## Limites por plano

| Plano | Chaves | Requisições/min | Arquivos por proposta | Tamanho por proposta | Operações/mês |
| --- | ---: | ---: | ---: | ---: | ---: |
| Free | 1 | 10 | 10 | 256 KiB | 20 |
| Pro | 3 | 60 | 50 | 1 MiB | 500 |
| Team | 10 | 120 | 100 | 2 MiB | 3.000 |
| Business | 25 | 300 | 200 | 4 MiB | 15.000 |

A especificação completa fica em `<api-url>/openapi.json`.
