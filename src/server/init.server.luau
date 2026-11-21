local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Profiles = require(script.Services.Profiles)
local Inventory = require(script.Services.Inventory)
local Teams = require(script.Services.Teams)

local nextRequest = {}

Teams.Start()
Profiles.Start(Teams.Restore)

local request = Instance.new("RemoteFunction")
request.Name = "OperacaoRioRequest"
request.OnServerInvoke = function(player, action, first, second)
    local now = os.clock()
    if now < (nextRequest[player] or 0) then
        return { Message = "Aguarde antes de tentar novamente." }
    end
    nextRequest[player] = now + 0.25

    local data = Profiles.Get(player)
    if not data then
        return { Message = "Carregando seu perfil…" }
    end

    local message
    if action == "move" then
        local _, status = Inventory.Move(player, first, second)
        message = status
    elseif action == "team" then
        local _, status = Teams.Select(player, first)
        message = status
    elseif action ~= "state" then
        return { Message = "Ação inválida." }
    end

    return {
        Message = message,
        Team = data.Team,
        Available = Teams.Available(player),
        Slots = data.Slots,
        Grams = Inventory.Weight(data.Slots),
    }
end
request.Parent = ReplicatedStorage

Players.PlayerRemoving:Connect(function(player)
    nextRequest[player] = nil
end)
