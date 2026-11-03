# Segurança

Este pacote usa tokens de instalação com escrita em conteúdo e pull requests no repositório atual. Guarde a chave privada como Actions Secret e execute geradores confiáveis antes da etapa de proposta.

O módulo valida origem, branch e caminhos, e usa push normal. Isso não torna o conteúdo dos arquivos seguro nem transforma o módulo em scanner de segredos. Instalações, permissões, proteção de branches e credenciais permanecem sob controle do mantenedor.

Para reportar um problema, abra uma issue com uma reprodução sanitizada. Não envie tokens, chaves privadas ou dados do repositório privado. Em caso de exposição de chave, revogue-a na página da App e gere outra antes de repetir a automação.
