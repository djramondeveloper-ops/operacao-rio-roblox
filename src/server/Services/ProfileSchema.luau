local Shared = game:GetService("ReplicatedStorage").Shared
local Items = require(Shared.Items)
local Appearance = require(Shared.Appearance)
local Careers = require(script.Parent.Careers)
local InventoryRules = require(script.Parent.InventoryRules)

local Schema = {}

local function decodeLegacy(data)
    if type(data) ~= "table" or data.Version ~= 1 or type(data.Slots) ~= "table"
        or type(data.Team) ~= "string" then
        return nil
    end

    local slots = {}
    local grams = 0
    for key, slot in pairs(data.Slots) do
        local index = if type(key) == "string" then tonumber(key) else nil
        local definition = if type(slot) == "table" and type(slot.Id) == "string"
            then Items.Catalog[slot.Id] else nil
        if not index or index % 1 ~= 0
            or index < 1 or index > Items.Slots or tostring(index) ~= key
            or not definition or type(slot.Count) ~= "number" or slot.Count % 1 ~= 0
            or slot.Count < 1 or slot.Count > definition.Stack then
            return nil
        end
        slots[key] = { Id = slot.Id, Count = slot.Count }
        grams += definition.Grams * slot.Count
    end
    if grams > Items.MaxGrams then
        return nil
    end
    return { Team = data.Team, Slots = slots }
end

local function starterInventory()
    return {
        Version = 1,
        Team = "civil",
        Slots = {
            ["1"] = { Id = "agua", Count = 2 },
            ["2"] = { Id = "lanche", Count = 1 },
        },
    }
end

function Schema.New()
    return { Version = 2, Characters = {} }
end

function Schema.NewCharacter(id, first, last, appearance, legacy)
    local team = legacy and legacy.Team or "civil"
    if not Careers.Paths[team] then
        team = "civil"
    end
    return {
        Id = id,
        First = first,
        Last = last,
        Appearance = appearance,
        Team = team,
        Careers = { [team] = 1 },
        Cash = 0,
        Bank = 0,
        Slots = if legacy then legacy.Slots else starterInventory().Slots,
        Garage = {},
        Progress = {},
    }
end

local function validMoney(value)
    return type(value) == "number" and value >= 0 and value <= 1000000000 and value % 1 == 0
end

function Schema.Decode(data)
    if type(data) ~= "table" then
        return nil
    end
    if data.Version == 1 then
        local legacy = decodeLegacy(data)
        if not legacy then
            return nil
        end
        local account = Schema.New()
        account.Legacy = legacy
        return account
    end
    if data.Version ~= 2 or type(data.Characters) ~= "table" or #data.Characters > 3 then
        return nil
    end
    local ids = {}
    local count = 0
    for index, character in pairs(data.Characters) do
        if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > #data.Characters
            or type(character) ~= "table" or type(character.Id) ~= "string" or ids[character.Id]
            or type(character.First) ~= "string" or type(character.Last) ~= "string"
            or not Appearance.Sanitize(character.Appearance) or type(character.Team) ~= "string"
            or not Careers.Paths[character.Team] or type(character.Careers) ~= "table"
            or not character.Careers[character.Team] or not validMoney(character.Cash)
            or not validMoney(character.Bank) or type(character.Garage) ~= "table"
            or type(character.Progress) ~= "table"
            or type(character.Slots) ~= "table" or not InventoryRules.Validate(character) then
            return nil
        end
        for organization, rank in pairs(character.Careers) do
            local ranks = Careers.Paths[organization]
            if not ranks or type(rank) ~= "number" or rank % 1 ~= 0 or not ranks[rank] then
                return nil
            end
        end
        ids[character.Id] = true
        count += 1
    end
    if count ~= #data.Characters then
        return nil
    end
    if data.Legacy ~= nil then
        if type(data.Legacy) ~= "table" or not decodeLegacy({
            Version = 1, Team = data.Legacy.Team, Slots = data.Legacy.Slots,
        }) then
            return nil
        end
    end
    return data
end

function Schema.Copy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, child in pairs(value) do
        copy[key] = Schema.Copy(child)
    end
    return copy
end

return Schema
