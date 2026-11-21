# Aceitação da Fase 2 no Roblox Studio

Configure R15 e siga a instalação do README. Use uma conta real em uma experiência separada para testar a filtragem de nomes e o DataStore. A filtragem usa o serviço oficial durante a criação. Jogadores simulados podem ter IDs que o serviço não aceita.

1. Entre e confirme que a câmera do menu se move e que não existe avatar no mundo antes da seleção.
2. Abra o editor, passe pelos seis modelos, altere pele, cabelo, rosto, roupa e acessório. Gire e dê zoom. Verifique no toque e com mouse e teclado. Cancele e confira que a vaga continua vazia.
3. Tente um nome inválido. Depois salve um nome RP aprovado. Crie mais dois personagens e confira o limite de três.
4. Selecione um personagem e confira câmera, corpo R15, aparência, nome, vida e inventário. Mova um item, troque de personagem e confirme que o outro inventário está separado. Volte ao primeiro personagem.
5. Teste o modelo visual BOPE com `StudioOpenPoliceTeams = false` e listas vazias. O personagem inicia como Civil e não pode selecionar equipes policiais.
6. Provoque respawn pelo reset do Roblox e confira aparência e seleção preservadas. Volte ao menu enquanto o personagem está morto e confira que ele não reaparece no mundo.
7. Tente excluir um personagem e cancele. Confirme a exclusão em seguida, verifique que o personagem some e reabra a sessão com persistência habilitada para confirmar.
8. Teste um perfil versão 1 preservado em uma experiência descartável. Crie o primeiro personagem e confirme que ele recebeu o inventário anterior. Confira que os personagens adicionais recebem seus próprios itens iniciais.
9. Interrompa o acesso às APIs em uma experiência descartável para validar o tratamento de falha. Um personagem só deve aparecer como salvo depois que o servidor confirmar a operação.
