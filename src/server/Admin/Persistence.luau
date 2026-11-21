local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Config = require(script.Parent.Config)
local studio = RunService:IsStudio()
local store = if not studio or Config.StudioPersistence then DataStoreService:GetDataStore(
    if studio then "OperacaoRio_AdminStudio" else "OperacaoRio_Admin"
) else nil
local memory = {}
local Persistence = {}

function Persistence.Read(key)
    if store then
        local options = Instance.new("DataStoreGetOptions")
        options.UseCache = false
        return store:GetAsync(key, options)
    end
    return memory[key]
end

function Persistence.Update(key, transform)
    if store then
        return store:UpdateAsync(key, transform)
    end
    local nextValue = transform(memory[key])
    if nextValue ~= nil then
        memory[key] = nextValue
    end
    return nextValue
end

return Persistence
