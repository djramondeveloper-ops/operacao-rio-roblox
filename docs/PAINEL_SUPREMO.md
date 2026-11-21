# Painel Supremo do Fundador

## Configurar acesso

1. Abra o perfil Roblox da conta proprietária e copie o número na URL do perfil.
2. Em `src/server/Admin/Config.luau`, altere o mapa de UserIds. Exemplo de formato para substituir pelo número real:

   ```luau
   FounderUserIds = { [123456789] = true },
   ```

3. Sincronize a branch com o Rojo. Use **F8**, **/admin** ou **Painel supremo** no celular.
4. No Studio, cargos e auditoria ficam em memória. Para testar persistência administrativa, configure `StudioPersistence = true` no mesmo arquivo e habilite acesso à API em uma experiência de teste separada. Perfis dos personagens usam a configuração de persistência de `src/server/Settings.luau`.

A lista fica em ServerScriptService. A lista vazia ou inválida bloqueia todos os cargos. Somente a configuração cria um fundador. O DataStore de cargos é separado dos perfis. Uma falha ao consultar permissões bloqueia a ação.

## Matriz de permissões padrão

| Nível mínimo | Ações liberadas |
| --- | --- |
| SUPPORT | Ir até jogador e observar |
| MODERATOR | Expulsar, trazer, congelar, descongelar, curar e consultar histórico |
| ADMIN | Banir, revogar banimento, renascer avatar, ForceField, anúncio e consulta de saldo e inventário |
| DIRECTOR | Horário, clima, troca de equipe elegível, auditoria e gestão de subordinados |
| FOUNDER | Alterações de dinheiro e itens e gestão de diretores |

Cada nível herda o anterior. As ações sobre terceiros exigem cargo superior ao alvo. Atribuição de cargo nunca permite modificar a própria função ou a de um fundador. Um diretor pode gerir cargos abaixo do seu. `AllowDirectorDelegation` permite a um diretor conceder excepcionalmente DIRECTOR a um subordinado. A revogação de DIRECTOR permanece reservada a fundador.

## Comandos

Use Roblox UserId decimal como `id`. O painel mostra os IDs dos jogadores do servidor e permite digitar IDs offline para cargos, banimentos e histórico.

| Comando | Uso |
| --- | --- |
| `/admin` | Abrir painel |
| `/kick id motivo` | Expulsar do servidor |
| `/ban id dias motivo` | Banir do universo. Use `-1` para permanente |
| `/unban id motivo` | Revogar banimento |
| `/history id` | Histórico disciplinar registrado pelo painel |
| `/tp id`, `/goto id`, `/bring id` | Ir até o jogador ou trazê-lo |
| `/freeze id`, `/unfreeze id`, `/spectate id` | Congelar, descongelar ou observar |
| `/heal id`, `/revive id`, `/god id` | Restaurar vida, renascer avatar morto ou alternar ForceField |
| `/announce texto` | Distribuir anúncio filtrado |
| `/balance id`, `/inventory id` | Consultar carteira, banco e slots ativos |
| `/setmoney id valor`, `/givemoney id valor`, `/removemoney id valor` | Alterar dinheiro em mãos |
| `/giveitem id item quantidade`, `/removeitem id slot quantidade` | Alterar inventário |
| `/setteam id equipe` | Atribuir equipe para a qual a conta já é elegível |
| `/settime hora`, `/setweather clear`, `/setweather fog` | Controlar horário e neblina |
| `/role id cargo` | Atribuir cargo. Use `NONE` para remover |
| `/logs [id]` | Consultar registros paginados. No painel há também filtro por comando |
| `/confirmadmin` | Confirmar a última ação sensível, dentro de 30 segundos |

Os IDs iniciais de equipe são `civil`, `pmerj`, `bope`, `aurora` e `horizonte`. Consulte `src/shared/Items.luau` para os IDs de itens. O ForceField protege contra mecanismos de dano do Roblox que respeitam ForceField. Congelamento e ForceField se aplicam ao avatar atual.

## Persistência e auditoria

Banimentos usam `Players:BanAsync` e `Players:UnbanAsync`, com expiração administrada pelo Roblox, escopo de universo e contas alternativas excluídas. O histórico do painel cobre operações originadas pelo próprio painel e preservadas na janela de retenção. Ban e unban exigem servidor publicado com `Players.BanningEnabled`, e ficam indisponíveis no Studio.

O DataStore administrativo registra início e resultado sob um ID de operação. Um estado pendente ou incerto pede conferência do alvo antes de repetir a operação. A retenção padrão é de até 30 dias e 300 registros no universo. Recusas são amostradas para controlar gravações sob abuso. O filtro de texto do Roblox é exigido para motivos e anúncios. O conteúdo de anúncios fica fora da auditoria.

As confirmações são vinculadas à sessão do administrador e consumidas no servidor. Alterações de bens e equipes ficam vinculadas ao personagem ativo na confirmação. A remoção de itens também verifica o conteúdo do slot. O perfil e seu inventário continuam usando o mesmo serviço da Fase 3. A proteção por alvo cobre operações simultâneas no mesmo servidor. A escala administrativa usa UpdateAsync e revalidação durante o commit.

Os controles de cidade usam MessagingService para servidores ativos. No Studio, funcionam localmente. O horário e a neblina voltam à configuração de mapa em novos servidores. Entrega a outros servidores depende da inscrição ativa no tópico Roblox.

## Integrações pendentes

`/spawncar`, `/deletecar` e `/repaircar` informam indisponibilidade ao fundador. O serviço futuro deve oferecer operações internas autorizadas com identificador persistente de veículo, proprietário, garagem e estado, além de devolver um resultado verificável para auditoria. Polícia e facções precisam expor alterações autorizadas de patentes, membros e liderança. Territórios e eventos precisam expor operações internas equivalentes. Essas ações só devem aparecer como executáveis no catálogo depois que os serviços estiverem integrados.
