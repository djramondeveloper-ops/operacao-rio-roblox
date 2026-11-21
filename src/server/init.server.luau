-- OPERAÇÃO RIO: ponto de entrada do servidor
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))

print(("[OPERAÇÃO RIO] Servidor iniciado | %d comunidades configuradas"):format(#Config.Communities))

Players.PlayerAdded:Connect(function(player)
    print(("[OPERAÇÃO RIO] Jogador conectado: %s (%d)"):format(player.Name, player.UserId))
end)
