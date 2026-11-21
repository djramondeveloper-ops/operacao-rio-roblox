local Inventory = modules.Inventory
local Rules = modules.InventoryRules
local Schema = modules.ProfileSchema
local Appearance = modules.Appearance
local Economy = modules.Economy
local Careers = modules.Careers

local tests = 0
local function test(name, execute)
    local ok, reason = pcall(execute)
    assert(ok, name .. ": " .. tostring(reason))
    tests += 1
end

local look = { Skin = 1, Hair = 1, Face = 1, Outfit = 1, Accessory = 1 }
local function character(id)
    return Schema.NewCharacter(id, "Lucas", "Silva", look)
end

test("migra versão 1 e preserva bens somente no primeiro personagem", function()
    local account = Schema.Decode({
        Version = 1, Team = "aurora", Slots = { ["7"] = { Id = "radio", Count = 1 } },
    })
    assert(account.Version == 2 and #account.Characters == 0)
    local first = Schema.NewCharacter("primeiro", "Lucas", "Silva", look, account.Legacy)
    local second = character("segundo")
    assert(first.Team == "aurora" and first.Slots["7"].Id == "radio")
    assert(second.Team == "civil" and second.Slots["7"] == nil)
end)

test("separa personagens e valida identidade e permissões", function()
    local first, second = character("a"), character("b")
    active.user = first
    assert(Inventory.Move("user", 1, 3, 1))
    assert(first.Slots["3"].Count == 1 and second.Slots["3"] == nil)
    assert(not Careers.CanJoin({ UserId = 10 }, "bope"))
    assert(not Inventory.Grant("user", "escudo", 1))
    assert(not Inventory.Move("outro", 1, 2))
    assert(not Appearance.Sanitize({ Skin = 99 }))
    assert(not Schema.Decode({ Version = 2, Characters = { first, first } }))
end)

test("rejeita slots inválidos e preserva a soma de pilhas", function()
    local data = character("a")
    active.user = data
    assert(not Inventory.Move("user", 1.5, 3))
    assert(not Inventory.Move("user", 1, 100))
    assert(not Inventory.Move("user", 1, 2, 1))
    assert(Inventory.Move("user", 1, 3, 1))
    assert(Inventory.Move("user", 3, 1))
    assert(data.Slots["1"].Count == 2 and data.Slots["3"] == nil)
    assert(Rules.Weight(data.Slots) == 1250)
end)

test("concessão sem capacidade deixa slots intactos", function()
    local data = character("a")
    assert(not Rules.Grant(data, "lanche", 1000))
    assert(data.Slots["2"].Count == 1)
    for index = 3, 12 do
        data.Slots[tostring(index)] = { Id = "documento", Count = 1 }
    end
    assert(not Rules.Grant(data, "documento", 1))
    assert(Rules.Validate(data))
end)

test("mochila não pode ser retirada com slots extras ocupados", function()
    local data = character("a")
    active.user = data
    assert(Rules.Grant(data, "mochila", 1))
    assert(Inventory.Action("user", "use", 3))
    assert(Inventory.Move("user", 1, 13))
    assert(not Inventory.Action("user", "use", 3))
    assert(not Inventory.Action("user", "discard", 3, 1))
    assert(data.Backpack and Rules.Validate(data))
    assert(Inventory.Move("user", 13, 1))
    assert(Inventory.Action("user", "use", 3))
    assert(not data.Backpack)
end)

test("transações rejeitam replay, saldo negativo e valores inválidos", function()
    local data = character("a")
    assert(Economy.Apply(data, 1, "deposit", 30))
    assert(not Economy.Apply(data, 1, "deposit", 30))
    assert(not Economy.Apply(data, 3, "withdraw", 8))
    assert(not Economy.Apply(data, 2, "withdraw", 31))
    assert(not Economy.Apply(data, 2, "withdraw", 0 / 0))
    assert(Economy.Apply(data, 2, "withdraw", 5))
    assert(data.Bank == 25 and data.Cash == 125)
    assert(Economy.ValidLedger(data))
end)

test("candidato rejeitado não consome dinheiro nem itens do perfil original", function()
    local original = character("a")
    local candidate = Schema.Copy(original)
    assert(Rules.Grant(candidate, "radio", 1))
    assert(not Economy.Apply(candidate, 1, "purchase", 151))
    assert(original.Cash == 150 and original.Slots["3"] == nil)
    assert(candidate.Slots["3"].Durability == 100)
    assert(Schema.Decode({ Version = 2, Characters = { original } }))
end)

return tests
