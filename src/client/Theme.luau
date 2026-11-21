local TweenService = game:GetService("TweenService")

local Theme = {
    Graphite = Color3.fromHex("#101419"),
    Blue = Color3.fromHex("#1769AA"),
    Gold = Color3.fromHex("#D4AF37"),
    White = Color3.fromHex("#F5F7FA"),
    Red = Color3.fromHex("#C93636"),
    Surface = Color3.fromHex("#222C37"),
    ReducedMotion = false,
}

function Theme.Tween(instance, seconds, properties)
    local tween = TweenService:Create(instance, TweenInfo.new(
        if Theme.ReducedMotion then 0 else seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out
    ), properties)
    tween:Play()
    return tween
end

function Theme.Rounded(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
end

function Theme.Label(kind, parent, caption, size)
    local text = Instance.new(kind)
    text.Text = caption
    text.TextSize = size
    text.TextColor3 = Theme.White
    text.Font = Enum.Font.GothamMedium
    text.TextWrapped = true
    text.BackgroundTransparency = 1
    text.Parent = parent
    return text
end

function Theme.Button(parent, caption, callback)
    local button = Theme.Label("TextButton", parent, caption, 15)
    button.Size = UDim2.new(1, 0, 0, 44)
    button.BackgroundTransparency = 0
    button.BackgroundColor3 = Theme.Surface
    button.AutoButtonColor = false
    Theme.Rounded(button, 8)
    button.MouseEnter:Connect(function()
        Theme.Tween(button, 0.15, { BackgroundColor3 = Theme.Blue })
    end)
    button.MouseLeave:Connect(function()
        Theme.Tween(button, 0.15, { BackgroundColor3 = Theme.Surface })
    end)
    button.Activated:Connect(callback)
    return button
end

return Theme
