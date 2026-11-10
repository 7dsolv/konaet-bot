# Ativação da App KONAET

`ativar_konaet` automatiza a configuração na conta **7dsolv**. A chave privada original precisa existir; o GitHub guarda somente a parte pública e não permite recuperar a privada. [Gerenciamento oficial de chaves](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/managing-private-keys-for-github-apps).

Na raiz deste pacote, no MATLAB:

```matlab
status = ativar_konaet(CheckOnly=true);
status = ativar_konaet;
```

O primeiro comando apenas verifica arquivos e ferramentas, sem ler a chave nem acessar a rede. O segundo procura arquivos `konaet*.pem` diretamente em Downloads, tenta os cinco mais recentes e só avança após autenticar a chave. Também é possível informar `PrivateKeyPath` e `GhExecutable` explicitamente. Nenhum conteúdo de chave aparece no relatório.

## Antes da configuração

1. A chave precisa ter sido gerada no [cadastro KONAET](https://github.com/settings/apps/konaet), em **Credentials / Key pairs** ou **Private keys**, conforme a interface da conta.
2. A App deve estar instalada em `7dsolv/konaet-bot` e `7dsolv/RealidadeQuantica`, com escrita em conteúdo e pull requests.
3. É necessário o GitHub CLI oficial e o login Git da conta `7dsolv`. Nesta estação, o CLI portátil foi preparado em `%LOCALAPPDATA%\Konaet\tools\gh_2.103.3\bin\gh.exe`, com o SHA-256 conferido contra a release oficial. Em outra máquina, use a [distribuição oficial](https://cli.github.com/).

O programa confirma o cadastro de ID `5602778`, slug `konaet`, dono `7dsolv`, Client ID e instalação nos dois repositórios. Uma chave de outro aplicativo ou uma instalação insuficiente interrompe a operação **antes de enviar Secrets**.

## O que é configurado

A JVM assina um JWT RS256 usando a chave RSA PKCS#1 ou PKCS#8, com no mínimo 2048 bits. O JWT segue os [campos exigidos pelo GitHub](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-json-web-token-jwt-for-a-github-app). Depois, o programa verifica a conta autenticada pelo Git Credential Manager ou por `GH_TOKEN`.

A chave entra no GitHub CLI por **stdin**, sem shell e sem aparecer nos argumentos de processo. O [`gh secret set`](https://cli.github.com/manual/gh_secret_set) cifra o valor localmente antes de enviá-lo. O token do dono fica só no ambiente do processo filho. A função não altera o ambiente do MATLAB, grava chaves no repositório ou retorna tokens.

Os dois Secrets `KONAET_APP_PRIVATE_KEY` são enviados primeiro. Só então são definidas as variáveis `KONAET_APP_CLIENT_ID` que habilitam a App nos workflows. Falhas posteriores não têm rollback automático: consulte a configuração se alguma etapa for interrompida.

Por fim, a função solicita os workflows de identidade real e do agente integrado. `VERIFICATION_REQUESTED` significa que as execuções foram solicitadas, não que já passaram. O workflow de identidade só produz `VERIFIED` depois de autenticar a App e conferir que o token acessa somente o repositório esperado. O artifact `konaet-live-app-proof` contém essa evidência sem credenciais.

## Evidência dos testes

A suíte `run_activation_tests` usa chaves RSA geradas localmente e processos de teste. Ela verifica assinaturas, adulteração do payload, formatos de chave, políticas de instalação, leitura apenas de metadados e passagem de stdin/ambiente sem shell. Esses testes **não autenticam uma App real**. A evidência real vem exclusivamente do workflow `verificar-identidade.yml` executado com credenciais válidas.
