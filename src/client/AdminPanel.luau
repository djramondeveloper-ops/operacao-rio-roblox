local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Input = game:GetService("UserInputService")
local Catalog = require(ReplicatedStorage.Shared.AdminCatalog)
local Theme = require(script.Parent.Theme)

local AdminPanel = {}

function AdminPanel.Start()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local remote = ReplicatedStorage:WaitForChild("OperacaoRioAdmin", 15)
    if not remote then
        return
    end
    local request = remote:WaitForChild("Request")
    local signal = remote:WaitForChild("Signal")
    local gui = Instance.new("ScreenGui")
    gui.Name = "PainelSupremoDoFundador"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 40
    gui.Parent = playerGui

    local panel = Instance.new("Frame")
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Size = UDim2.fromScale(0.94, 0.91)
    panel.BackgroundColor3 = Theme.Graphite
    panel.Visible = false
    panel.Parent = gui
    Theme.Rounded(panel, 12)
    local limit = Instance.new("UISizeConstraint")
    limit.MaxSize = Vector2.new(620, 640)
    limit.Parent = panel
    local border = Instance.new("UIStroke")
    border.Color = Theme.Red
    border.Parent = panel

    local heading = Theme.Label("TextLabel", panel, "PAINEL SUPREMO DO FUNDADOR", 18)
    heading.Font = Enum.Font.GothamBlack
    heading.TextColor3 = Theme.Gold
    heading.Size = UDim2.new(1, -24, 0, 44)
    heading.Position = UDim2.fromOffset(12, 5)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -24, 1, -104)
    scroll.Position = UDim2.fromOffset(12, 49)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.CanvasSize = UDim2.new()
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollBarThickness = 5
    scroll.Parent = panel
    local status = Theme.Label("TextLabel", panel, "", 14)
    status.Size = UDim2.new(1, -24, 0, 50)
    status.Position = UDim2.new(0, 12, 1, -51)
    local toast = Theme.Label("TextLabel", gui, "", 15)
    toast.BackgroundColor3 = Theme.Graphite
    toast.BackgroundTransparency = 0.12
    toast.AnchorPoint = Vector2.new(0.5, 1)
    toast.Position = UDim2.fromScale(0.5, 0.94)
    toast.Size = UDim2.new(0.75, 0, 0, 56)
    toast.Visible = false
    Theme.Rounded(toast, 8)

    local session
    local selection
    local tab
    local root
    local waiting = false
    local toastRevision = 0
    local observed
    local openPanel, render, showAction

    local function notice(message)
        status.Text = message or ""
        if not panel.Visible and message then
            toastRevision += 1
            local revision = toastRevision
            toast.Text = message
            toast.Visible = true
            task.delay(4, function()
                if toastRevision == revision then
                    toast.Visible = false
                end
            end)
        end
    end

    local function observe(id)
        local target = id and Players:GetPlayerByUserId(id) or player
        local humanoid = target and target.Character and target.Character:FindFirstChildOfClass("Humanoid")
        local camera = workspace.CurrentCamera
        if humanoid and camera then
            camera.CameraSubject = humanoid
            observed = if id then target else nil
        elseif not id then
            observed = nil
        end
    end

    local function invoke(action, payload)
        if waiting then
            return nil
        end
        waiting = true
        notice("Consultando servidor…")
        local ok, result = pcall(function()
            return request:InvokeServer(action, payload)
        end)
        waiting = false
        if not ok or type(result) ~= "table" then
            notice("Serviço indisponível.")
            return nil
        end
        notice(result.Message or "")
        return result
    end

    local function clear()
        if root then
            root:Destroy()
        end
        root = Instance.new("Frame")
        root.Size = UDim2.new(1, -8, 0, 0)
        root.AutomaticSize = Enum.AutomaticSize.Y
        root.BackgroundTransparency = 1
        root.Parent = scroll
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 7)
        layout.Parent = root
        scroll.CanvasPosition = Vector2.zero
    end

    local function label(text, height)
        local object = Theme.Label("TextLabel", root, text, 15)
        object.Size = UDim2.new(1, -4, 0, height or 34)
        return object
    end

    local function field(placeholder, initial)
        local box = Theme.Label("TextBox", root, initial or "", 15)
        box.PlaceholderText = placeholder
        box.ClearTextOnFocus = false
        box.Size = UDim2.new(1, 0, 0, 44)
        box.BackgroundColor3 = Theme.Surface
        box.BackgroundTransparency = 0
        Theme.Rounded(box, 8)
        return box
    end

    local function button(text, handler)
        return Theme.Button(root, text, function()
            if not waiting then
                handler()
            end
        end)
    end

    local function showResult(result, back, more)
        if result.Spectate then
            observe(result.Spectate)
        end
        if not result.Rows and not result.Audit then
            return
        end
        clear()
        button("Voltar", back)
        for _, line in ipairs(result.Rows or {}) do
            label(line)
        end
        if result.Audit and #result.Audit == 0 then
            label("Nenhum registro encontrado.")
        end
        for _, row in ipairs(result.Audit or {}) do
            local fields = {}
            if row.Value then
                table.insert(fields, if row.Action == "ban" then
                    (if row.Value == -1 then "Permanente" else tostring(row.Value) .. " dia(s)") else tostring(row.Value))
            end
            if row.Key then
                table.insert(fields, row.Key)
            end
            if row.Slot then
                table.insert(fields, "Slot " .. tostring(row.Slot))
            end
            if row.Reason then
                table.insert(fields, row.Reason)
            end
            label(("%s UTC · %s · %s\nUserId %s → %s%s"):format(
                os.date("!%d/%m %H:%M", row.At), row.Action, row.Result,
                tostring(row.Actor), tostring(row.Target or "—"),
                if #fields > 0 then "\n" .. table.concat(fields, " · ") else ""
            ), if #fields > 0 then 98 else 56)
        end
        if result.More and more then
            button("Próxima página", more)
        end
    end

    local launcher = Theme.Button(gui, "Painel supremo", function()
        openPanel()
    end)
    launcher.AnchorPoint = Vector2.new(0, 1)
    launcher.Position = UDim2.new(0, 12, 1, -88)
    launcher.Size = UDim2.fromOffset(145, 44)
    launcher.Visible = false

    local function acceptPanel(result)
        session = result
        launcher.Visible = false
        panel.Visible = true
        panel.BackgroundTransparency = 0.25
        Theme.Tween(panel, 0.18, { BackgroundTransparency = 0 })
        tab = nil
        render()
    end

    openPanel = function()
        local result = invoke("open")
        if result and result.Ok then
            acceptPanel(result)
        else
            launcher.Visible = false
        end
    end

    local global = { announce = true, settime = true, setweather = true }
    local numeric = {
        settime = "Hora de 0 a 23", ban = "Dias (-1 permanente)",
        setmoney = "Valor em reais", givemoney = "Valor em reais", removemoney = "Valor em reais",
        giveitem = "Quantidade", removeitem = "Quantidade",
    }
    local keyed = { giveitem = "ID do item", setteam = "ID da equipe", role = "Cargo ou NONE",
        setweather = "clear / fog", logs = "Filtrar por comando (opcional)" }
    local textActions = { announce = true, kick = true, ban = true, unban = true }

    showAction = function(descriptor)
        clear()
        local action, title, syntax = table.unpack(descriptor)
        button("Voltar", render)
        label(title)
        label("/" .. action .. " " .. syntax, 42)
        local target = if global[action] then nil else field(
            if action == "logs" then "UserId opcional" else "UserId do jogador", selection
        )
        local value = numeric[action] and field(numeric[action])
        local key = keyed[action] and field(keyed[action])
        local slot = action == "removeitem" and field("Número do slot")
        local sentence = textActions[action] and field(if action == "announce" then "Texto" else "Motivo obrigatório")
        local back = function() showAction(descriptor) end

        button("Continuar", function()
            local payload = {
                Target = target and tonumber(target.Text),
                Value = value and tonumber(value.Text),
                Key = if key and key.Text ~= "" then key.Text else nil,
                Slot = slot and tonumber(slot.Text),
                Text = sentence and sentence.Text,
                Page = 1,
            }
            local function query()
                local result = invoke(action, payload)
                if not result or not result.Ok then
                    return
                end
                if result.Token then
                    clear()
                    local detail = ("%s%s%s%s"):format(title,
                        if payload.Target then " · UserId " .. tostring(payload.Target) else "",
                        if payload.Key then " · " .. payload.Key else "",
                        if payload.Value then " · " .. tostring(payload.Value) else "")
                    label(detail, 54)
                    button("Confirmar", function()
                        local confirmed = invoke("confirm", result.Token)
                        if confirmed and confirmed.Ok then
                            back()
                        end
                    end).BackgroundColor3 = Theme.Red
                    button("Cancelar", function()
                        invoke("cancel")
                        back()
                    end)
                else
                    showResult(result, back, function()
                        payload.Page += 1
                        query()
                    end)
                end
            end
            query()
        end)
    end

    render = function()
        clear()
        if not tab then
            label("Acesso · " .. session.Role)
            button("Fechar", function()
                panel.Visible = false
                launcher.Visible = true
            end)
            if observed then
                button("Parar observação", function()
                    observe(nil)
                    render()
                end)
            end
            for _, group in ipairs(Catalog) do
                local hasAccess = group[1] == "Dashboard" or group[1] == "Configurações"
                    or (session.Role == "FOUNDER" and group.Pending ~= nil)
                for index = 2, #group do
                    hasAccess = hasAccess or session.Available[group[index][1]] == true
                end
                if hasAccess then
                    button(group[1], function()
                        tab = group
                        render()
                    end)
                end
            end
            return
        end

        button("Todas as abas", function()
            tab = nil
            render()
        end)
        label(tab[1])
        if tab[1] == "Dashboard" then
            label(("Cargo %s · %d jogadores online"):format(session.Role, #session.Players))
            button("Atualizar sessão", openPanel)
        elseif tab[1] == "Configurações" then
            button(if Theme.ReducedMotion then "Movimento reduzido ligado" else "Movimento reduzido desligado", function()
                Theme.ReducedMotion = not Theme.ReducedMotion
                render()
            end)
            label("Atalho: F8 ou /admin")
        elseif tab[1] == "Jogadores" then
            local search = field("Pesquisar nome Roblox ou UserId")
            local rows = {}
            for _, row in ipairs(session.Players) do
                rows[row] = button(("%s · %d"):format(row.Name, row.UserId), function()
                    selection = tostring(row.UserId)
                    notice("Alvo selecionado · " .. row.Name)
                end)
            end
            search:GetPropertyChangedSignal("Text"):Connect(function()
                local query = search.Text:lower()
                for row, control in pairs(rows) do
                    control.Visible = row.Name:lower():find(query, 1, true) ~= nil
                        or tostring(row.UserId):find(query, 1, true) ~= nil
                end
            end)
        end
        if tab.Pending and session.Role == "FOUNDER" then
            label(tab.Pending, 64)
        end
        for index = 2, #tab do
            local descriptor = tab[index]
            if session.Available[descriptor[1]] then
                button(descriptor[2], function()
                    showAction(descriptor)
                end)
            end
        end
    end

    signal.OnClientEvent:Connect(function(kind, result)
        if kind == "announcement" then
            toast.Text = result
            toast.Visible = true
            toastRevision += 1
            local revision = toastRevision
            task.delay(7, function()
                if toastRevision == revision then
                    toast.Visible = false
                end
            end)
        elseif kind == "roleChanged" then
            panel.Visible = false
            observe(nil)
            task.delay(0.75, function()
                local ok, refreshed = pcall(function() return request:InvokeServer("open") end)
                launcher.Visible = ok and type(refreshed) == "table" and refreshed.Ok == true and not panel.Visible
            end)
        elseif kind == "open" then
            acceptPanel(result)
        elseif kind == "result" then
            notice(result.Message)
            if result.Spectate then
                observe(result.Spectate)
            end
            if panel.Visible and (result.Audit or result.Rows) then
                showResult(result, function()
                    tab = nil
                    render()
                end)
            end
        end
    end)
    Players.PlayerRemoving:Connect(function(leaving)
        if observed == leaving then
            observe(nil)
        end
    end)
    player.CharacterAdded:Connect(function()
        observed = nil
    end)
    Input.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Enum.KeyCode.F8 then
            if panel.Visible then
                panel.Visible = false
                launcher.Visible = true
            else
                openPanel()
            end
        end
    end)
    task.spawn(function()
        local ok, result = pcall(function() return request:InvokeServer("open") end)
        launcher.Visible = ok and type(result) == "table" and result.Ok == true and not panel.Visible
    end)
end

return AdminPanel
