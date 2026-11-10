![KONAET: identidade verificável e mudanças revisáveis](assets/konaet-cover.png)

# KONAET

**Hardened repository automation.** Validate a scoped App identity, publish an
allowed diff and verify the exact repository/branch/commit of its pull request.
See [maintenance and support](docs/MAINTENANCE.md), [usage contract](docs/CONTRACT.md)
and [private vulnerability reporting](SECURITY.md).

**[Página da App KONAET](https://github.com/apps/konaet)** · **[Laboratório XENOELEMENT X-01](https://github.com/7dsolv/RealidadeQuantica/tree/main/xeno)**

**[Sistema offline KONAET: componentes em código, circuito e IA local](https://github.com/7dsolv/RealidadeQuantica/tree/main/offline)** · **[Explorar a placa em 3D](https://github.com/7dsolv/RealidadeQuantica/blob/main/hardware/x01-carrier/x01-carrier.stl)**

**[KONAET integrada X02: pesos próprios, pesquisa com memória e FPGA](https://github.com/7dsolv/RealidadeQuantica/tree/main/integrated)** · **[Nova placa com ADC em 3D](https://github.com/7dsolv/RealidadeQuantica/blob/main/hardware/x02-acquisition/x02-acquisition.stl)**

**Da App ao diff. Do diff à revisão.**

Verified GitHub App identity and reviewable updates, with explicit repository scope.

[![Verificar pacote Konaet](https://github.com/7dsolv/konaet-bot/actions/workflows/verificar.yml/badge.svg)](https://github.com/7dsolv/konaet-bot/actions/workflows/verificar.yml)
[![Licença MIT](https://img.shields.io/badge/license-MIT-c5ef65)](LICENSE)
[![Identidade real da App](https://github.com/7dsolv/konaet-bot/actions/workflows/verificar-identidade.yml/badge.svg?branch=main)](https://github.com/7dsolv/konaet-bot/actions/workflows/verificar-identidade.yml)
[![Release pública](https://img.shields.io/github/v/release/7dsolv/konaet-bot?label=release&color=8b5cf6)](https://github.com/7dsolv/konaet-bot/releases/latest)

[Ativação das credenciais em MATLAB](docs/ACTIVATION.md) · [Evidências do agente e significado dos selos](https://github.com/7dsolv/RealidadeQuantica/blob/main/integrated/VERIFICATION.md)

**Identidade real verificada em 10/11/2026:** a [execução autenticada](https://github.com/7dsolv/konaet-bot/actions/runs/42883494662) confirmou `konaet[bot]` com token da App limitado a este repositório. [Evidência JSON](assets/live-app.json). Os testes offline permanecem separados dessa autenticação.

Para verificar a preparação local, execute `ativar_konaet(CheckOnly=true)` no MATLAB. Depois de gerar a chave privada no cadastro oficial da App, `ativar_konaet` valida a conta e as instalações, configura os dois repositórios e solicita as verificações reais. A [suíte de ativação](assets/activation-test-report.json) usa chaves sintéticas e mantém a autenticação real como uma checagem separada.

Uma Action para autenticar sua GitHub App e um módulo para transformar arquivos gerados pelo projeto em propostas revisáveis. A Konaet confere a identidade do bot, restringe o diff aos caminhos permitidos e entrega uma pull request ao mantenedor.

O [laboratório integrado](https://github.com/7dsolv/RealidadeQuantica/tree/main/integrated) é um módulo separado: treina o detector KONAET Sense do zero, atualiza uma política de pesquisa persistente e publica comparações, circuito, esquema/PCB e inferência SystemVerilog. Este pacote de identidade não é o modelo neural. Os resultados incluem cenários desfavoráveis e distinguem estimativas das ferramentas de medições físicas. A App oficial já foi autenticada neste repositório; cada consumidor configura sua própria instalação, conforme o [contrato](docs/CONTRACT.md).

A identidade visual usa o **cubo roxo original da KONAET**, fornecido no projeto `konaet-cover`. O nome público é **KONAET**; o endereço técnico `7dsolv/konaet-bot` preserva as integrações existentes. [Origem da marca](visuals/brand/README.md).

![Demonstração animada: App, identidade, diff, push e revisão](assets/konaet-flow.gif)

O GIF ilustra o protocolo. Os números exibidos vêm dos testes offline com **Git real em repositórios locais** e respostas de API controladas. A autenticação de uma App instalada é uma verificação separada. [Relatório reproduzível](docs/VALIDATION.md).

## O que o pacote faz

| Etapa | Comportamento |
| --- | --- |
| **Identidade** | Confere slug, ID, login e tipo `Bot` retornados pela API. |
| **Escopo** | Gera token temporário limitado ao repositório atual, revogado pela dependência oficial ao fim do job. |
| **Diff** | Confere arquivos literais, renomeações e o diff completo da proposta, inclusive alterações staged ou introduzidas por hooks. |
| **Git** | Preserva a branch base e usa push normal. Uma branch remota divergente interrompe a atualização. |
| **Proposta** | Cria ou atualiza a PR da branch; recupera falha depois do push sem criar outro commit. |
| **Decisão** | O mantenedor revisa e decide o merge. |

![Arquitetura: fronteiras de identidade, runner e revisão](assets/konaet-architecture.svg)

## Começar com sua App

1. Use o [cadastro oficial pré-preenchido](https://github.com/settings/apps/new?name=Konaet&description=Automacao%20Konaet%20com%20identidade%20propria%2C%20commits%20e%20propostas%20para%20revisao%20humana.&url=https%3A%2F%2Fgithub.com%2F7dsolv%2Fkonaet-bot&public=true&webhook_active=false&contents=write&pull_requests=write). Escolha um nome disponível para sua App.
2. Instale-a nos repositórios desejados com **Contents** e **Pull requests: Read and write**.
3. Em Actions, crie a variável `KONAET_APP_CLIENT_ID` e o segredo `KONAET_APP_PRIVATE_KEY`.
4. Em `expected-slug`, informe o slug da sua App. O padrão `konaet` exige a App oficial com esse slug.

A configuração está em [`github-app.json`](github-app.json). Pelo MATLAB, `abrir_cadastro_konaet` abre o mesmo formulário. A chave da App oficial permanece com seu mantenedor; outros usuários usam suas próprias credenciais.

```yaml
name: Propor resultados
on: [workflow_dispatch]
permissions:
  contents: read

jobs:
  propor:
    runs-on: ubuntu-24.04
    steps:
      - uses: 7dsolv/konaet-bot@a27acebb28894beb79a7f83409788d4122a9fd41 # v1.3.0 source
        id: konaet
        with:
          client-id: ${{ vars.KONAET_APP_CLIENT_ID }}
          private-key: ${{ secrets.KONAET_APP_PRIVATE_KEY }}
          expected-slug: konaet # substitua pelo slug da sua App

      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7
        with:
          token: ${{ steps.konaet.outputs.token }}
          fetch-depth: 0

      - name: Gerar arquivo demonstrativo
        run: |
          mkdir -p relatorios
          date -u '+Execucao em %Y-%m-%dT%H:%M:%SZ' > relatorios/estado.txt

      - uses: 7dsolv/konaet-bot/propose@a27acebb28894beb79a7f83409788d4122a9fd41 # v1.3.0 source
        with:
          token: ${{ steps.konaet.outputs.token }}
          bot-login: ${{ steps.konaet.outputs.bot-login }}
          bot-id: ${{ steps.konaet.outputs.bot-id }}
          paths: relatorios/estado.txt
          branch: konaet/resultado-${{ github.run_id }}
          base: ${{ github.event.repository.default_branch }}
          title: 'Konaet: revisar resultado gerado'
          body: O mantenedor pode conferir o diff antes do merge.
```

Para reutilizar uma branch entre execuções, faça checkout dela antes de gerar os arquivos. O [workflow manual do pacote](.github/workflows/propor.yml) já faz essa preparação. O [contrato de uso](docs/CONTRACT.md) detalha entradas, saídas, recuperação e conflitos.

## Testar e reproduzir a apresentação

No MATLAB em Linux, com Bash e Git:

```matlab
addpath('tests', 'visuals')
r = run_konaet_tests(pwd, fullfile(pwd, 'artifacts'));
render_konaet_assets(fullfile(pwd, 'artifacts', 'showcase'), r);
```

O CI executa esses comandos, actionlint e ShellCheck, verifica o contrato JSON e guarda o relatório e os visuais nos artifacts. A apresentação é composta por [`visuals/render_konaet_assets.m`](visuals/render_konaet_assets.m): capa, diagrama SVG e GIF de 48 quadros com o cubo original. O ícone da App conserva os bytes da imagem de origem; o CI confere seu SHA-256 e sua procedência. [Manifesto dos visuais](assets/showcase-manifest.json).

## Estado de publicação

O pacote é público e reutilizável sob licença MIT. A publicação da **Action** no Marketplace exige o contrato de desenvolvedor e a seleção de categoria na tela de release do GitHub. [Preparação da listagem](docs/MARKETPLACE.md).

A App **KONAET** já foi registrada, e a conta `konaet[bot]` existe. A autenticação por chave da App e sua instalação devem ser verificadas separadamente pelo workflow **Verificar identidade real da App**, após configurar as credenciais. Atribuir um commit à conta do bot não substitui essa autenticação; os testes offline não a declaram executada. A página da App fica em `/apps/konaet`; o endereço de perfil `/konaet[bot]` retorna 404.

O pacote automatiza identidade e propostas. Modelos científicos e pesquisa neural continuam nos projetos [RealidadeQuantica](https://github.com/7dsolv/RealidadeQuantica) e [Konaet-IA](https://github.com/7dsolv/Konaet-IA). Contribuições antigas de `github-actions[bot]` permanecem no histórico dos respectivos projetos.

O [XENOELEMENT X-01](https://github.com/7dsolv/RealidadeQuantica/tree/main/xeno) conecta percepção química e tátil, controle e resposta óptica em um protótipo MATLAB/Fortran/SystemVerilog. Publica equações, dados sintéticos, testes e gráficos, com fontes e antecedentes identificados. Suas avaliações medem tarefas numéricas definidas; não demonstram superioridade de um agente universal.

Fontes do pacote em MATLAB e configurações YAML/JSON, sem fontes HTML, JavaScript ou Python. As Actions oficiais são dependências de infraestrutura. [Licença](LICENSE) · [Segurança](SECURITY.md) · [Mudanças](CHANGELOG.md).
