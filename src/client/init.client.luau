local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared:WaitForChild("Items"))
local Teams = require(Shared:WaitForChild("TeamsConfig"))
local request = ReplicatedStorage:WaitForChild("OperacaoRioRequest")

if not request:IsA("RemoteFunction") then
    error("OperacaoRioRequest precisa ser uma RemoteFunction.")
end

local Theme = require(script.Theme)
require(script.CharacterMenu).Start(request)
require(script.Hud).Start(request)
local commerceGui = require(script.CommercePanel).Start(request)

local surface = Theme.Graphite
local control = Theme.Surface
local accent = Theme.Blue
local white = Theme.White

local function rounded(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
end

local function textControl(className, parent, text, size)
    local object = Instance.new(className)
    object.Text = text
    object.TextSize = size
    object.TextColor3 = white
    object.Font = Enum.Font.GothamMedium
    object.TextWrapped = true
    object.BackgroundTransparency = 1
    object.Parent = parent
    return object
end

local function button(parent, caption)
    local object = textControl("TextButton", parent, caption, 14)
    object.BackgroundTransparency = 0
    object.BackgroundColor3 = control
    rounded(object, 7)
    return object
end

local gui = Instance.new("ScreenGui")
gui.Name = "OperacaoRio"
gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.Parent = player:WaitForChild("PlayerGui")

local toggle = button(gui, "Mochila e equipe")
toggle.AnchorPoint = Vector2.new(1, 0)
toggle.Position = UDim2.new(1, -12, 0, 12)
toggle.Size = UDim2.fromOffset(148, 44)

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.94, 0, 0.88, 0)
panel.BackgroundColor3 = surface
panel.Visible = false
panel.Parent = gui
rounded(panel, 12)

local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(480, 530)
limit.Parent = panel

local close = button(panel, "Fechar")
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, -12, 0, 10)
close.Size = UDim2.fromOffset(76, 44)

local title = textControl("TextLabel", panel, "Mochila e equipe", 18)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Position = UDim2.fromOffset(14, 10)
title.Size = UDim2.new(1, -112, 0, 44)

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.fromOffset(12, 60)
scroll.Size = UDim2.new(1, -24, 1, -118)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.CanvasSize = UDim2.new()
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollingDirection = Enum.ScrollingDirection.Y
scroll.ScrollBarThickness = 5
scroll.Parent = panel

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -8, 0, 0)
content.AutomaticSize = Enum.AutomaticSize.Y
content.BackgroundTransparency = 1
content.Parent = scroll

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = content

local function heading(caption, order)
    local label = textControl("TextLabel", content, caption, 15)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = UDim2.new(1, 0, 0, 26)
    label.LayoutOrder = order
    return label
end

local weight = heading("Inventário", 1)
local grid = Instance.new("Frame")
grid.Size = UDim2.new(1, 0, 0, 0)
grid.AutomaticSize = Enum.AutomaticSize.Y
grid.BackgroundTransparency = 1
grid.LayoutOrder = 2
grid.Parent = content

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(1 / 3, -6, 0, 48)
gridLayout.CellPadding = UDim2.fromOffset(8, 8)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.FillDirectionMaxCells = 3
gridLayout.Parent = grid

local itemInfo = heading("Selecione um item para ver os detalhes.", 3)
itemInfo.Size = UDim2.new(1, 0, 0, 52)
local tools = Instance.new("Frame")
tools.Size = UDim2.new(1, 0, 0, 50)
tools.BackgroundTransparency = 1
tools.LayoutOrder = 4
tools.Parent = content
local useButton = button(tools, "Usar")
local splitButton = button(tools, "Dividir")
local discardButton = button(tools, "Descartar")
for index, object in ipairs({ useButton, splitButton, discardButton }) do
    object.Size = UDim2.new(1 / 3, -5, 0, 44)
    object.Position = UDim2.fromScale((index - 1) / 3, 0)
end
heading("Equipes", 5)
local status = textControl("TextLabel", panel, "Carregando seu perfil…", 14)
status.Position = UDim2.new(0, 12, 1, -53)
status.Size = UDim2.new(1, -24, 0, 44)

local slots = {}
local teamButtons = {}
local state
local selected
local splitting = false
local discardConfirmation
local drag
useButton.Visible = false
splitButton.Visible = false
discardButton.Visible = false
local ignoreClickUntil = 0
local busy = false
local nextInvoke = 0

local function render()
    if not state then
        return
    end
    weight.Text = ("Inventário · %.2f / %.2f kg"):format(state.Grams / 1000, state.MaxGrams / 1000)
    for index, object in ipairs(slots) do
        object.Visible = index <= state.MaxSlots
        local slot = state.Slots[tostring(index)]
        object.Text = if slot then ("%d · %s ×%d"):format(index, Items.Catalog[slot.Id].Name, slot.Count)
            else ("%d · Vazio"):format(index)
        object.BackgroundColor3 = if selected == index then accent else control
    end
    local item = selected and state.Slots[tostring(selected)]
    local definition = item and Items.Catalog[item.Id]
    itemInfo.Text = if definition then definition.Category .. " · " .. definition.Description
        .. (if item.Durability ~= nil then (" Durabilidade: %d%%"):format(item.Durability) else "")
        else "Selecione um item para ver os detalhes."
    useButton.Visible = definition ~= nil and (item.Id == "mochila" or definition.Heal ~= nil)
    splitButton.Visible = item ~= nil and item.Count > 1
    discardButton.Visible = item ~= nil
    discardButton.Text = if discardConfirmation then "Confirmar" else "Descartar"
    for _, team in ipairs(Teams) do
        local object = teamButtons[team.Id]
        local active = state.Team == team.Id
        object.Text = team.Name .. (if active then " · Atual" elseif not state.Available[team.Id] then " · Restrita" else "")
        object.BackgroundColor3 = if active then accent else control
        object.Active = state.Available[team.Id] and not active
        object.Selectable = object.Active
        object.AutoButtonColor = object.Active
    end
