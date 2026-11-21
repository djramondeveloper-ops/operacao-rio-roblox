local Players = game:GetService("Players")
local Theme = require(script.Parent.Theme)

local Hud = {}

function Hud.Start(request)
    local player = Players.LocalPlayer
    local gui = Instance.new("ScreenGui")
    gui.Name = "OperacaoRioHUD"
    gui.ResetOnSpawn = false
    gui.Parent = player:WaitForChild("PlayerGui")

    local panel = Instance.new("Frame")
    panel.Position = UDim2.fromOffset(12, 12)
    panel.Size = UDim2.new(0.58, 0, 0, 142)
    panel.BackgroundColor3 = Theme.Graphite
    panel.BackgroundTransparency = 0.12
    panel.Parent = gui
    Theme.Rounded(panel, 9)
    local limit = Instance.new("UISizeConstraint")
    limit.MaxSize = Vector2.new(288, 142)
    limit.Parent = panel

    local identity = Theme.Label("TextLabel", panel, "", 14)
    identity.Position = UDim2.fromOffset(10, 6)
    identity.Size = UDim2.new(1, -20, 0, 40)
    identity.TextXAlignment = Enum.TextXAlignment.Left
    local vital = Theme.Label("TextLabel", panel, "", 13)
    vital.Position = UDim2.fromOffset(10, 44)
    vital.Size = UDim2.new(1, -20, 0, 32)
    vital.TextXAlignment = Enum.TextXAlignment.Left
    local balance = Theme.Label("TextLabel", panel, "", 13)
    balance.Position = UDim2.fromOffset(10, 76)
    balance.Size = UDim2.new(1, -20, 0, 18)
    balance.TextXAlignment = Enum.TextXAlignment.Left
    balance.TextColor3 = Theme.Gold

    local waiting = false
    local back = Theme.Button(panel, "Trocar personagem", function()
        if waiting then
            return
        end
        waiting = true
        local ok, response = pcall(function()
            return request:InvokeServer("returnToMenu")
        end)
        waiting = false
        if not ok or not response or not response.Ok then
            identity.Text = if ok and response then response.Message else "Falha ao voltar ao menu."
        end
    end)
    back.Position = UDim2.fromOffset(8, 96)
    back.Size = UDim2.new(1, -16, 0, 40)

    local humanoid
    local healthChanged
    local function render()
        gui.Enabled = player:GetAttribute("ActiveCharacterId") ~= nil
        local name = player:GetAttribute("RoleName") or ""
        local rank = player:GetAttribute("RoleRank") or ""
        local organization = player.Team and player.Team.Name or "Civil"
        identity.Text = ("%s\n%s · %s"):format(name, organization, rank)
        local life = humanoid and humanoid.Health or 0
        vital.Text = ("Vida %d  ·  Colete %d"):format(math.ceil(life), player:GetAttribute("RoleArmor") or 0)
        balance.Text = ("R$ %d"):format(player:GetAttribute("RoleCash") or 0)
    end
    local function bind(character)
        if healthChanged then
            healthChanged:Disconnect()
            healthChanged = nil
        end
        humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            healthChanged = humanoid.HealthChanged:Connect(render)
        end
        render()
    end

    player.CharacterAdded:Connect(bind)
    player.CharacterRemoving:Connect(function()
        bind(nil)
    end)
    for _, name in ipairs({ "ActiveCharacterId", "RoleName", "RoleRank", "RoleCash", "RoleArmor" }) do
        player:GetAttributeChangedSignal(name):Connect(render)
    end
    player:GetPropertyChangedSignal("Team"):Connect(render)
    bind(player.Character)
end

return Hud
