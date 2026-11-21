local Config = require(script.Parent.Config)
local Permissions = {}
local rank = { SUPPORT = 1, MODERATOR = 2, ADMIN = 3, DIRECTOR = 4, FOUNDER = 5 }

function Permissions.UserId(id)
    return type(id) == "number" and id >= 1 and id <= 9007199254740991 and id % 1 == 0
end

local function configured()
    if type(Config.FounderUserIds) ~= "table" then
        return false
    end
    local found = false
    for id, enabled in pairs(Config.FounderUserIds) do
        if not Permissions.UserId(id) or enabled ~= true then
            return false
        end
        found = true
    end
    return found
end

function Permissions.Role(id, roles)
    if not Permissions.UserId(id) or not configured() then
        return nil
    end
    if Config.FounderUserIds[id] == true then
        return "FOUNDER"
    end
    local role = roles[string.format("%.0f", id)]
    return if role ~= "FOUNDER" and rank[role] then role else nil
end

function Permissions.Allows(role, action)
    local minimum = rank[Config.Permissions[action]]
    return minimum ~= nil and rank[role] ~= nil and rank[role] >= minimum
end

function Permissions.CanTarget(actorId, targetId, roles)
    local actor = Permissions.Role(actorId, roles)
    local target = Permissions.Role(targetId, roles)
    return actorId ~= targetId and rank[actor] ~= nil and rank[actor] > (rank[target] or 0)
end

local selfActions = {
    heal = true, revive = true, god = true, setteam = true,
    balance = true, inventory = true, setmoney = true, givemoney = true,
    removemoney = true, giveitem = true, removeitem = true,
}

function Permissions.CanActOn(actorId, targetId, roles, action)
    if actorId == targetId then
        return selfActions[action] == true
            and (action == "heal" or action == "revive" or action == "god"
                or Permissions.Role(actorId, roles) == "FOUNDER")
    end
    return Permissions.CanTarget(actorId, targetId, roles)
end

function Permissions.CanAssign(actorId, targetId, nextRole, roles)
    if not Permissions.CanTarget(actorId, targetId, roles) then
        return false
    end
    local actor = Permissions.Role(actorId, roles)
    local target = Permissions.Role(targetId, roles)
    if nextRole == "FOUNDER" or (nextRole ~= "NONE" and not rank[nextRole]) then
        return false
    end
    if actor == "FOUNDER" then
        return true
    end
    -- Opcionalmente, um diretor pode conceder o próprio nível a um subordinado.
    if actor == "DIRECTOR" and nextRole == "DIRECTOR" then
        return Config.AllowDirectorDelegation == true
    end
    return actor == "DIRECTOR" and target ~= "DIRECTOR" and nextRole ~= "DIRECTOR"
end

return Permissions
