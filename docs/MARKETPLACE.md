# Publicação no GitHub Marketplace

O produto a listar é a **Action Konaet Bot**. A GitHub App que fornece sua identidade é um registro separado. O pacote pode ser usado com uma App própria do mantenedor, informando seu `expected-slug`.

## Conteúdo da listagem

| Campo | Conteúdo preparado |
| --- | --- |
| Nome | Konaet Bot |
| Descrição | Verified GitHub App identity and scoped tokens for reviewable repository updates. |
| Categoria principal sugerida | Code review |
| Categoria secundária sugerida | Utilities |
| Versão | v1.1.0 |
| Branding da Action | Ícone `git-pull-request`, cor `purple`, conforme os campos aceitos pelo GitHub. |
| Apresentação | README com capa, GIF e diagrama originais gerados em MATLAB. |
| Ícone para a App | `assets/konaet-app-icon.png`, para upload na página da App. |

O repositório é público, contém um único `action.yml` na raiz e usa licença MIT. O módulo em `propose/action.yml` integra o pacote e não gera uma segunda listagem automática.

Na tela de release, a conta proprietária precisa aceitar o **GitHub Marketplace Developer Agreement**, marcar **Publish this Action to the GitHub Marketplace**, selecionar as categorias e publicar/atualizar a release. O GitHub também exige autenticação de dois fatores. A captura fornecida pelo proprietário mostra que o contrato ainda bloqueava a caixa de publicação.

Uma release pública no repositório não confirma por si só a presença no Marketplace. A listagem só deve ser anunciada como publicada depois de seu endereço no Marketplace estar acessível.

Fonte: [instruções oficiais de publicação de Actions](https://docs.github.com/en/actions/how-tos/create-and-publish-actions/publish-in-github-marketplace).
