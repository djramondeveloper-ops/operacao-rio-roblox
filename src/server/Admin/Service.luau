local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Catalog = require(ReplicatedStorage.Shared.AdminCatalog)
local Config = require(script.Parent.Config)
local Permissions = require(script.Parent.Permissions)
local Persistence = require(script.Parent.Persistence)
local Audit = require(script.Parent.Audit)
local Arguments = require(script.Parent.Arguments)
local Actions = require(script.Parent.Actions)
local City = require(script.Parent.City)
local Moderation = require(script.Parent.Moderation)
local Commands = require(script.Parent.Commands)

local Service = {}
local nextRequest, busy, lastDenied, tickets, targetBusy = {}, {}, {}, {}, {}
local confirmation = {}
local lookup
local lookupExpires = 0
local lookupInFlight = false
local nextAuditDenial = 0
local signal
for _, tab in ipairs(Catalog) do
    for index = 2, #tab do
        local item = tab[index]
        confirmation[item[1]] = item[4] == true
    end
end

local function roles()
    local record = Persistence.Read("roles_v1")
    assert(record == nil or type(record) == "table", "Escala administrativa inválida")
    return record or {}
end

local function discoverRoles()
    local now = os.clock()
    if lookup and now < lookupExpires then
        return lookup
    end
    if lookupInFlight then
        return nil
    end
    lookupInFlight = true
    local ok, result = pcall(roles)
    lookupInFlight = false
    if not ok then
        error(result)
    end
    lookup, lookupExpires = result, now + 10
    return lookup
end

local function roleChange(actor, args)
    local key = tostring(args.Target)
    local newRoles = Persistence.Update("roles_v1", function(old)
        assert(old == nil or type(old) == "table", "Escala administrativa inválida")
        old = old or {}
        if not Permissions.CanAssign(actor.UserId, args.Target, args.Key, old) then
            return nil
        end
        local updated = table.clone(old)
        updated[key] = if args.Key == "NONE" then nil else args.Key
        return updated
    end)
    if not newRoles then
        return false, "Alteração de cargo recusada."
    end
    lookupExpires = 0
    local target = Players:GetPlayerByUserId(args.Target)
    if target and signal then
        signal:FireClient(target, "roleChanged")
    end
    return true, "Cargo atualizado."
end

local function entry(player, action, args, id)
    return {
        Id = id or HttpService:GenerateGUID(false),
        At = os.time(),
        Actor = player.UserId,
        Target = args.Target,
        Action = action,
        Value = args.Value,
        Key = args.Key,
        Slot = args.Slot,
        Reason = if action == "announce" then nil else args.Text,
    }
end

local function denied(player, action, args)
    local now = os.clock()
    if now >= (lastDenied[player] or -1) and now >= nextAuditDenial then
        lastDenied[player] = now + 60
        nextAuditDenial = now + 3
        task.spawn(function()
            local row = entry(player, action, args)
            row.Result = "denied"
            if not pcall(Audit.Write, row) then
                warn("[OPERAÇÃO RIO] Falha ao registrar tentativa administrativa recusada", player.UserId)
            end
        end)
    end
    return { Ok = false, Message = "Acesso negado." }
end

local function open(role)
    local available = {}
    for action in pairs(Config.Permissions) do
        if Permissions.Allows(role, action) then
            available[action] = true
        end
    end
    local players = {}
    for _, player in ipairs(Players:GetPlayers()) do
        table.insert(players, { UserId = player.UserId, Name = player.Name })
    end
    table.sort(players, function(a, b) return a.Name < b.Name end)
    return { Ok = true, Role = role, Available = available, Players = players }
end

