local Items = require(game:GetService("ReplicatedStorage").Shared.Items)

local Rules = {}

function Rules.Limits(character)
    if character.Backpack then
        return Items.Slots + Items.BackpackSlots, Items.MaxGrams + Items.BackpackGrams
    end
    return Items.Slots, Items.MaxGrams
end

function Rules.Weight(slots)
    local grams = 0
    for _, slot in pairs(slots) do
        grams += Items.Catalog[slot.Id].Grams * slot.Count
    end
    return grams
end

function Rules.Index(character, value)
    local maxSlots = Rules.Limits(character)
    if type(value) == "number" and value % 1 == 0 and value >= 1 and value <= maxSlots then
        return tostring(value)
    end
    return nil
end

function Rules.Validate(character)
    local slots, capacity = Rules.Limits(character)
    if character.Backpack ~= nil and type(character.Backpack) ~= "boolean" then
        return false
    end
    local ownsBackpack = false
    local grams = 0
    for key, slot in pairs(character.Slots) do
        local index = if type(key) == "string" then tonumber(key) else nil
        local definition = if type(slot) == "table" and type(slot.Id) == "string"
            then Items.Catalog[slot.Id] else nil
        if not index or index % 1 ~= 0 or index < 1 or index > slots or tostring(index) ~= key
            or not definition or type(slot.Count) ~= "number" or slot.Count % 1 ~= 0
            or slot.Count < 1 or slot.Count > definition.Stack then
            return false
        end
        if slot.Durability ~= nil and (not definition.Durability or type(slot.Durability) ~= "number"
            or slot.Durability % 1 ~= 0 or slot.Durability < 0 or slot.Durability > definition.Durability) then
            return false
        end
        ownsBackpack = ownsBackpack or slot.Id == "mochila"
        grams += definition.Grams * slot.Count
    end
    return grams <= capacity and (not character.Backpack or ownsBackpack)
end

function Rules.Grant(character, itemId, quantity)
    local definition = if type(itemId) == "string" then Items.Catalog[itemId] else nil
    if not definition or type(quantity) ~= "number" or quantity % 1 ~= 0 or quantity < 1 then
        return false
    end
    local slots, maxWeight = Rules.Limits(character)
    if Rules.Weight(character.Slots) + definition.Grams * quantity > maxWeight then
        return false
    end

    local remaining = quantity
    local changes = {}
    for index = 1, slots do
        local key = tostring(index)
        local slot = character.Slots[key]
        if slot and slot.Id == itemId and definition.Stack > 1 then
            local added = math.min(remaining, definition.Stack - slot.Count)
            if added > 0 then
                changes[key] = { Id = itemId, Count = slot.Count + added }
                remaining -= added
            end
        end
    end
    for index = 1, slots do
        if remaining == 0 then
            break
        end
        local key = tostring(index)
        if not character.Slots[key] then
            local added = math.min(remaining, definition.Stack)
            changes[key] = { Id = itemId, Count = added, Durability = definition.Durability }
            remaining -= added
        end
    end
    if remaining > 0 then
        return false
    end
    for key, slot in pairs(changes) do
        character.Slots[key] = slot
    end
    return true
end

return Rules
