local tests = 0
local function test(name, run)
    local ok, reason = pcall(run)
    assert(ok, name .. ": " .. tostring(reason))
    tests += 1
end
local function player(id)
    local result = { UserId = id, Name = "Conta" .. tostring(id), Parent = players,
        SetAttribute = function() end, Kick = function(self) self.Kicked = true end }
    online[id] = result
    return result
end
local founder, ordinary, director, admin, other = player(11), player(12), player(13), player(14), player(15)
local config = modules.Config
local permissions = modules.Permissions
config.FounderUserIds[founder.UserId] = true
records.roles_v1 = { ["13"] = "DIRECTOR", ["14"] = "ADMIN" }
modules.Service.Start()
local function call(actor, action, payload)
    time += 1
    return instances.RemoteFunction.OnServerInvoke(actor, action, payload)
end
local function confirm(actor, action, payload)
    local pending = call(actor, action, payload)
    assert(pending.Token, pending.Message)
    return call(actor, "confirm", pending.Token), pending.Token
end

test("fundador configurado e jogador comum", function()
    assert(call(founder, "open").Role == "FOUNDER")
    assert(not call(ordinary, "open").Ok)
    assert(permissions.Role(99, { ["99"] = "FOUNDER" }) == nil)
    config.FounderUserIds[founder.UserId] = nil
    assert(not permissions.Role(director.UserId, records.roles_v1))
    config.FounderUserIds[founder.UserId] = true
end)
test("atribuição persiste e hierarquia protege fundador e autoelevação", function()
    assert(confirm(founder, "role", { Target = other.UserId, Key = "SUPPORT" }).Ok)
    assert(records.roles_v1["15"] == "SUPPORT")
    assert(call(other, "open").Role == "SUPPORT")
    assert(not call(admin, "role", { Target = ordinary.UserId, Key = "ADMIN" }).Ok)
    assert(not call(director, "role", { Target = director.UserId, Key = "FOUNDER" }).Ok)
    assert(not call(director, "role", { Target = founder.UserId, Key = "NONE" }).Ok)
    assert(not call(director, "role", { Target = ordinary.UserId, Key = "DIRECTOR" }).Ok)
end)
test("servidor ignora cargo alegado e rejeita parâmetros adulterados", function()
    assert(not call(ordinary, "kick", { Target = other.UserId, Text = "Motivo", Role = "FOUNDER" }).Ok)
    assert(not call(founder, { "kick" }, {}).Ok)
    assert(not call(founder, "kick", { Target = {}, Text = "Motivo" }).Ok)
    assert(not call(founder, "ban", { Target = ordinary.UserId, Value = 0, Text = "Motivo" }).Ok)
    assert(not call(founder, "confirm", "inventado").Ok)
    assert(instances.RemoteEvent.OnServerEvent == nil)
end)
test("banimento temporário, permanente, revogação e proteção de superior", function()
    assert(confirm(admin, "ban", { Target = ordinary.UserId, Text = "Regra", Value = 2 }).Ok)
    assert(bans[ordinary.UserId].Duration == 172800 and bans[ordinary.UserId].ExcludeAltAccounts)
    assert(confirm(admin, "unban", { Target = ordinary.UserId, Text = "Revisão" }).Ok)
    assert(bans[ordinary.UserId] == nil)
    assert(confirm(founder, "ban", { Target = 1000, Text = "Regra", Value = -1 }).Ok)
    assert(bans[1000].Duration == -1)
    assert(not call(admin, "ban", { Target = founder.UserId, Text = "Regra", Value = 1 }).Ok)
    local history = call(admin, "history", { Target = ordinary.UserId })
    assert(#history.Audit == 2 and history.Audit[1].Action == "unban")
end)
test("saldo, inventário, equipe e proteção contra reenvio", function()
    characters[ordinary.UserId] = { Id = "role", Slots = {}, Cash = 150, Bank = 0, Team = "civil", Careers = {} }
    local result, ticket = confirm(founder, "givemoney", { Target = ordinary.UserId, Value = 25 })
    assert(result.Ok and not call(founder, "confirm", ticket).Ok)
    assert(characters[ordinary.UserId].Cash == 175)
    assert(confirm(founder, "setmoney", { Target = ordinary.UserId, Value = 100 }).Ok)
    assert(confirm(founder, "giveitem", { Target = ordinary.UserId, Key = "agua", Value = 2 }).Ok)
    assert(characters[ordinary.UserId].Slots["1"].Count == 2)
    assert(confirm(founder, "removeitem", { Target = ordinary.UserId, Slot = 1, Value = 1 }).Ok)
    assert(characters[ordinary.UserId].Slots["1"].Count == 1)
    assert(not confirm(founder, "setteam", { Target = ordinary.UserId, Key = "bope" }).Ok)
    assert(confirm(founder, "setteam", { Target = ordinary.UserId, Key = "civil" }).Ok)
end)
test("confirmação não segue o alvo para outro personagem", function()
    local pending = call(founder, "givemoney", { Target = ordinary.UserId, Value = 25 })
    characters[ordinary.UserId].Id = "outro"
    assert(not call(founder, "confirm", pending.Token).Ok)
    assert(characters[ordinary.UserId].Cash == 100)
    characters[ordinary.UserId].Id = "role"
end)
test("DataStore indisponível sem efeitos administrativos", function()
    local pending = call(founder, "givemoney", { Target = ordinary.UserId, Value = 30 })
    failStore = true
    assert(not call(founder, "confirm", pending.Token).Ok)
    failStore = false
    assert(characters[ordinary.UserId].Cash == 100)
end)
test("comandos inválidos e sintaxe inequívoca", function()
    local args = modules.Commands.Parse("ban", "12 3 Fraude em evento")
    assert(args.Target == 12 and args.Value == 3 and args.Text == "Fraude em evento")
    assert(not modules.Arguments.Parse("ban", modules.Commands.Parse("ban", "Nome 3 abc")))
    assert(not modules.Commands.Parse("goto", "12 surpreender"))
end)
test("duas ações simultâneas para o mesmo alvo", function()
    local pending = call(founder, "givemoney", { Target = ordinary.UserId, Value = 25 })
    suspendedWrite = true
    local worker = coroutine.create(function()
        assert(call(founder, "confirm", pending.Token).Ok)
    end)
    assert(coroutine.resume(worker))
    local overlapping = confirm(admin, "kick", { Target = ordinary.UserId, Text = "Motivo" })
    assert(not overlapping.Ok and not ordinary.Kicked)
    local ok, reason = coroutine.resume(worker)
    assert(ok, tostring(reason))
    assert(characters[ordinary.UserId].Cash == 125)
end)
return tests
