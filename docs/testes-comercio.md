# Verificação da Fase 3

## Regras executáveis fora do Studio

Use Node.js 22+ e instale o compilador Luau Web em um diretório temporário.

```bash
npm install --prefix /tmp/operacao-verificacao luau-web@1.5.1
node tests/run-rules.mjs /tmp/operacao-verificacao/node_modules/luau-web/src/index.js
rojo build -o OperacaoRio.rbxlx
```

A suíte carrega os módulos Luau do projeto com substitutos explícitos para serviços do Roblox. Asserções cobrem migração, isolamento, permissões, pilhas, slots, mochila, repetição de transação e preservação do perfil após uma compra rejeitada. Dois cenários exercitam o serviço de perfil com DataStore substituto, incluindo concorrência e perda da resposta após a gravação.

## Banco e lojas no Studio

1. Com um personagem novo, aproxime-se do banco. Deposite R$ 30, saque R$ 5 e confira carteira, banco e extrato. Tente sacar mais que o saldo e confira que os valores não mudaram.
2. Compre um item perto da loja. Confirme a alteração na HUD e reabra a mochila. Venda o mesmo item e confira o preço indicado e a remoção de uma unidade.
3. Envie duas compras simultâneas usando a mesma sequência de transação. A compra deve ocorrer no máximo uma vez. Repita de fora da distância aceita e confira a rejeição.
4. Preencha a mochila e tente comprar sem espaço. Confira saldo e extrato inalterados. Equipe uma mochila, ocupe um slot adicional e tente removê-la.
5. Divida uma pilha, arraste entre slots no PC e use toque no celular. Teste o kit médico com vida cheia e com dano.
6. Alterne de personagem com o painel aberto. Confirme que os dados anteriores são fechados e que o novo personagem tem seu próprio saldo, extrato e inventário.
7. Com DataStore do Studio habilitado, reconecte após uma compra e confirme que dinheiro e item foram gravados juntos. Em uma experiência descartável, simule indisponibilidade do DataStore e verifique se uma gravação incerta bloqueia a sessão até que seja possível reconciliar o perfil.
