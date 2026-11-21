local Config = require(script.Parent.AvatarConfig)
local Appearance = {}
Appearance.Fields = table.freeze({ "Skin", "Hair", "Face", "Outfit", "Accessory" })

function Appearance.Sanitize(options)
    if type(options) ~= "table" then
        return nil
    end
    local copy = {}
    for _, field in ipairs(Appearance.Fields) do
        local choice = options[field]
        if type(choice) ~= "number" or choice % 1 ~= 0 or choice < 1 or choice > #Config[field] then
            return nil
        end
        copy[field] = choice
    end
    return copy
end

function Appearance.Description(options)
    local description = Instance.new("HumanoidDescription")
    local skin = Config.Skin[options.Skin][2]
    local shirt = Config.Outfit[options.Outfit][2]
    description.HeadColor = skin
    description.LeftArmColor = skin
    description.RightArmColor = skin
    description.TorsoColor = shirt
    description.LeftLegColor = Color3.fromRGB(43, 49, 57)
    description.RightLegColor = description.LeftLegColor
    return description
end

local function patch(parent, limb, name, color, size, offset)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Color = color
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
    part.CastShadow = false
    part.CFrame = limb.CFrame * CFrame.new(offset)
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = limb
    weld.Part1 = part
    weld.Parent = part
    part.Parent = parent
end

function Appearance.Apply(model, options)
    local head = model:FindFirstChild("Head")
    local torso = model:FindFirstChild("UpperTorso")
    if not head or not torso then
        return
    end
    local existing = model:FindFirstChild("Cosmetics")
    if existing then
        existing:Destroy()
    end
    local folder = Instance.new("Folder")
    folder.Name = "Cosmetics"
    folder.Parent = model

    local dark = Color3.fromRGB(32, 23, 27)
    local headSize = head.Size
    if options.Hair > 1 then
        local height = if options.Hair == 2 then 0.12 else 0.23
        patch(folder, head, "Cabelo", dark, Vector3.new(headSize.X * 0.85, height, headSize.Z * 0.87),
            Vector3.new(0, headSize.Y * 0.40 + height / 2, 0))
    end
    if options.Face > 1 then
        for _, direction in ipairs({ -1, 1 }) do
            local y = if options.Face == 2 then 0.17 else 0.22
            patch(folder, head, "Sobrancelha", dark, Vector3.new(headSize.X * 0.13, 0.03, 0.03),
                Vector3.new(headSize.X * direction * 0.17, headSize.Y * y, -headSize.Z * 0.47))
        end
    end
    if options.Accessory == 2 then
        patch(folder, torso, "Colete visual", Color3.fromRGB(36, 42, 51),
            Vector3.new(torso.Size.X * 0.75, torso.Size.Y * 0.74, 0.10),
            Vector3.new(0, 0, -torso.Size.Z / 2))
    elseif options.Accessory == 3 then
        patch(folder, head, "Faixa", Color3.fromRGB(151, 53, 61),
            Vector3.new(headSize.X * 0.85, 0.09, 0.10),
            Vector3.new(0, headSize.Y * 0.30, -headSize.Z * 0.45))
    end
end

return Appearance
