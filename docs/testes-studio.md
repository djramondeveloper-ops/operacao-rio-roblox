# Testes da primeira etapa no Roblox Studio

Os resultados abaixo são critérios de aceitação para execução manual.

## Servidor com dois clientes

1. Confira no Explorer os mapeamentos `ReplicatedStorage.Shared`, `ServerScriptService.Server` e `StarterPlayer.StarterPlayerScripts.Client`.
2. Inicie um servidor com dois jogadores. Na Fase 2, siga primeiro o [roteiro de personagens](testes-personagens.md) para selecionar um personagem em cada sessão com conta real. Abra a interface pelo botão e pela tecla **I**. Verifique o estado inicial Civil, os 12 slots, Água ×2, Lanche ×1 e 1,25 kg. Reinicie um personagem e confira que a interface continua acessível.
3. No primeiro cliente, mova a água para um slot vazio, troque água e lanche entre slots ocupados e escolha Aliança Aurora. No servidor, confira o objeto `Player.Team`. No segundo cliente, confira que a equipe e o inventário próprios continuam iguais.
4. No emulador de dispositivos, teste os modos retrato e paisagem. Abra e feche pelo toque, role até a última equipe e mova um item entre slots.
5. Configure `StudioOpenPoliceTeams = false`, deixe as listas vazias e reinicie a sessão. Verifique que PMERJ e BOPE ficam restritas. Configure um UserId real autorizado para testar com a conta correspondente em uma sessão de teste.

## Validações do servidor

Na Command Bar em contexto **cliente**, execute chamadas separadas por pelo menos um segundo.

```luau
local request = game:GetService("ReplicatedStorage").OperacaoRioRequest
print(request:InvokeServer("move", 1.5, 2).Message)
task.wait(1)
print(request:InvokeServer("move", 1, 999).Message)
task.wait(1)
print(request:InvokeServer("grant", "radio", 100).Message)
task.wait(1)
print(request:InvokeServer("team", "equipe_inexistente").Message)
```

Verifique que as solicitações são rejeitadas e que o inventário e a equipe permanecem iguais. Com equipes policiais restritas, repita com `request:InvokeServer("team", "bope")`.

Na Command Bar em contexto **servidor**, com um perfil novo já carregado:

```luau
local player = game:GetService("Players"):GetPlayers()[1]
local inventory = require(game:GetService("ServerScriptService").Server.Services.Inventory)
assert(inventory.Grant(player, "radio", 1))
assert(not inventory.Grant(player, "radio", 100))
```

Reabra a interface. Confira um rádio e 2,05 kg. Em um perfil novo, conceda 4 águas e depois 2 águas pelo mesmo método. Mova a segunda pilha para a primeira. A pilha cheia de seis unidades deve impedir a fusão e preservar as duas unidades na origem.

## Persistência em experiência de teste

1. Configure o DataStore do Studio e teste com a mesma conta real entre sessões. Perfis simulados do teste multicliente podem ter IDs diferentes dos perfis reais.
2. Mova um item, selecione uma facção, aguarde pelo menos 45 segundos e saia. Abra outra sessão e confira equipe, posição de item e peso.
3. Repita a alteração e feche a sessão antes do salvamento periódico. Ao voltar, confira a gravação de saída.
4. Com `StudioPersistence = true`, desabilite temporariamente o acesso às APIs na experiência de teste. Confirme que a falha de leitura não abre um inventário padrão e que o jogador recebe a mensagem de perfil indisponível. Reabilite o acesso e confirme que os dados anteriores podem ser carregados.
