local Lighting = game:GetService("Lighting")
local Theme = require(script.Parent.Theme)

local Scene = {}
local model
local cameraTween
local savedCameraType

local origin = Vector3.new(0, 3200, 0)
local viewStart = CFrame.lookAt(origin + Vector3.new(42, 28, 75), origin + Vector3.new(0, 12, -15))
local viewEnd = CFrame.lookAt(origin + Vector3.new(17, 24, 64), origin + Vector3.new(-10, 9, -24))

local function block(name, position, size, color, material)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Size = size
    part.Position = origin + position
    part.Color = color
    part.Material = material or Enum.Material.Concrete
    part.Parent = model
end

function Scene.Open()
    if model then
        return
    end
    model = Instance.new("Model")
    model.Name = "OperacaoRioMenuScene"
    model.Parent = workspace
    block("Base", Vector3.new(0, -1, 0), Vector3.new(165, 2, 160), Theme.Graphite)
    local random = Random.new(4321)
    for row = 1, 4 do
        for column = 1, 8 do
            local x, z = (column - 4.5) * 16, -row * 16
            local h = random:NextInteger(8, 25 + row * 4)
            block("Edifício", Vector3.new(x, h / 2, z), Vector3.new(12, h, 10),
                Theme.Surface:Lerp(Theme.Graphite, random:NextNumber(0, 0.6)))
            for floor = 1, math.floor(h / 6) do
                block("Janelas", Vector3.new(x, floor * 5, z + 5.06), Vector3.new(8, 0.30, 0.14),
                    if column % 3 == 0 then Theme.Gold else Theme.Blue, Enum.Material.Neon)
            end
        end
    end
    block("Via", Vector3.new(0, 0.04, 16), Vector3.new(160, 0.08, 20), Color3.fromRGB(39, 44, 53))
    for index = -5, 5 do
        block("Faixa", Vector3.new(index * 12, 0.10, 16), Vector3.new(5, 0.06, 0.2), Theme.Gold)
    end
    local effect = Instance.new("ColorCorrectionEffect")
    effect.Name = "OperacaoRioMenuGrade"
    effect.Contrast = 0.25
    effect.TintColor = Color3.fromRGB(191, 219, 255)
    effect.Parent = Lighting
    Scene.Effect = effect

    local camera = workspace.CurrentCamera
    if camera then
        savedCameraType = camera.CameraType
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = viewStart
        camera.Focus = CFrame.new(origin)
        cameraTween = Theme.Tween(camera, 8, { CFrame = viewEnd })
    end
end

function Scene.Close(character)
    if cameraTween then
        cameraTween:Cancel()
        cameraTween = nil
    end
    if model then
        model:Destroy()
        model = nil
    end
    if Scene.Effect then
        Scene.Effect:Destroy()
        Scene.Effect = nil
    end
    local camera = workspace.CurrentCamera
    if camera then
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            camera.CameraSubject = humanoid
        end
        camera.CameraType = if savedCameraType == Enum.CameraType.Scriptable then Enum.CameraType.Custom
            else savedCameraType or Enum.CameraType.Custom
    end
end

return Scene
