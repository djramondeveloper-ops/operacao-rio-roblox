# OPERAÇÃO RIO — Roblox RP

Jogo multiplayer de roleplay brasileiro ambientado em uma cidade fictícia inspirada no Rio de Janeiro. A visão inclui sete comunidades, PMERJ e BOPE, facções fictícias, armas, veículos, loja VIP e baques PvP. A experiência é voltada a jogadores reais, sem NPCs com IA.

## Instalação

1. Instale o Roblox Studio, o Rojo 7 e o plugin Rojo para o Studio.
2. Na raiz do repositório, execute `rojo serve`.
3. Abra uma Baseplate no Studio. No plugin Rojo, escolha **Connect** e conecte a sessão local, normalmente na porta 34872.
4. Use **Test → Server & Clients** com dois clientes. Abra **Mochila e equipe** pelo botão ou pressione **I**.
5. Para gerar um arquivo de experiência local, execute `rojo build -o OperacaoRio.rbxlx`.

O Studio usa armazenamento em memória por padrão. Para testar o DataStore, publique uma experiência de teste separada, habilite **Game Settings → Security → Enable Studio Access to API Services** e configure `StudioPersistence = true` em `src/server/Settings.luau`. O Studio usa o DataStore `OperacaoRio_Studio`. A experiência publicada usa `OperacaoRio_Profiles`.

## Primeira etapa

- Perfil por UserId com versão de esquema, salvamento periódico, tentativa de gravação na saída e bloqueio temporário contra sessões concorrentes.
- Equipes Civil, PMERJ, BOPE, Aliança Aurora e Coletivo Horizonte. PMERJ e BOPE ficam abertas no Studio por padrão. Em experiências publicadas, configure os UserIds autorizados em `Settings.PoliceAccess` por equipe, por exemplo `pmerj = { [123456] = true }`.
- Inventário com 12 slots, limite de 8 kg, pilhas e movimentação validada no servidor. Cada perfil novo recebe água e lanche. A concessão de itens é uma operação interna do servidor.
- Interface em português para teclado, mouse e toque. O cliente solicita ações e exibe o estado devolvido pelo servidor.

## Estrutura e próximos sistemas

O mapeamento Rojo original foi preservado. `src/shared` contém configurações compartilhadas. `src/server` inicializa os serviços autoritativos. `src/client` monta a interface. Os seis arquivos da base foram auditados. Os pontos de entrada que apenas registravam logs passaram a inicializar os sistemas.

| Sistema | Base disponível | Trabalho pendente |
| --- | --- | --- |
| Armas | Catálogo por ID, inventário e autorização por equipe | Equipamentos, equipar, validação de combate e regras de dano |
| Veículos | Equipes e perfil versionado | Catálogo, chaves, propriedade e ciclo de criação no servidor |
| Loja VIP | Categorias e IDs de Game Pass reservados em `GameConfig.VIP` | IDs reais, verificação de benefícios com MarketplaceService e processamento idempotente de recibos se houver Developer Products |
| Território e baque | Sete comunidades, IDs estáveis, facções e parâmetros de captura em `GameConfig` | Mapa, zonas, presença verificada no servidor, posse, captura, recarga e interface |

O [roteiro de testes no Studio](docs/testes-studio.md) descreve os cenários de aceitação.
