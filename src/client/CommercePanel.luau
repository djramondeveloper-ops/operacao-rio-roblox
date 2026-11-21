local Players = game:GetService("Players")
local PromptService = game:GetService("ProximityPromptService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.CommerceConfig)
local Items = require(Shared.Items)
local Theme = require(script.Parent.Theme)

local CommercePanel = {}
local transactionNames = {
    deposit = "Depósito", withdraw = "Saque", purchase = "Compra", sale = "Venda", salary = "Salário",
}

function CommercePanel.Start(request)
    local player = Players.LocalPlayer
    local gui = Instance.new("ScreenGui")
    gui.Name = "OperacaoRioCommerce"
    gui.DisplayOrder = 10
    gui.ResetOnSpawn = false
    gui.Enabled = false
    gui.Parent = player:WaitForChild("PlayerGui")
    local panel = Instance.new("Frame")
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Size = UDim2.fromScale(0.92, 0.79)
    panel.BackgroundColor3 = Theme.Graphite
    panel.Parent = gui
    Theme.Rounded(panel, 12)
    local limit = Instance.new("UISizeConstraint")
    limit.MaxSize = Vector2.new(445, 530)
    limit.Parent = panel

    local scroll = Instance.new("ScrollingFrame")
    scroll.Position = UDim2.fromOffset(12, 12)
    scroll.Size = UDim2.new(1, -24, 1, -66)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 5
    scroll.ScrollingDirection = Enum.ScrollingDirection.Y
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.CanvasSize = UDim2.new()
    scroll.Parent = panel
    local status = Theme.Label("TextLabel", panel, "", 14)
    status.Position = UDim2.new(0, 12, 1, -50)
    status.Size = UDim2.new(1, -24, 0, 46)

    local location
    local character
    local state
    local busy = false
    local revision = 0
    local content
    local render

    local function close()
        revision += 1
        gui.Enabled = false
        state = nil
    end

    local function invoke(operation, args)
        if busy then
            return nil
        end
        busy = true
        status.Text = "Aguarde…"
        local ticket = revision
        local ok, result = pcall(function()
            return request:InvokeServer(operation, args)
        end)
        busy = false
        if ticket ~= revision then
            return nil
        end
        if not ok or type(result) ~= "table" then
            status.Text = "Falha de conexão."
            return nil
        end
        status.Text = result.Message or ""
        return result
    end

    local function transact(operation, values)
        if not state then
            return
        end
        values.Location = location
        values.CharacterId = character
        values.Operation = operation
        values.Sequence = state.Sequence
        local response = invoke("commerceTransact", values)
        if response and response.Sequence then
            state = response
            render()
        elseif response and not response.Ok then
            state = nil
            render()
        end
    end

    local function label(text, size)
        local label = Theme.Label("TextLabel", content, text, size or 15)
        label.Size = UDim2.new(1, 0, 0, 36)
        return label
    end

    local function input(placeholder)
        local box = Theme.Label("TextBox", content, "", 15)
        box.PlaceholderText = placeholder
        box.Size = UDim2.new(1, 0, 0, 44)
        box.BackgroundTransparency = 0
        box.BackgroundColor3 = Theme.Surface
        Theme.Rounded(box, 8)
        return box
    end

    render = function()
        if content then
            content:Destroy()
        end
        content = Instance.new("Frame")
        content.Size = UDim2.new(1, -8, 0, 0)
        content.AutomaticSize = Enum.AutomaticSize.Y
        content.BackgroundTransparency = 1
        content.Parent = scroll
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 7)
        layout.Parent = content
        label(Config[location].Name, 20)
        Theme.Button(content, "Fechar", close)
        if not state then
            Theme.Button(content, "Atualizar", function()
                local response = invoke("commerceRead", location)
                if response and response.Ok then
                    state = response
                    render()
                end
            end)
            return
        end
        label(("Em mãos · R$ %d"):format(state.Cash))
        if location == "bank" then
            label(("Banco · R$ %d"):format(state.Bank))
            local amount = input("Valor em reais")
            Theme.Button(content, "Depositar", function()
                transact("deposit", { Amount = tonumber(amount.Text) })
            end)
            Theme.Button(content, "Sacar", function()
                transact("withdraw", { Amount = tonumber(amount.Text) })
            end)
            label("Extrato")
            for index = #state.History, 1, -1 do
                local entry = state.History[index]
                label(("%s · R$ %d"):format(transactionNames[entry.Kind] or entry.Kind, entry.Amount))
            end
            return
        end
        local products = {}
        for itemId in pairs(Config[location].Catalog) do
            table.insert(products, itemId)
        end
        table.sort(products)
        for _, itemId in ipairs(products) do
            Theme.Button(content, ("Comprar %s · R$ %d"):format(
                Items.Catalog[itemId].Name, Config[location].Catalog[itemId]
            ), function()
                transact("purchase", { Item = itemId })
            end)
        end
        local slot = input("Número do slot para venda")
        Theme.Button(content, "Vender uma unidade por metade do preço", function()
            transact("sale", { Slot = tonumber(slot.Text) })
        end)
    end

    PromptService.PromptTriggered:Connect(function(prompt, source)
        if source ~= player or busy then
            return
        end
        local point = prompt.Parent
        local id = point and point:GetAttribute("CommerceId")
        local active = player:GetAttribute("ActiveCharacterId")
        if type(id) ~= "string" or not Config[id] or not active then
            return
        end
        close()
        location = id
        character = active
        gui.Enabled = true
        scroll.CanvasPosition = Vector2.zero
        render()
        local response = invoke("commerceRead", location)
        if response and response.Ok then
            state = response
            render()
        end
    end)
    player:GetAttributeChangedSignal("ActiveCharacterId"):Connect(close)
end

return CommercePanel
