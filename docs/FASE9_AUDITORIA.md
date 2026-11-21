# Auditoria da versão candidata

A candidata cobre a fundação, o fluxo de personagens e parte da Fase 3. Ela pode ser construída pelo Rojo. Testes de runtime do Roblox, desempenho e inspeção visual ainda precisam ser executados no Studio.

## Matriz

| Sistema | Estado | Evidência ou dependência |
| --- | --- | --- |
| Mapeamento Rojo | Aprovado com evidência | O Rojo 7.7.1 gerou o arquivo da experiência e o sourcemap |
| Sintaxe Luau | Aprovado com evidência | Os 24 arquivos de src compilaram no Luau Web |
| Perfil e migração | Aguardando teste no Studio | Migração e isolamento passaram em teste de regras. DataStore e concorrência real aguardam teste |
| Menu, editor R15, HUD e spawn | Aguardando teste no Studio | Fluxo integra remotes, perfil ativo e criação do avatar. Interface e câmera aguardam inspeção |
| Inventário | Parcial | Pilhas, mochila, capacidade e isolamento têm evidência isolada. Transferências, depósitos e cofres ausentes |
| Banco e comércio | Parcial | Regras de saldo, reenvio e cópia candidata testadas. Transferências e assinaturas de operações entre perfis ainda ausentes |
| Armas | Não implementado | Catálogo inclui munição e equipamento. Falta combate e validação em ambiente Roblox |
| Veículos, garagens e VIP | Não implementado | Campos e configurações sem frota ou integração de compras |
| Sete comunidades, departamentos e viaturas | Não implementado | A cena cinematográfica é local ao menu. Faltam mapa jogável, interiores e frota |
| Polícia | Parcial | Equipes e cargos iniciais com autorização. Falta serviço e operação policial |
| Facções e baques | Parcial | Equipes fictícias cadastradas. Sem domínio, baques ou cofres |
| Bailes, celular e vida social | Não implementado | Sem DJ, áudio, apps, propriedades ou empregos |

## Correções feitas na candidata

- `src/server/Services/ProfileSchema.luau` e `Profiles.luau` preservam dados da versão 1 e isolam os bens do personagem ativo. Se uma gravação transacional falhar sem confirmação, a sessão deixa de aceitar alterações para evitar sobrescrever uma transação que possa ter sido gravada.
- `src/server/Services/Characters.luau` filtra o nome completo, valida propriedade, desabilita spawn antes da seleção e impede a troca durante criação do avatar.
- `src/server/Services/InventoryRules.luau`, `Inventory.luau` e `src/client/init.client.luau` aplicam os mesmos limites a gravação e movimentação. A interface limpa o estado ao trocar de personagem.
- `src/server/Services/Economy.luau` e `Commerce.luau` rejeitam reenvio da sequência e aplicam saldo e itens à mesma cópia candidata. A venda confere se o item do slot continua idêntico ao apresentado na oferta.
- `src/client/CommercePanel.luau` carrega saldo e ofertas do servidor e fecha na troca do personagem. A mochila fecha ao abrir o painel de comércio.

## Evidência e validação pendente

Foram executados compilação da árvore Luau, build e sourcemap Rojo, revisão de whitespace do Git e sete cenários automatizados. Os testes automatizados exercitam regras de negócio com substitutos locais para serviços Roblox. A validação no Studio deve cobrir filtro de texto, criação e respawn R15, layout em retrato e paisagem, toque, dois clientes, concorrência de compras, acesso real ao DataStore e desligamento do servidor. Consulte os [testes de personagens](testes-personagens.md) e o [roteiro de comércio](testes-comercio.md).

Antes de liberar transferências entre contas, implemente reconciliação idempotente entre registros e teste quedas durante as etapas de débito e crédito. A economia atual grava apenas no perfil do ator.

## Assets ausentes

| Asset | Finalidade e instalação futura |
| --- | --- |
| Cabelos, roupas, coletes e acessórios originais R15 | Usar no catálogo de aparência e em equipamentos de carreira |
| Kits arquitetônicos distintos, vegetação e vias | Instalar nos módulos de edição de cada comunidade e validar colisões e acessibilidade |
| Interiores PMERJ e BOPE | Instalar nas zonas de batalhão e conectar portas, garagens e pontos de serviço |
| Viaturas PMERJ, motocicletas, SUVs e blindados BOPE | Instalar no catálogo de modelos do futuro serviço de veículos, com encaixes para rodas, portas e iluminação |
| Paredões, palcos e áudio autorizado | Instalar nos sete pontos de baile e configurar IDs que a experiência tenha permissão para reproduzir |

A candidata ainda depende dos testes no Studio e dos sistemas pendentes no [status geral](STATUS_GERAL.md) antes de publicação.
