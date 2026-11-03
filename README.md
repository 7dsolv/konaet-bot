# Konaet Bot

Uma identidade de GitHub App para commits e propostas da Konaet, com uma Action reutilizável por outros projetos.

![Verificação do pacote](https://github.com/7dsolv/konaet-bot/actions/workflows/verificar.yml/badge.svg)

**Estado:** pacote de configuração e automação. A identidade `konaet[bot]` só fica ativa depois que a App **Konaet** é registrada, instalada e autenticada. O CI do pacote valida os arquivos; o workflow manual **Verificar identidade real da App** valida a autenticação depois da instalação.

## Ativar a Konaet na conta 7dsolv

1. Abra o [cadastro oficial já preenchido](https://github.com/settings/apps/new?name=Konaet&description=Automacao%20Konaet%20com%20identidade%20propria%2C%20commits%20e%20propostas%20para%20revisao%20humana.&url=https%3A%2F%2Fgithub.com%2F7dsolv%2Fkonaet-bot&public=true&webhook_active=false&contents=write&pull_requests=write) na sessão `7dsolv` e conclua **Create GitHub App**. O GitHub decide a disponibilidade do nome no envio do formulário.
2. Na página da App, gere a chave privada e use **Install App** para selecionar `RealidadeQuantica` e `konaet-bot`.
3. Em cada repositório que vai executar a automação, configure a variável Actions `KONAET_APP_CLIENT_ID` e o segredo Actions `KONAET_APP_PRIVATE_KEY`. Guarde o conteúdo da chave somente no segredo.
4. Execute **Actions → Verificar identidade real da App → Run workflow** neste repositório. Ele confere o login real pela API e não altera arquivos.

Também é possível abrir o mesmo cadastro pelo MATLAB:

```matlab
abrir_cadastro_konaet
```

O arquivo [`github-app.json`](github-app.json) registra a configuração na raiz. O helper MATLAB usa os parâmetros oficiais do formulário: App pública, webhook desligado, acesso de escrita a conteúdo e pull requests. O pacote não hospeda um servidor de webhooks.

## Commit, push e proposta para aprovação

Neste repositório, o workflow **Konaet - commit e proposta para revisao** já está disponível na aba Actions. Depois de configurar a App, execute-o manualmente. Ele cria uma branch, grava um estado de execução, faz commit como o bot autenticado e abre uma pull request para revisão. O merge é decisão do mantenedor.

Para usar em outro projeto, copie [`.github/workflows/propor.yml`](.github/workflows/propor.yml) para a pasta de workflows do destino e configure as credenciais da App daquele mantenedor.

Para integrar a Action a um workflow próprio:

```yaml
- uses: 7dsolv/konaet-bot@v1.0.0
  id: konaet
  with:
    client-id: ${{ vars.KONAET_APP_CLIENT_ID }}
    private-key: ${{ secrets.KONAET_APP_PRIVATE_KEY }}

- uses: actions/checkout@v7
  with:
    token: ${{ steps.konaet.outputs.token }}

- name: Configurar autoria real
  env:
    BOT_LOGIN: ${{ steps.konaet.outputs.bot-login }}
    BOT_EMAIL: ${{ steps.konaet.outputs.bot-email }}
  run: |
    git config user.name "$BOT_LOGIN"
    git config user.email "$BOT_EMAIL"
```

O token fica limitado ao repositório atual e é revogado ao fim do job. A Action consulta o ID real do bot e recusa uma App cujo slug difira de `expected-slug` (padrão: `konaet`). Use um runner Linux com Bash e GitHub CLI, como `ubuntu-latest`.

## Reutilização por outras pessoas

O código é público e tem licença MIT. Outro mantenedor pode criar sua própria App pelo mesmo cadastro, escolher um nome disponível e informar esse slug em `expected-slug`. Cada mantenedor guarda sua própria chave. A chave da App oficial Konaet não é distribuída a terceiros.

Marcar a App como pública permite que outros usuários a instalem; isso não fornece a eles a chave da App nem inicia um serviço de automação hospedado. Este pacote fornece a Action para workflows configurados pelo mantenedor.

## Identidade e histórico

`github-actions[bot]` é a conta da plataforma. O workflow usa a infraestrutura GitHub Actions, e a GitHub App determina a identidade dos commits feitos com seu token. Alterar `git user.name` sozinho não cria uma conta bot. Contribuições antigas do bot da plataforma continuam no histórico e podem continuar na lista de contribuidores.

O pacote cuida da autenticação, autoria e envio de propostas; os cálculos científicos continuam no [RealidadeQuantica](https://github.com/7dsolv/RealidadeQuantica) e a pesquisa de modelos no [Konaet-IA](https://github.com/7dsolv/Konaet-IA). Não há transferência de um modelo de IA a partir do bot da plataforma.

Configuração em YAML/JSON e helper em MATLAB, sem fontes HTML, JavaScript ou Python neste repositório. As Actions oficiais utilizadas são dependências de infraestrutura.

Fontes: [cadastro por parâmetros](https://docs.github.com/en/apps/sharing-github-apps/registering-a-github-app-using-url-parameters), [tokens de GitHub App](https://github.com/actions/create-github-app-token), [configuração de Apps](https://docs.github.com/en/apps/creating-github-apps/registering-a-github-app).
