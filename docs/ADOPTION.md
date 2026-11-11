# KONAET / adoção verificável

A tarefa oferecida é **propor resultados de um gerador autorizado para revisão**.
O laboratório acrescenta pesquisa limitada a três configurações de treinamento.
Não existe um serviço que absorve modelos de terceiros ao instalar a App.

## Primeiro projeto de uma empresa

1. Crie uma App própria com Contents e Pull requests em escrita, somente nos
   repositórios escolhidos. Use o manifesto do pacote e outro `expected-slug`.
   A instalação pública da App oficial não entrega a chave privada do mantenedor.
2. Guarde a chave em Actions Secrets e o identificador em Variables. Faça o
   workflow de identidade real e registre instalação, bot e repositório obtidos.
3. Fixe identidade e `propose` ao SHA revisado da release. Faça checkout sem
   credenciais persistidas e gere apenas arquivos permitidos, antes da proposta.
4. Execute o caso sem mudança e uma proposta com mudança. Confira autor,
   origem/base, SHA e diff; os testes de Git não substituem essa instalação real.
5. Reexecute depois de falha simulada de rede. A branch deve permitir recuperar
   a mesma proposta sem commit duplicado. Revogue a instalação e confirme que
   o acesso deixa de funcionar. Registre a evidência na sua conta.

Os 52 contratos Git e 19 testes do ativador são a base reproduzível. A instalação
em uma terceira empresa ainda exige esse ensaio: não é declarada por uma fixture.

## Limites e operação

| Aspecto | Contrato atual |
| --- | --- |
| Escopo de token | Um repositório por execução; revogação pelo post step da dependência oficial |
| Escrita | Branch de proposta e paths literais; sem force push ou merge automático pelo módulo |
| Fila | Concurrency do workflow; uma execução de publicação por repositório, sem cancelar escrita em andamento |
| Consultas de consistência | Até cinco leituras de PR, esperas de 1, 2, 3 e 4 segundos |
| Sessão demonstrativa | Timeout de dez minutos; limite explícito também deve existir no workflow consumidor |
| Recuperação | Falha é reportada; nova execução pode recuperar push/PR sem duplicar commit |
| Credenciais | Secrets da instalação; não entram em artefatos, conteúdo do modelo ou memória |
| Auditoria | SHA de origem, SHA publicado, URL da PR, bot e execução nos artefatos/summary |

O GitHub agenda os jobs. Não oferecemos uma fila externa permanente nem um SLA.
Não execute código de forks ou geradores não revisados em um job com chave da
App. Consumidores isolam instalações e Secrets; não compartilham a chave oficial.

## Critério de adoção

Meça tarefas concluídas, propostas rejeitadas corretamente, recuperação, latência
total e custo no seu ambiente. Compare com outras soluções na mesma tarefa e
nas mesmas permissões. Hardware, desempenho do detector e disponibilidade da
rede Sovereign possuem protocolos separados; o sucesso de uma PR não os aprova.

[Contrato completo](CONTRACT.md) · [Segurança](../SECURITY.md) ·
[Integração dos três projetos](ecosystem.md)
