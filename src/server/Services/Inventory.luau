local Items = require(game:GetService("ReplicatedStorage").Shared.Items)
local Profiles = require(script.Parent.Profiles)

local Inventory = {}

local function validIndex(index)
    return type(index) == "number" and index % 1 == 0 and index >= 1 and index <= Items.Slots
end

function Inventory.Weight(slots)
    local grams = 0
    for _, slot in pairs(slots) do
        grams += Items.Catalog[slot.Id].Grams * slot.Count
    end
    return grams
end

function Inventory.Move(player, fromIndex, toIndex)
    local data = Profiles.Get(player)
    if not data then
        return false, "Perfil indisponível."
    end
    if not validIndex(fromIndex) or not validIndex(toIndex) or fromIndex == toIndex then
        return false, "Selecione dois slots diferentes."
    end

    local fromKey = tostring(fromIndex)
    local toKey = tostring(toIndex)
    local slots = data.Slots
    local source = slots[fromKey]
    local destination = slots[toKey]
    if not source then
        return false, "O slot de origem está vazio."
    end
    if destination and destination.Id == source.Id then
        local quantity = math.min(source.Count, Items.Catalog[source.Id].Stack - destination.Count)
        if quantity == 0 then
            return false, "A pilha de destino está cheia."
        end
        destination.Count += quantity
        source.Count -= quantity
        if source.Count == 0 then
            slots[fromKey] = nil
        end
    else
        slots[fromKey], slots[toKey] = destination, source
    end
    return true, "Inventário atualizado."
end

-- Aquisição somente por módulos do servidor. A operação é atômica na sessão.
function Inventory.Grant(player, itemId, quantity)
    local data = Profiles.Get(player)
    local definition = if type(itemId) == "string" then Items.Catalog[itemId] else nil
    if not data or not definition or type(quantity) ~= "number"
        or quantity % 1 ~= 0 or quantity < 1 then
        return false
    end
    if Inventory.Weight(data.Slots) + definition.Grams * quantity > Items.MaxGrams then
        return false
    end

    local remaining = quantity
    local changes = {}
    for index = 1, Items.Slots do
        local key = tostring(index)
        local slot = data.Slots[key]
        if slot and slot.Id == itemId then
            local added = math.min(remaining, definition.Stack - slot.Count)
            changes[key] = { Id = itemId, Count = slot.Count + added }
            remaining -= added
        end
    end
    for index = 1, Items.Slots do
        if remaining == 0 then
            break
        end
        local key = tostring(index)
        if not data.Slots[key] then
            local added = math.min(remaining, definition.Stack)
            changes[key] = { Id = itemId, Count = added }
            remaining -= added
        end
    end
    if remaining > 0 then
        return false
    end
    for key, slot in pairs(changes) do
        data.Slots[key] = slot
    end
    return true
end

return Inventory
