local modules = {}
local records, online, bans, characters, instances = {}, {}, {}, {}, {}
local failStore = false
local uncertainCommit = false
local time = 100
local guid = 0
local suspendedWrite
local function require(name)
    return assert(modules[name], tostring(name))
end
local players = {
    BanningEnabled = true,
    PlayerRemoving = { Connect = function() end },
    GetPlayerByUserId = function(_, userId) return online[userId] end,
    GetPlayers = function()
        local result = {}
        for _, player in pairs(online) do
            table.insert(result, player)
        end
        return result
    end,
    BanAsync = function(_, config) bans[config.UserIds[1]] = config end,
    UnbanAsync = function(_, config) bans[config.UserIds[1]] = nil end,
}
local store = {
    GetAsync = function(_, key)
        assert(not failStore, "DataStore indisponível")
        return records[key]
    end,
    UpdateAsync = function(_, key, apply)
        assert(not failStore, "DataStore indisponível")
        if suspendedWrite and key == "audit_v1" then
            suspendedWrite = false
            coroutine.yield()
        end
        local value = apply(records[key])
        if value ~= nil then
            records[key] = value
        end
        return value
    end,
}
local replication = { Shared = { Items = "Items", AdminCatalog = "AdminCatalog" } }
local services = {
    Players = players, ReplicatedStorage = replication,
    HttpService = { GenerateGUID = function() guid += 1; return tostring(guid) end },
    DataStoreService = { GetDataStore = function() return store end },
    RunService = { IsStudio = function() return false end },
    TextChatService = { ChatVersion = "Legacy" },
    TextService = { FilterStringAsync = function(_, value)
        return { GetNonChatStringForBroadcastAsync = function() return value end }
    end },
}
local game = { GetService = function(_, name) return assert(services[name]) end }
local serviceModules = { Profiles = "Profiles", Inventory = "Inventory", InventoryRules = "InventoryRules",
    Economy = "Economy", Careers = "Careers", Teams = "Teams", Characters = "Characters" }
local adminModules = { Parent = { Services = serviceModules } }
for _, name in ipairs({ "Config", "Permissions", "Persistence", "Audit", "Arguments", "Moderation", "Commands",
    "Actions", "Service", "City" }) do
    adminModules[name] = name
end
adminModules.Profiles = "Profiles"
adminModules.Careers = "Careers"
adminModules.InventoryRules = "InventoryRules"
local script = { Parent = adminModules }
local Instance = { new = function(class)
    local object = { FireClient = function() end }
    instances[class] = object
    return object
end }
local Enum = { ChatVersion = { TextChatService = "Modern" }, TextFilterContext = { PublicChat = 1 } }
local os = { time = function() return time end, clock = function() return time end }
local task = { spawn = function(fn) fn() end }
local warn = function() end
services.HttpService.GenerateGUID = function()
    guid += 1
    return "op" .. tostring(guid)
end

local function copy(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, child in pairs(value) do
        result[key] = copy(child)
    end
    return result
end

modules.Profiles = {
    Get = function(player) return characters[player.UserId] end,
    Commit = function(player, apply)
        local data = copy(characters[player.UserId])
        local accepted, message = apply({ Characters = { data } })
        if accepted then
            characters[player.UserId] = data
            if uncertainCommit then
                return false, "Gravação indisponível.", true
            end
        end
        return accepted, message
    end,
}
modules.Careers = {
    CanJoin = function(_, organization) return organization == "civil" end,
    Enter = function(character, organization) character.Team = organization end,
}
modules.Teams = { Restore = function(player, character) player.Team = character.Team end }
modules.Characters = { PublishIdentity = function() end }
modules.City = { Start = function() end, Apply = function() return true, "Enviado." end }
