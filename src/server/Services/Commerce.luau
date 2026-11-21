local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.CommerceConfig)
local Items = require(Shared.Items)
local Profiles = require(script.Parent.Profiles)
local Rules = require(script.Parent.InventoryRules)
local Inventory = require(script.Parent.Inventory)
local Economy = require(script.Parent.Economy)

local Commerce = {}
local TAG = "OperacaoRioCommerce"
local function nearby(player, id)
    if type(id) ~= "string" or not Config[id] then
        return false
    end
    local model = player.Character
    local root = model and model:FindFirstChild("HumanoidRootPart")
    local humanoid = model and model:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then
        return false
    end
    for _, point in ipairs(CollectionService:GetTagged(TAG)) do
        if point:IsA("BasePart") and point:IsDescendantOf(workspace)
            and point:GetAttribute("CommerceId") == id and (root.Position - point.Position).Magnitude <= 12 then
            return true
        end
    end
    return false
end

function Commerce.Read(player, id)
    local data = Profiles.Get(player)
    if not data or not nearby(player, id) then
        return { Ok = false, Message = "Aproxime-se do estabelecimento." }
    end
    local offers = {}
    local catalog = Config[id].Catalog
    if catalog then
        local slots = Rules.Limits(data)
        for index = 1, slots do
            local slot = data.Slots[tostring(index)]
            if slot and catalog[slot.Id] then
                table.insert(offers, {
                    Slot = index, Item = slot.Id, Price = math.max(1, math.floor(catalog[slot.Id] / 2)),
                })
            end
        end
    end
    return {
        Ok = true,
        Offers = offers,
        Cash = data.Cash,
        Bank = if id == "bank" then data.Bank else nil,
        Sequence = (data.TransactionSequence or 0) + 1,
        History = if id == "bank" then data.Transactions or {} else nil,
    }
end

function Commerce.Transact(player, payload)
    if type(payload) ~= "table" or not nearby(player, payload.Location) then
        return { Ok = false, Message = "Estabelecimento indisponível." }
    end
    local active = Profiles.Get(player)
    if not active or payload.CharacterId ~= active.Id then
        return { Ok = false, Message = "Selecione um personagem." }
    end
    local id = payload.Location
    local ok, message = Profiles.Commit(player, function(account)
        for _, data in ipairs(account.Characters) do
            if data.Id ~= active.Id then
                continue
            end
            local operation = payload.Operation
            if id == "bank" and (operation == "deposit" or operation == "withdraw") then
                return Economy.Apply(data, payload.Sequence, operation, payload.Amount)
            end
            local catalog = Config[id].Catalog
            if not catalog or (operation ~= "purchase" and operation ~= "sale") then
                return false, "Operação indisponível neste local."
            end
            if operation == "purchase" then
                local itemId = payload.Item
                local price = if type(itemId) == "string" then catalog[itemId] else nil
                if not price or not Inventory.CanHandle(player, data, Items.Catalog[itemId]) then
                    return false, "Produto indisponível."
                end
                if not Rules.Grant(data, itemId, 1) then
                    return false, "Sem espaço ou capacidade de peso."
                end
                return Economy.Apply(data, payload.Sequence, operation, price)
            end
            local key = Rules.Index(data, payload.Slot)
            local slot = key and data.Slots[key]
            local price = slot and slot.Id == payload.Item and catalog[slot.Id]
            if not price then
                return false, "Esta loja não compra o item selecionado."
            end
            local removed, reason = Inventory.Discard(data, key, 1)
            if not removed then
                return false, reason
            end
            return Economy.Apply(data, payload.Sequence, operation, math.max(1, math.floor(price / 2)))
        end
        return false, "Personagem indisponível."
    end)
    local result = Commerce.Read(player, id)
    result.Ok = ok
    result.Message = message
    local updated = Profiles.Get(player)
    if ok and updated then
        player:SetAttribute("RoleCash", updated.Cash)
    end
    return result
end

function Commerce.Start(studioTerminals)
    if not RunService:IsStudio() or not studioTerminals then
        return
    end
    local folder = Instance.new("Folder")
    folder.Name = "OperacaoRioCommerceStudio"
    folder.Parent = workspace
    for id, config in pairs(Config) do
        local point = Instance.new("Part")
        point.Name = config.Name
        point.Size = Vector3.new(4, 5, 2)
        point.Position = config.Position
        point.Color = Color3.fromRGB(23, 105, 170)
        point.Anchored = true
        point:SetAttribute("CommerceId", id)
        point:AddTag(TAG)
        point.Parent = folder
        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Abrir"
        prompt.ObjectText = config.Name
        prompt.MaxActivationDistance = 10
        prompt.Parent = point
    end
end

return Commerce
