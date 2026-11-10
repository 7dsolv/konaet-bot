# Histórico

## v1.3.1

- Aguarda de forma limitada a consistência do SHA na API após um push, sem editar uma PR enquanto o commit exato não for confirmado.
- Mantém a rejeição de SHA persistentemente divergente, fork, branch, base ou metadados incorretos.
- Envia erros para stderr para preservar o diagnóstico dentro de substituições de comando.
- Regressões para atraso na listagem/releitura e falha da API de propostas.

## v1.3.0

- PRs conferidas por repositório, branches e SHA, incluindo releitura após criação.
- Destinos efetivos do Git validados; reescritas e múltiplos push URLs recusados.
- Regressões para forks homônimos, metadados divergentes e redirecionamentos.
- Helper de processos com prazo, limite de saída e I/O temporário privado.
- Dependências fixadas por SHA, revisão por responsáveis e documentação de manutenção.

## v1.2.0

- Ativador MATLAB, política de instalação e assinatura JWT com chaves sintéticas nos testes.
- Credenciais da App verificadas nos dois repositórios e prova pública de autenticação real.

## v1.1.1

- Nome público unificado para **KONAET**, incluindo metadados da Action e apresentação.
- Cubo roxo original de `7dsolv/konaet-cover` na capa, ícone, diagrama e GIF; substitui a letra K da apresentação anterior.
- Ícone publicado sem alterar os bytes da origem. Procedência, revisão e SHA-256 registrados e verificados no CI.
- Caminhos de uso e contrato do módulo preservados.

## v1.1.0

- A identidade passa a conferir ID positivo, login exato e tipo `Bot`.
- Novo módulo `propose`: lista de caminhos, preservação da base, push sem força, criação/atualização de PR e recuperação de falha depois do push.
- Suíte MATLAB com contratos e integração Git real local; API substituída por fixture explícito.
- Capa, ícone, diagrama SVG e animação de 48 quadros gerados em MATLAB, com manifesto de procedência.
- Documentação e release preparadas para o fluxo de publicação no Marketplace.

## v1.0.0

- Token de GitHub App restrito ao repositório e resolução de autoria.
- Configuração pública da App na raiz e helper MATLAB para abrir o cadastro.
- Workflow manual de proposta e licença MIT.
