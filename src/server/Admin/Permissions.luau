local Config = require(script.Parent.Config)
local Permissions = {}
local rank = { SUPPORT = 1, MODERATOR = 2, ADMIN = 3, DIRECTOR = 4, FOUNDER = 5 }

function Permissions.UserId(id)
    return type(id) == "number" and id >= 1 and id <= 9007199254740991 and id % 1 == 0
end

function Permissions.Role(id, roles)
    if not Permissions.UserId(id) then
        return nil
    end
    if type(Config.FounderUserIds) == "table" and Config.FounderUserIds[id] == true then
        return "FOUNDER"
    end
    local role = roles[tostring(id)]
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
