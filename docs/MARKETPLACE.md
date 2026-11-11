# Publicação no GitHub Marketplace

O produto a listar é a **Action KONAET**. A GitHub App que fornece sua identidade é um registro separado. O pacote pode ser usado com uma App própria do mantenedor, informando seu `expected-slug`.

## Conteúdo da listagem

| Campo | Conteúdo preparado |
| --- | --- |
| Nome | KONAET |
| Descrição | Verified GitHub App identity and scoped tokens for reviewable repository updates. |
| Categoria principal sugerida | Code review |
| Categoria secundária sugerida | Utilities |
| Versão | v1.3.1 |
| Branding da Action | Ícone `git-pull-request`, cor `purple`, conforme os campos aceitos pelo GitHub. |
| Apresentação | README com o cubo roxo original da KONAET, capa, GIF e diagrama compostos em MATLAB. |
| Ícone para a App | `assets/konaet-app-icon.png`: cópia exata do cubo original, para upload na página da App. |

O repositório é público, contém um único `action.yml` na raiz e usa licença MIT. O módulo em `propose/action.yml` integra o pacote e não gera uma segunda listagem automática.

O nome público é **KONAET**. O caminho `7dsolv/konaet-bot` permanece estável para quem já usa a Action. O campo `branding` aceita os ícones predefinidos do GitHub; o cubo aparece na apresentação e no arquivo de avatar da App.

A [listagem KONAET](https://github.com/marketplace/actions/konaet) e a
[App pública](https://github.com/apps/konaet) foram confirmadas em 11/11/2026.
A release v1.3.1 é imutável; seus assets e tag não são regravados por correções
da documentação. Novas versões exigem testes e nova release.

Uma release pública no repositório não confirma por si só a presença no Marketplace. A listagem só deve ser anunciada como publicada depois de seu endereço no Marketplace estar acessível.

Fonte: [instruções oficiais de publicação de Actions](https://docs.github.com/en/actions/how-tos/create-and-publish-actions/publish-in-github-marketplace).
