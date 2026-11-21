# Roteiro de aceitação administrativa no Roblox

## Evidência automatizada

```bash
npm install --prefix /tmp/operacao-verificacao luau-web@1.5.1
node tests/run-admin.mjs /tmp/operacao-verificacao/node_modules/luau-web/src/index.js
node tests/run-rules.mjs /tmp/operacao-verificacao/node_modules/luau-web/src/index.js
rojo build -o OperacaoRio.rbxlx
```

A suíte administrativa usa módulos reais de autorização, argumentos, auditoria, moderação e ações com substitutos para APIs Roblox, perfis e cidade. Cobre fundador, ator comum, hierarquia, autopromoção, proteção do fundador, carga inválida, banimento e desbanimento, persistência de cargo, dinheiro, itens, equipe, troca de personagem, falha de DataStore, reenvio, comandos inválidos e concorrência. A interface responsiva depende de avaliação no Studio.

## Sessão de Studio e dispositivos

1. Confira que lista vazia bloqueia o painel. Configure uma conta Roblox real de teste e verifique F8, /admin e botão touch. Teste tela pequena, retrato e paisagem. Confira rolagem, pesquisa e confirmação.
2. Conceda SUPPORT e ADMIN a contas de teste. Reabra a sessão com persistência administrativa ligada. Confira acesso e abas por cargo. Revogue um cargo durante uma sessão em execução.
3. Com dois personagens ativos, teste teleporte, observação e retorno da câmera, congelamento, cura e ForceField. Teste renascimento de um avatar morto e confirme que o respawn normal não repete a operação.
4. Abra uma confirmação de saldo ou inventário, troque o personagem do alvo e confirme a rejeição. Reenvie uma confirmação já usada e tente duas operações concorrentes. Compare saldo, slots, auditoria e extrato após reconectar.
5. Teste troca de equipe elegível e rejeição de BOPE sem autorização. Confira filtragem de motivos e anúncio usando as APIs reais. Teste o efeito de erro de DataStore numa experiência descartável.

## Servidor de teste publicado pelo proprietário

1. Em experiência isolada com `Players.BanningEnabled`, aplique banimento temporário a uma conta de teste. Confira bloqueio de conexão, expiração e revogação. Repita com banimento permanente e revogue ao final.
2. Abra dois servidores da mesma experiência de teste. Verifique anúncio, clima e horário usando MessagingService. Confira que uma falha de inscrição ou publicação recebe feedback.
3. Compare os registros dos casos acima com as operações efetuadas. Confirme que o resultado aparece apenas após resposta da API ou como incerto em caso de erro de comunicação.

Nenhum desses cenários Roblox foi executado no ambiente do Codex.
