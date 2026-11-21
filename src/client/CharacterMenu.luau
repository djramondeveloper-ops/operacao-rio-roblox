local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.AvatarConfig)
local Appearance = require(ReplicatedStorage.Shared.Appearance)
local Preview = require(script.Parent.AvatarPreview)
local Scene = require(script.Parent.MenuScene)
local Theme = require(script.Parent.Theme)

local Menu = {}

function Menu.Start(request)
    local player = Players.LocalPlayer
    local gui = Instance.new("ScreenGui")
    gui.Name = "OperacaoRioMenu"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 20
    gui.Parent = player:WaitForChild("PlayerGui")

    local panel = Instance.new("Frame")
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.fromScale(0.94, 0.9)
    panel.BackgroundColor3 = Theme.Graphite
    panel.BackgroundTransparency = 0.07
    panel.Parent = gui
    Theme.Rounded(panel, 14)

    local size = Instance.new("UISizeConstraint")
    size.MaxSize = Vector2.new(490, 610)
    size.Parent = panel

    local border = Instance.new("UIStroke")
    border.Color = Theme.Blue
    border.Transparency = 0.3
    border.Parent = panel

    local logo = Theme.Label("TextLabel", panel, "OPERAÇÃO RIO", 29)
    logo.Font = Enum.Font.GothamBlack
    logo.Size = UDim2.new(1, -24, 0, 48)
    logo.Position = UDim2.fromOffset(12, 7)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(Theme.White, Theme.Gold)
    gradient.Parent = logo

    local scroll = Instance.new("ScrollingFrame")
    scroll.Position = UDim2.fromOffset(12, 55)
    scroll.Size = UDim2.new(1, -24, 1, -110)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.CanvasSize = UDim2.new()
    scroll.ScrollingDirection = Enum.ScrollingDirection.Y
    scroll.ScrollBarThickness = 5
    scroll.Parent = panel

    local status = Theme.Label("TextLabel", panel, "", 14)
    status.Position = UDim2.new(0, 12, 1, -54)
    status.Size = UDim2.new(1, -24, 0, 48)

    local content
    local page
    local busy = false
    local currentList = {}
    local primary
    local home, list, editor

    local function message(text, alert)
        status.Text = text
        status.TextColor3 = if alert then Color3.fromRGB(255, 153, 153) else Theme.White
    end

    local function showPage(name)
        if content then
            content:Destroy()
        end
        page = name
        primary = nil
        scroll.CanvasPosition = Vector2.zero
        content = Instance.new("CanvasGroup")
        content.Size = UDim2.new(1, -8, 0, 0)
        content.AutomaticSize = Enum.AutomaticSize.Y
        content.BackgroundTransparency = 1
        content.GroupTransparency = 1
        content.Parent = scroll
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.Parent = content
        Theme.Tween(content, 0.2, { GroupTransparency = 0 })
        message("")
    end

    local function caption(text, height)
        local label = Theme.Label("TextLabel", content, text, 15)
        label.Size = UDim2.new(1, 0, 0, height or 32)
        return label
    end

    local function action(text, callback, isPrimary)
        local function activate()
            if not busy then
                callback()
            end
        end
        local control = Theme.Button(content, text, activate)
        if isPrimary then
            primary = activate
        end
        return control
    end

    local function invoke(name, ...)
        if busy then
            return nil
        end
        busy = true
        message("Aguarde…")
        local args = table.pack(...)
        local ok, result = pcall(function()
            return request:InvokeServer(name, table.unpack(args, 1, args.n))
        end)
        busy = false
        if not ok or type(result) ~= "table" then
            message("Não foi possível conectar ao servidor. Tente novamente.", true)
            return nil
        end
        if result.Characters then
            currentList = result.Characters
        end
        message(result.Message or "", result.Ok == false or not result.Characters)
        return result
    end

    local function refresh()
        if not player:GetAttribute("ProfileReady") then
            message("Carregando seu perfil…")
            return false
        end
        local response = invoke("characters")
        return response and response.Characters ~= nil
    end

    local function confirmDelete(character)
        showPage("delete")
        caption("Excluir " .. character.Name .. "?", 44)
        caption("O progresso, os bens e o inventário deste personagem serão excluídos.", 56)
        local confirmation = action("Excluir definitivamente", function()
            local result = invoke("deleteCharacter", character.Id, true)
            if result and result.Ok then
                list()
                message(result.Message)
            end
        end)
        confirmation.BackgroundColor3 = Theme.Red
        action("Cancelar", function()
            list()
        end, true)
    end

    local function details(character)
        showPage("details")
        caption(character.Name .. " · " .. character.Rank)
        local preview = Preview.Create(content)
        preview.Show(character.Appearance, function(text)
            message(text, true)
        end)
        action("Girar prévia", function()
            preview.Rotate(math.rad(45))
        end)
        action("Entrar na cidade", function()
            invoke("selectCharacter", character.Id)
        end, true)
        action("Excluir personagem", function()
            confirmDelete(character)
        end)
        action("Voltar", function()
            list()
        end)
    end

    list = function()
        showPage("list")
        caption(("Personagens · %d/3"):format(#currentList))
        for _, character in ipairs(currentList) do
            action(character.Name .. " · " .. character.Rank, function()
                details(character)
            end)
        end
        if #currentList < 3 then
            action("Criar personagem", function()
                editor()
            end, #currentList == 0)
        end
        action("Menu principal", function()
            home()
        end)
    end

    local function field(placeholder)
        local input = Theme.Label("TextBox", content, "", 15)
        input.Size = UDim2.new(1, 0, 0, 44)
        input.PlaceholderText = placeholder
        input.PlaceholderColor3 = Theme.White
        input.BackgroundColor3 = Theme.Surface
        input.BackgroundTransparency = 0
        input.ClearTextOnFocus = false
        input.TextWrapped = false
        Theme.Rounded(input, 8)
        return input
    end

    local labels = { Skin = "Pele", Hair = "Cabelo", Face = "Rosto", Outfit = "Roupa", Accessory = "Acessório" }

    editor = function()
        showPage("editor")
        local template = 1
        local options = Appearance.Sanitize(Config.Templates[template])
        local first = field("Nome RP")
        local last = field("Sobrenome RP")
        local preview = Preview.Create(content)
        local templateButton
        local choices = {}
        local function render()
            templateButton.Text = "Modelo · " .. Config.Templates[template].Name
            for _, name in ipairs(Appearance.Fields) do
                local choice = Config[name][options[name]]
                choices[name].Text = labels[name] .. " · " .. (if type(choice) == "table" then choice[1] else choice)
            end
            preview.Show(options, function(text)
                message(text, true)
            end)
        end
        templateButton = action("", function()
            template = template % #Config.Templates + 1
            options = Appearance.Sanitize(Config.Templates[template])
            render()
        end)
        for _, name in ipairs(Appearance.Fields) do
            choices[name] = action("", function()
                options[name] = options[name] % #Config[name] + 1
                render()
            end)
        end
        local controls = Instance.new("Frame")
        controls.Size = UDim2.new(1, 0, 0, 44)
        controls.BackgroundTransparency = 1
        controls.Parent = content
        for index, spec in ipairs({
            { "Girar", function() preview.Rotate(math.rad(45)) end },
            { "Zoom +", function() preview.ChangeZoom(-1) end },
            { "Zoom −", function() preview.ChangeZoom(1) end },
        }) do
            local button = Theme.Button(controls, spec[1], spec[2])
            button.Size = UDim2.new(1 / 3, -5, 1, 0)
            button.Position = UDim2.fromScale((index - 1) / 3, 0)
        end
        action("Salvar personagem", function()
            local result = invoke("createCharacter", first.Text, last.Text, options)
            if result and result.Ok then
                list()
                message(result.Message)
            end
        end, true)
        action("Cancelar", function()
            list()
        end)
        render()
    end

    home = function()
        showPage("home")
        action("Jogar", function()
            if refresh() then
                list()
            end
        end, true)
        action("Criar personagem", function()
            if refresh() then
                if #currentList < 3 then
                    editor()
                else
                    message("As três vagas estão ocupadas.")
                end
            end
        end)
        action("Personagens", function()
            if refresh() then
                list()
            end
        end)
        action("Configurações", function()
            showPage("settings")
            local setting
            local function update()
                setting.Text = if Theme.ReducedMotion then "Movimento reduzido · ligado" else "Movimento reduzido · desligado"
            end
            setting = action("", function()
                Theme.ReducedMotion = not Theme.ReducedMotion
                update()
            end)
            update()
            action("Voltar", home, true)
        end)
        action("Loja VIP", function()
            showPage("vip")
            caption("A loja VIP ainda não está disponível.", 64)
            action("Voltar", home, true)
        end)
    end

    local function updatePresence()
        local active = player:GetAttribute("ActiveCharacterId") ~= nil
        gui.Enabled = not active
        if active then
            Scene.Close(player.Character)
            if content then
                content:Destroy()
                content = nil
            end
        else
            home()
            Scene.Open()
            if not player:GetAttribute("ProfileReady") then
                message("Carregando seu perfil…")
            end
        end
    end

    player:GetAttributeChangedSignal("ActiveCharacterId"):Connect(updatePresence)
    player:GetAttributeChangedSignal("ProfileReady"):Connect(function()
        if gui.Enabled and page == "home" then
            message("")
        end
    end)
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not gui.Enabled or busy or UserInputService:GetFocusedTextBox() then
            return
        end
        if input.KeyCode == Enum.KeyCode.Return and primary then
            primary()
        elseif input.KeyCode == Enum.KeyCode.Escape and page ~= "home" then
            home()
        end
    end)
    updatePresence()
end

return Menu
