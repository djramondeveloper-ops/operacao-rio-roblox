local Players = game:GetService("Players")
local Appearance = require(game:GetService("ReplicatedStorage").Shared.Appearance)
local Theme = require(script.Parent.Theme)

local Preview = {}

function Preview.Create(parent)
    local frame = Instance.new("ViewportFrame")
    frame.Size = UDim2.new(1, 0, 0, 180)
    frame.BackgroundColor3 = Theme.Graphite
    frame.Ambient = Color3.fromRGB(185, 196, 217)
    frame.LightColor = Color3.fromRGB(246, 237, 221)
    frame.LightDirection = Vector3.new(-1, -1, -1)
    frame.Parent = parent
    Theme.Rounded(frame, 8)

    local camera = Instance.new("Camera")
    camera.FieldOfView = 40
    camera.Parent = frame
    frame.CurrentCamera = camera
    local world = Instance.new("WorldModel")
    world.Parent = frame

    local self = { Angle = 0, Zoom = 8.8 }
    local revision = 0
    local building = false
    local pending

    local function position()
        local direction = CFrame.Angles(0, self.Angle, 0).LookVector
        local center = Vector3.new(0, -0.30, 0)
        camera.CFrame = CFrame.lookAt(center + direction * self.Zoom + Vector3.new(0, 0.3, 0), center)
    end

    function self.Rotate(amount)
        self.Angle += amount
        position()
    end

    function self.ChangeZoom(amount)
        self.Zoom = math.clamp(self.Zoom + amount, 5.8, 11)
        position()
    end

    function self.Show(options, onError)
        revision += 1
        pending = { Options = table.clone(options), Revision = revision, Error = onError }
        if building then
            return
        end
        building = true
        task.spawn(function()
            while pending and frame.Parent do
                local job = pending
                pending = nil
                local description = Appearance.Description(job.Options)
                local ok, model = pcall(function()
                    return Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
                end)
                description:Destroy()
                if ok and model then
                    if frame.Parent and job.Revision == revision then
                        world:ClearAllChildren()
                        model:PivotTo(CFrame.new())
                        local root = model:FindFirstChild("HumanoidRootPart")
                        if root then
                            root.Anchored = true
                        end
                        Appearance.Apply(model, job.Options)
                        model.Parent = world
                    else
                        model:Destroy()
                    end
                elseif frame.Parent and job.Revision == revision then
                    job.Error("A prévia não carregou. Altere uma opção para tentar de novo.")
                end
            end
            building = false
        end)
    end

    position()
    return self, frame
end

return Preview
