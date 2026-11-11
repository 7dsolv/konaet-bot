# KONAET no ecossistema verificável

A automação deste pacote integra o
[RealidadeQuantica](https://github.com/7dsolv/RealidadeQuantica) com a
[Konaet Sovereign Spec](https://github.com/7dsol3/konaet-sovereign-spec).

O laboratório produz arquivos científicos; a App instalada publica propostas
com identidade conferida e escopo limitado. Separadamente, a ponte MATLAB
executa esta suíte de contratos Git e o ativador, liga o resultado ao hash
do experimento e produz um compromisso para `SocialReceiptRegistry.ko`.
O runtime da Sovereign finaliza esse compromisso em quatro processos de
teste e confere o certificado contra gênese, contrato e compromisso esperados.

O [workflow científico](https://github.com/7dsolv/RealidadeQuantica/blob/main/.github/workflows/ecosystem.yml)
fixa todas as revisões externas e produz relatórios com atestação de
procedência na `main`. A [especificação da ponte](https://github.com/7dsol3/konaet-sovereign-spec/tree/main/ecosystem)
explica os bytes canônicos, limites e referências de confiança.

Esta integração reutiliza a API existente deste pacote e mantém seus
consumidores atuais. A suíte de integração usa Git local real e chaves
sintéticas, sem enviar credenciais da App para outro repositório. Seus
resultados offline não devem ser apresentados como autenticação de App.
Use o workflow de identidade real deste pacote para essa verificação.

Os recibos não substituem os checks obrigatórios de uma PR. Não alteram a
proteção da `main`, a instalação da App, seu slug ou seus privilégios.
Não transferem conhecimentos de outros modelos nem medem superioridade geral.

O [BTC Lab](https://github.com/7dsol3/konaet-sovereign-spec/tree/main/btc-lab)
fica na especificação e tem supervisor local para puzzles públicos. Este
bot não recebe chaves Bitcoin ou soluções privadas e não agenda buscas
por recompensas em runners hospedados.
