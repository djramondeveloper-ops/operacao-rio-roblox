local RobloxTeams = game:GetService("Teams")
local RunService = game:GetService("RunService")
local Config = require(game:GetService("ReplicatedStorage").Shared.TeamsConfig)
local Profiles = require(script.Parent.Profiles)
local Settings = require(script.Parent.Parent.Settings)

local Teams = {}
local instances = {}

local function canJoin(player, team)
    local allowlist = Settings.PoliceAccess[team.Id]
    return team.Public == true or RunService:IsStudio() or (allowlist and allowlist[player.UserId] == true)
end

function Teams.Start()
    for _, team in ipairs(Config) do
        local instance = RobloxTeams:FindFirstChild(team.Name)
        if not instance then
            instance = Instance.new("Team")
            instance.Name = team.Name
        end
        assert(instance:IsA("Team"), "Conflito no serviço Teams: " .. team.Name)
        instance.TeamColor = BrickColor.new(team.Color)
        instance.AutoAssignable = false
        instance.Parent = RobloxTeams
        instances[team.Id] = instance
    end
end

function Teams.Available(player)
    local result = {}
    for _, team in ipairs(Config) do
        result[team.Id] = canJoin(player, team) == true
    end
    return result
end

local function apply(player, data, id)
    player.Team = instances[id]
    player.Neutral = false
    data.Team = id
end

function Teams.Restore(player, data)
    local id = data.Team
    if not Teams.Available(player)[id] then
        id = "civil"
    end
    apply(player, data, id)
end

function Teams.Select(player, id)
    local data = Profiles.Get(player)
    if not data then
        return false, "Perfil indisponível."
    end
    if type(id) ~= "string" or not Teams.Available(player)[id] then
        return false, "Equipe indisponível para sua conta."
    end
    apply(player, data, id)
    return true, "Equipe atualizada."
end

return Teams
