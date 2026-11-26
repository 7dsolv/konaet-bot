# Segurança

Este pacote usa tokens de instalação com escrita em conteúdo e pull requests no repositório atual. Guarde a chave privada como Actions Secret e execute geradores confiáveis antes da etapa de proposta.

O módulo valida origem, branch e caminhos, e usa push normal. Antes do envio, a inspeção local bloqueia formatos reconhecidos de credenciais, arquivos reservados, links simbólicos e submódulos. Consulte os limites no [contrato da proposta](docs/CONTRACT.md#proposta--módulo-propose). Instalações, permissões, proteção de branches e credenciais permanecem sob controle do mantenedor.

Reporte vulnerabilidades de forma privada em [Security → Report a vulnerability](https://github.com/7dsolv/konaet-bot/security/advisories/new). Issues públicas servem apenas para bugs não sensíveis. Não envie tokens, chaves privadas ou dados do repositório privado. Em caso de exposição de chave, revogue-a na página da App e gere outra antes de repetir a automação.

A versão minor mais recente recebe correções; não há SLA comercial. O helper de processos usa arquivos temporários com acesso restrito ao proprietário e remove-os ao terminar. O computador, o armazenamento temporário e os geradores devem ser confiáveis. Consulte [manutenção](docs/MAINTENANCE.md).
