local Players = game:GetService("Players")
local Items = require(game:GetService("ReplicatedStorage").Shared.Items)
local Services = script.Parent.Parent.Services
local Profiles = require(Services.Profiles)
local Inventory = require(Services.Inventory)
local Rules = require(Services.InventoryRules)
local Economy = require(Services.Economy)
local Careers = require(Services.Careers)
local Teams = require(Services.Teams)
local Characters = require(Services.Characters)
local City = require(script.Parent.City)
local Moderation = require(script.Parent.Moderation)

local Actions = {}
local frozen = setmetatable({}, { __mode = "k" })
local god = setmetatable({}, { __mode = "k" })

local function alter(target, action, args)
    local active = Profiles.Get(target)
    if not active then
        return false, "Alvo precisa de um personagem ativo."
    end
    local ok, message = Profiles.Commit(target, function(account)
        for _, data in ipairs(account.Characters) do
            if data.Id ~= active.Id then
                continue
            end
            if action == "giveitem" then
                local item = Items.Catalog[args.Key]
                if not item or not Inventory.CanHandle(target, data, item) then
                    return false, "Item indisponível para a carreira."
                end
                local granted = Rules.Grant(data, args.Key, args.Value)
                return granted, if granted then "Item concedido." else "Capacidade insuficiente."
            elseif action == "removeitem" then
                local slot = Rules.Index(data, args.Slot)
                if not slot then
                    return false, "Slot inválido."
                end
                return Inventory.Discard(data, slot, args.Value)
            elseif action == "setteam" then
                if not Careers.CanJoin(target, args.Key) then
                    return false, "A conta do alvo não está autorizada para essa equipe."
                end
                Careers.Enter(data, args.Key)
                return true, "Equipe atualizada."
            end

            local amount = if action == "setmoney" then args.Value - data.Cash
                elseif action == "removemoney" then -args.Value else args.Value
            if amount == 0 then
                return false, "O saldo já tem esse valor."
            end
            return Economy.Apply(data, (data.TransactionSequence or 0) + 1,
                if amount > 0 then "admin_credit" else "admin_debit", math.abs(amount))
        end
        return false, "Personagem indisponível."
    end)
    local updated = Profiles.Get(target)
    if ok and updated then
        if action == "setteam" then
            Teams.Restore(target, updated)
            Characters.PublishIdentity(target)
        else
            target:SetAttribute("RoleCash", updated.Cash)
        end
    end
    return ok, message
end

local mutations = {
    setmoney = true, givemoney = true, removemoney = true, giveitem = true, removeitem = true, setteam = true,
}
local world = { announce = true, settime = true, setweather = true }

function Actions.Run(actor, action, args, id)
    local target = args.Target and Players:GetPlayerByUserId(args.Target)
    if world[action] then
        return City.Apply(id, action, args.Text or args.Value or args.Key)
    elseif action == "kick" or action == "ban" or action == "unban" then
        return Moderation.Apply(action, args.Target, target, args.Text,
            if args.Value == -1 then -1 elseif args.Value then args.Value * 86400 else nil)
    elseif not target then
        return false, "Alvo precisa estar neste servidor."
    elseif mutations[action] then
        return alter(target, action, args)
    elseif action == "balance" or action == "inventory" then
        local data = Profiles.Get(target)
        if not data then
            return false, "Personagem indisponível."
        end
        if action == "balance" then
            return true, ("Carteira R$ %d · Banco R$ %d"):format(data.Cash, data.Bank)
        end
        local rows = {}
        local limit = Rules.Limits(data)
        for index = 1, limit do
            local slot = data.Slots[tostring(index)]
            if slot then
                table.insert(rows, ("%d · %s ×%d"):format(index, Items.Catalog[slot.Id].Name, slot.Count))
            end
        end
        return true, "Inventário consultado.", { Rows = rows }
    elseif action == "revive" then
        return Characters.Revive(target)
    end

    local model = target.Character
    local root = model and model:FindFirstChild("HumanoidRootPart")
    local humanoid = model and model:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then
        return false, "Avatar vivo indisponível."
    end
    if action == "goto" or action == "bring" then
        if not actor.Character or not actor.Character:FindFirstChild("HumanoidRootPart") then
            return false, "Abra um personagem para teleportar."
        end
        local mover, destination = model, actor.Character
        if action == "goto" then
            mover, destination = destination, mover
        end
        mover:PivotTo(destination:GetPivot() * CFrame.new(3, 0, 0))
    elseif action == "spectate" then
        return true, "Observação iniciada.", { Spectate = target.UserId }
    elseif action == "freeze" then
        if frozen[root] == nil then
            frozen[root] = { Anchored = root.Anchored }
        end
        root.Anchored = true
    elseif action == "unfreeze" then
        if not frozen[root] then
            return false, "Alvo não está congelado pelo painel."
        end
        root.Anchored = frozen[root].Anchored
        frozen[root] = nil
    elseif action == "heal" then
        humanoid.Health = humanoid.MaxHealth
    elseif action == "god" then
        if god[model] then
            god[model]:Destroy()
            god[model] = nil
            return true, "ForceField removido."
        end
        local shield = Instance.new("ForceField")
        shield.Visible = false
        shield.Parent = model
        god[model] = shield
        return true, "ForceField ativado."
    else
        return false, "Ação indisponível."
    end
    return true, "Ação executada."
end

return Actions