local function handle(player, action, payload)
    if type(action) ~= "string" or #action > 32 then
        return denied(player, "invalid", {})
    end
    if action ~= "open" and action ~= "confirm" and action ~= "cancel" and confirmation[action] == nil then
        return denied(player, "invalid", {})
    end
    local id = player.UserId
    local discovery = discoverRoles()
    if not discovery then
        return { Ok = false, Message = "Consultando permissões. Tente novamente." }
    end
    if not Permissions.Role(id, discovery) then
        if action ~= "open" then
            return denied(player, if confirmation[action] ~= nil then action else "invalid", {})
        end
        return { Ok = false, Message = "Acesso negado." }
    end
    local roleMap = roles()
    local role = Permissions.Role(id, roleMap)
    if not role then
        -- O cliente consulta disponibilidade ao iniciar, inclusive em sessões públicas.
        if action == "open" then
            return { Ok = false, Message = "Acesso negado." }
        end
        return denied(player, if confirmation[action] ~= nil then action else "invalid", {})
    end
    if action == "open" then
        return open(role)
    end

    local args
    local token
    if action == "confirm" then
        local pending = tickets[player]
        if type(payload) ~= "string" or not pending or pending.Token ~= payload or pending.Expiry <= os.clock() then
            return { Ok = false, Message = "Confirmação inválida ou expirada." }
        end
        tickets[player] = nil
        action, args, token = pending.Action, pending.Args, pending.Token
    elseif action == "cancel" then
        tickets[player] = nil
        return { Ok = true, Message = "Operação cancelada." }
    end
    if confirmation[action] == nil or not Permissions.Allows(role, action) then
        return denied(player, if confirmation[action] ~= nil then action else "invalid", {})
    end
    args = args or Arguments.Parse(action, payload)
    if not args then
        return { Ok = false, Invalid = true, Message = "Parâmetros inválidos. Confira a sintaxe." }
    end
    if args.Target and action ~= "logs" and not Permissions.CanTarget(id, args.Target, roleMap) then
        return denied(player, action, { Target = args.Target })
    end
    if action == "role" and not Permissions.CanAssign(id, args.Target, args.Key, roleMap) then
        return denied(player, action, { Target = args.Target })
    end
    if confirmation[action] and not token then
        token = HttpService:GenerateGUID(false)
        tickets[player] = { Token = token, Action = action, Args = args, Expiry = os.clock() + 30 }
        return { Ok = true, Token = token, Message = "Confirme a ação " .. action .. "." }
    end

    if action == "logs" or action == "history" then
        local rows, more = Audit.Read(args.Target, args.Key, args.Page, action == "history")
        return { Ok = true, Audit = rows, More = more, Message = "Registros consultados." }
    end
    if args.Text then
        args.Text = Moderation.Filter(player, args.Text)
        if not args.Text then
            return { Ok = false, Message = "O texto não passou pela filtragem." }
        end
    end

    local targetId = args.Target
    if targetId and targetBusy[targetId] then
        return { Ok = false, Message = "Outra ação administrativa está em andamento para este alvo." }
    end
    if targetId then
        targetBusy[targetId] = true
    end
    local completed, response = pcall(function()
        local row = entry(player, action, args, token)
        row.Result = "pending"
        Audit.Write(row)
        local current = roles()
        local authorized = player.Parent == Players and Permissions.Allows(Permissions.Role(id, current), action)
            and (not args.Target or Permissions.CanTarget(id, args.Target, current))
        if not authorized then
            local refusal = table.clone(row)
            refusal.Result = "denied"
            Audit.Write(refusal)
            return { Ok = false, Message = "Permissão alterada antes da execução." }
        end
        local invoke = if action == "role" then function() return roleChange(player, args) end
            else function() return Actions.Run(player, action, args, row.Id) end
        local ok, success, message, data = pcall(invoke)
        row = table.clone(row)
        row.Result = if not ok then "uncertain" elseif success then "ok" else "failed"
        local logged = pcall(Audit.Write, row)
        if not logged then
            warn("[OPERAÇÃO RIO] Não foi possível confirmar o resultado da ação", row.Id)
            return { Ok = false, Message = "Resultado da auditoria indisponível. Confira antes de repetir." }
        end
        if not ok then
            warn("[OPERAÇÃO RIO] Falha na ação administrativa", action, row.Id)
            return { Ok = false, Message = "Resultado indisponível. Confira o estado antes de repetir." }
        end
        local output = data or {}
        output.Ok, output.Message = success, message
        return output
    end)
    if targetId then
        targetBusy[targetId] = nil
    end
    if not completed then
        error(response)
    end
    return response
end

local function dispatch(player, action, payload)
    local now = os.clock()
    if busy[player] or now < (nextRequest[player] or 0) then
        return { Ok = false, Message = "Aguarde antes de tentar novamente." }
    end
    nextRequest[player] = now + 0.5
    busy[player] = true
    local ok, result = pcall(handle, player, action, payload)
    busy[player] = nil
    if not ok then
        warn("[OPERAÇÃO RIO] Serviço administrativo indisponível")
        return { Ok = false, Message = "Serviço administrativo indisponível." }
    end
    return result
end

function Service.Start()
    local folder = Instance.new("Folder")
    folder.Name = "OperacaoRioAdmin"
    local request = Instance.new("RemoteFunction")
    request.Name = "Request"
    request.OnServerInvoke = dispatch
    request.Parent = folder
    signal = Instance.new("RemoteEvent")
    signal.Name = "Signal"
    signal.Parent = folder
    -- Canal exclusivamente servidor → cliente. Nenhum receptor executa pedidos neste evento.
    folder.Parent = ReplicatedStorage
    City.Start(signal)
    Commands.Start(Catalog, dispatch, signal, function(player)
        return tickets[player] and tickets[player].Token
    end)
    Players.PlayerRemoving:Connect(function(player)
        nextRequest[player], busy[player], lastDenied[player], tickets[player] = nil, nil, nil, nil
    end)
end

return Service
