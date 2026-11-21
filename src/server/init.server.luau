local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.CharacterAutoLoads = false

local Characters = require(script.Services.Characters)
local Profiles = require(script.Services.Profiles)
local Inventory = require(script.Services.Inventory)
local Teams = require(script.Services.Teams)

local nextRequest = {}
local activeRequests = {}

Teams.Start()
Characters.Start()
Profiles.Start(function(player)
    player:SetAttribute("ProfileReady", true)
end)

local request = Instance.new("RemoteFunction")
request.Name = "OperacaoRioRequest"
local function handle(player, action, first, second, third)
    if action == "characters" then
        local list = Characters.List(player)
        return { Characters = list, Message = if list then nil else "Carregando seu perfil…" }
    elseif action == "createCharacter" or action == "deleteCharacter"
        or action == "selectCharacter" or action == "returnToMenu" then
        local operation = ({
            createCharacter = Characters.Create,
            deleteCharacter = Characters.Delete,
            selectCharacter = Characters.Select,
            returnToMenu = Characters.ReturnToMenu,
        })[action]
        local success, message = operation(player, first, second, third)
        return { Ok = success, Message = message, Characters = Characters.List(player) }
    end

    local data = Profiles.Get(player)
    if not data then
        return { Message = "Carregando seu perfil…" }
    end

    local message
    if action == "move" then
        local _, status = Inventory.Move(player, first, second, third)
        message = status
    elseif action == "use" or action == "discard" then
        local _, status = Inventory.Action(player, action, first, second)
        message = status
    elseif action == "team" then
        local changed, status = Teams.Select(player, first)
        if changed then
            Characters.PublishIdentity(player)
        end
        message = status
    elseif action ~= "state" then
        return { Message = "Ação inválida." }
    end

    local slots, capacity = Inventory.Limits(data)
    return {
        MaxSlots = slots,
        MaxGrams = capacity,
        Backpack = data.Backpack == true,
        Message = message,
        Team = data.Team,
        Available = Teams.Available(player),
        Slots = data.Slots,
        Grams = Inventory.Weight(data.Slots),
    }
end
request.OnServerInvoke = function(player, action, first, second, third)
    local now = os.clock()
    if activeRequests[player] or now < (nextRequest[player] or 0) then
        return { Message = "Aguarde antes de tentar novamente." }
    end
    if type(action) ~= "string" then
        return { Message = "Ação inválida." }
    end
    nextRequest[player] = now + (if action == "createCharacter" then 2 else 0.25)
    activeRequests[player] = true
    local ok, result = pcall(handle, player, action, first, second, third)
    activeRequests[player] = nil
    if not ok then
        warn("[OPERAÇÃO RIO] Falha ao processar solicitação", action, result)
        return { Message = "A operação falhou. Tente novamente." }
    end
    return result
end
request.Parent = ReplicatedStorage

Players.PlayerRemoving:Connect(function(player)
    nextRequest[player] = nil
end)