end

local function invoke(action, first, second, third)
    if busy or os.clock() < nextInvoke then
        return
    end
    busy = true
    local ok, response = pcall(function()
        return request:InvokeServer(action, first, second, third)
    end)
    nextInvoke = os.clock() + 0.25
    busy = false
    if not ok or type(response) ~= "table" then
        status.Text = "Falha de conexão. Tente novamente."
        return
    end
    if response.Slots then
        state = response
        render()
    end
    status.Text = response.Message or "Escolha um item e depois o slot de destino."
end

local function clearSelection()
    selected = nil
    splitting = false
    discardConfirmation = nil
end

local function move(origin, destination, quantity)
    clearSelection()
    render()
    invoke("move", origin, destination, quantity)
end

useButton.Activated:Connect(function()
    if selected and not busy and os.clock() >= nextInvoke then
        local index = selected
        clearSelection()
        invoke("use", index)
    end
end)

splitButton.Activated:Connect(function()
    if selected and not busy then
        splitting = true
        discardConfirmation = nil
        status.Text = "Escolha um slot vazio para receber metade da pilha."
        render()
    end
end)

discardButton.Activated:Connect(function()
    if not selected or busy or os.clock() < nextInvoke then
        return
    end
    if discardConfirmation == selected then
        local index = selected
        clearSelection()
        invoke("discard", index, 1)
    else
        discardConfirmation = selected
        splitting = false
        status.Text = "Confirme para descartar uma unidade."
        render()
    end
end)

for index = 1, Items.Slots + Items.BackpackSlots do
    local object = button(grid, tostring(index))
    object.LayoutOrder = index
    slots[index] = object
    object.Visible = index <= Items.Slots
    object.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and state
            and state.Slots[tostring(index)] and not busy then
            drag = { Index = index, Position = input.Position }
        end
    end)
    object.Activated:Connect(function()
        if not state or busy or os.clock() < ignoreClickUntil then
            return
        end
        if not selected then
            if state.Slots[tostring(index)] then
                selected = index
                status.Text = "Escolha o slot de destino."
            end
        elseif index == selected then
            clearSelection()
            status.Text = "Escolha um item e depois o slot de destino."
        elseif os.clock() >= nextInvoke then
            local quantity = if splitting then math.floor(state.Slots[tostring(selected)].Count / 2) else nil
            move(selected, index, quantity)
        end
        render()
    end)
end

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 or not drag then
        return
    end
    local origin = drag
    drag = nil
    if not panel.Visible or (input.Position - origin.Position).Magnitude < 12 then
        return
    end
    ignoreClickUntil = os.clock() + 0.1
    if not state or busy or os.clock() < nextInvoke then
        return
    end
    local objects = gui.Parent:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)
    for _, hit in ipairs(objects) do
        local destination = table.find(slots, hit)
        if destination and destination ~= origin.Index then
            move(origin.Index, destination)
            break
        end
    end
end)

for index, team in ipairs(Teams) do
    local object = button(content, team.Name)
    object.LayoutOrder = index + 5
    object.Size = UDim2.new(1, 0, 0, 44)
    teamButtons[team.Id] = object
    object.Activated:Connect(function()
        if state and state.Available[team.Id] and state.Team ~= team.Id then
            invoke("team", team.Id)
        end
    end)
end

local function setOpen(open)
    if open and (not gui.Enabled or commerceGui.Enabled) then
        return
    end
    panel.Visible = open
    toggle.Visible = not open
    clearSelection()
    drag = nil
    render()
    if open then
        invoke("state")
    end
end

toggle.Activated:Connect(function()
    setOpen(true)
end)
close.Activated:Connect(function()
    setOpen(false)
end)
local function updatePresence()
    gui.Enabled = player:GetAttribute("ActiveCharacterId") ~= nil
    if not gui.Enabled then
        state = nil
        weight.Text = "Inventário"
        for _, object in ipairs(slots) do
            object.Text = ""
        end
        itemInfo.Text = ""
        useButton.Visible = false
        splitButton.Visible = false
        discardButton.Visible = false
        setOpen(false)
    end
end
player:GetAttributeChangedSignal("ActiveCharacterId"):Connect(updatePresence)
commerceGui:GetPropertyChangedSignal("Enabled"):Connect(function()
    if commerceGui.Enabled then
        setOpen(false)
        state = nil
    end
end)
updatePresence()

UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.I then
        setOpen(not panel.Visible)
    end
end)

task.spawn(function()
    while gui.Parent do
        task.wait(1)
        if panel.Visible and not selected and not state then
            invoke("state")
        end
    end
end)
