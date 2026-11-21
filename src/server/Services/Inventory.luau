local Items = require(game:GetService("ReplicatedStorage").Shared.Items)
local Profiles = require(script.Parent.Profiles)
local Careers = require(script.Parent.Careers)
local Rules = require(script.Parent.InventoryRules)

local Inventory = { Weight = Rules.Weight, Limits = Rules.Limits }

function Inventory.CanHandle(player, data, definition)
    if not definition.PoliceOnly then
        return true
    end
    local team = data.Team
    return (team == "pmerj" or team == "bope") and Careers.CanJoin(player, team)
        and (not definition.Organization or team == definition.Organization)
        and (data.Careers[team] or 0) >= (definition.Rank or 1)
end

function Inventory.Move(player, fromIndex, toIndex, quantity)
    local data = Profiles.Get(player)
    if not data then
        return false, "Personagem indisponível."
    end
    local from = Rules.Index(data, fromIndex)
    local to = Rules.Index(data, toIndex)
    if not from or not to or from == to then
        return false, "Selecione dois slots diferentes."
    end
    local source = data.Slots[from]
    local target = data.Slots[to]
    if not source then
        return false, "O slot de origem está vazio."
    end

    local maximum = Items.Catalog[source.Id].Stack
    if quantity ~= nil then
        if type(quantity) ~= "number" or quantity % 1 ~= 0 or quantity < 1 or quantity >= source.Count
            or target then
            return false, "Divida uma pilha usando um slot vazio."
        end
        data.Slots[to] = { Id = source.Id, Count = quantity }
        source.Count -= quantity
    elseif target and target.Id == source.Id and maximum > 1 then
        local moved = math.min(source.Count, maximum - target.Count)
        if moved == 0 then
            return false, "A pilha de destino está cheia."
        end
        target.Count += moved
        source.Count -= moved
        if source.Count == 0 then
            data.Slots[from] = nil
        end
    else
        data.Slots[from], data.Slots[to] = target, source
    end
    return true, "Inventário atualizado."
end

function Inventory.Grant(player, itemId, quantity)
    local data = Profiles.Get(player)
    local definition = if type(itemId) == "string" then Items.Catalog[itemId] else nil
    return data ~= nil and definition ~= nil and Inventory.CanHandle(player, data, definition)
        and Rules.Grant(data, itemId, quantity)
end

function Inventory.Discard(data, key, amount)
    local slot = data.Slots[key]
    if not slot or type(amount) ~= "number" or amount % 1 ~= 0 or amount < 1 or amount > slot.Count then
        return false, "Quantidade inválida."
    end
    slot.Count -= amount
    if slot.Count == 0 then
        data.Slots[key] = nil
    end
    if not Rules.Validate(data) then
        slot.Count += amount
        data.Slots[key] = slot
        return false, "Retire a mochila equipada antes de removê-la e libere espaço."
    end
    return true, "Item removido."
end

function Inventory.Action(player, operation, index, amount)
    local data = Profiles.Get(player)
    local key = data and Rules.Index(data, index)
    local slot = key and data.Slots[key]
    if not slot then
        return false, "Item indisponível."
    end
    if operation == "discard" then
        return Inventory.Discard(data, key, amount)
    end

    local definition = Items.Catalog[slot.Id]
    if not Inventory.CanHandle(player, data, definition) then
        return false, "Equipamento reservado à carreira autorizada."
    end
    if slot.Id == "mochila" then
        local previous = data.Backpack
        data.Backpack = not previous
        if not Rules.Validate(data) then
            data.Backpack = previous
            return false, "Libere peso e os slots adicionais antes de retirar a mochila."
        end
        return true, if data.Backpack then "Mochila equipada." else "Mochila retirada."
    end
    if definition.Heal then
        local model = player.Character
        local humanoid = model and model:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 or humanoid.Health >= humanoid.MaxHealth then
            return false, "Use o kit quando estiver ferido e consciente."
        end
        local consumed, reason = Inventory.Discard(data, key, 1)
        if not consumed then
            return false, reason
        end
        humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + definition.Heal)
        return true, "Kit médico usado."
    end
    return false, "Este item ainda não tem uma ação de uso."
end

return Inventory
