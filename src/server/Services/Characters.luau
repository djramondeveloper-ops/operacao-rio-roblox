local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local Appearance = require(game:GetService("ReplicatedStorage").Shared.Appearance)
local Profiles = require(script.Parent.Profiles)
local Schema = require(script.Parent.ProfileSchema)
local Teams = require(script.Parent.Teams)
local Careers = require(script.Parent.Careers)

local Characters = {}
local deathConnections = {}

local function find(account, id)
    if type(id) == "string" and #id == 36 then
        for index, character in ipairs(account.Characters) do
            if character.Id == id then
                return character, index
            end
        end
    end
    return nil, nil
end

local function validName(value)
    if type(value) ~= "string" or #value > 64 or value:find("[%c%s%d%p]") then
        return false
    end
    local length = utf8.len(value)
    return length ~= nil and length >= 2 and length <= 18
end

local function filterName(player, value)
    local result = TextService:FilterStringAsync(value, player.UserId, Enum.TextFilterContext.PublicChat)
    return result:GetNonChatStringForBroadcastAsync()
end

function Characters.List(player)
    local account = Profiles.GetAccount(player)
    if not account then
        return nil
    end
    local result = {}
    for _, character in ipairs(account.Characters) do
        table.insert(result, {
            Id = character.Id,
            Name = character.First .. " " .. character.Last,
            Appearance = character.Appearance,
            Rank = Careers.Title(character),
        })
    end
    return result
end

function Characters.Create(player, first, last, options)
    local account = Profiles.GetAccount(player)
    if not account or #account.Characters >= 3 then
        return false, "Não há vaga disponível."
    end
    local appearance = Appearance.Sanitize(options)
    if not appearance or not validName(first) or not validName(last) then
        return false, "Use nome e sobrenome de 2 a 18 letras, sem espaços."
    end
    local ok, filteredFirst, filteredLast = pcall(function()
        return filterName(player, first), filterName(player, last)
    end)
    if not ok or not validName(filteredFirst) or not validName(filteredLast) then
        return false, "O nome não pôde ser aprovado. Tente outro nome."
    end

    local id = HttpService:GenerateGUID(false)
    return Profiles.Commit(player, function(candidate)
        if #candidate.Characters >= 3 then
            return false, "As três vagas estão ocupadas."
        end
        for _, character in ipairs(candidate.Characters) do
            if character.First == filteredFirst and character.Last == filteredLast then
                return false, "Este nome já pertence a um personagem da conta."
            end
        end
        table.insert(candidate.Characters, Schema.NewCharacter(
            id, filteredFirst, filteredLast, appearance, candidate.Legacy
        ))
        candidate.Legacy = nil
        return true, "Personagem salvo."
    end)
end

function Characters.Delete(player, id, confirmed)
    if confirmed ~= true or Profiles.Get(player) then
        return false, "Confirme a exclusão no menu de personagens."
    end
    return Profiles.Commit(player, function(account)
        local _, index = find(account, id)
        if not index then
            return false, "Personagem indisponível."
        end
        table.remove(account.Characters, index)
        return true, "Personagem excluído."
    end)
end

function Characters.PublishIdentity(player)
    local character = Profiles.Get(player)
    if not character then
        return
    end
    player:SetAttribute("RoleName", character.First .. " " .. character.Last)
    player:SetAttribute("RoleRank", Careers.Title(character))
    player:SetAttribute("RoleCash", character.Cash)
    player:SetAttribute("RoleArmor", 0)
    player:SetAttribute("ActiveCharacterId", character.Id)
end

local function clearDeath(player)
    if deathConnections[player] then
        deathConnections[player]:Disconnect()
        deathConnections[player] = nil
    end
end

local function spawnCharacter(player, character)
    clearDeath(player)
    Teams.Restore(player, character)
    local description = Appearance.Description(character.Appearance)
    local ok, reason = pcall(function()
        player:LoadCharacterWithHumanoidDescriptionAsync(description)
    end)
    description:Destroy()
    local model = player.Character
    local humanoid = model and model:FindFirstChildOfClass("Humanoid")
    if not ok or not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
        warn("[OPERAÇÃO RIO] Falha ao criar avatar R15", player.UserId, reason)
        if model then
            model:Destroy()
        end
        return false
    end
    Appearance.Apply(model, character.Appearance)
    humanoid.DisplayName = character.First .. " " .. character.Last
    deathConnections[player] = humanoid.Died:Once(function()
        task.delay(Players.RespawnTime, function()
            local active = Profiles.Get(player)
            if player.Parent == Players and active and active.Id == character.Id then
                if not spawnCharacter(player, active) and player.Parent == Players then
                    Characters.ReturnToMenu(player)
                end
            end
        end)
    end)
    return true
end

function Characters.Select(player, id)
    local account = Profiles.GetAccount(player)
    if not account or Profiles.Get(player) then
        return false, "Volte ao menu antes de selecionar outro personagem."
    end
    local character = find(account, id)
    if not character or not Profiles.SetActive(player, id) then
        return false, "Personagem indisponível."
    end
    if not spawnCharacter(player, character) then
        Characters.ReturnToMenu(player)
        return false, "Falha ao carregar avatar R15. Tente novamente."
    end
    Characters.PublishIdentity(player)
    return true, "Bem-vindo à cidade."
end

function Characters.ReturnToMenu(player)
    clearDeath(player)
    Profiles.SetActive(player, nil)
    for _, attribute in ipairs({ "ActiveCharacterId", "RoleName", "RoleRank", "RoleCash", "RoleArmor" }) do
        player:SetAttribute(attribute, nil)
    end
    if player.Character then
        player.Character:Destroy()
    end
    Teams.Clear(player)
    return true, "Selecione um personagem."
end

function Characters.Start()
    Players.PlayerRemoving:Connect(clearDeath)
end

return Characters
