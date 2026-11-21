local Lighting = game:GetService("Lighting")
local MessagingService = game:GetService("MessagingService")
local RunService = game:GetService("RunService")

local City = {}
local topic = "OperacaoRio_AdminCity_v1"
local signal
local subscription
local recent = {}
local originalFog = Lighting.FogEnd

local function receive(packet)
    if type(packet) ~= "table" or type(packet.Id) ~= "string" or recent[packet.Id] then
        return
    end
    recent[packet.Id] = true
    task.delay(60, function() recent[packet.Id] = nil end)
    if packet.Action == "announce" and type(packet.Value) == "string" then
        signal:FireAllClients("announcement", packet.Value)
    elseif packet.Action == "settime" and type(packet.Value) == "number" then
        Lighting.ClockTime = packet.Value
    elseif packet.Action == "setweather" and (packet.Value == "fog" or packet.Value == "clear") then
        Lighting.FogEnd = if packet.Value == "fog" then 175 else originalFog
    end
end

function City.Start(event)
    signal = event
    if not RunService:IsStudio() then
        task.spawn(function()
            for attempt = 1, 3 do
                local ok, result = pcall(function()
                    return MessagingService:SubscribeAsync(topic, function(message)
                        receive(message.Data)
                    end)
                end)
                if ok then
                    subscription = result
                    break
                end
                warn("[OPERAÇÃO RIO] Falha na inscrição administrativa", attempt)
                task.wait(attempt)
            end
        end)
    end
end

function City.Apply(id, action, value)
    local packet = { Id = id, Action = action, Value = value }
    if RunService:IsStudio() then
        receive(packet)
        return true, "Aplicado à sessão local do Studio."
    end
    if not subscription then
        return false, "Canal global indisponível."
    end
    MessagingService:PublishAsync(topic, packet)
    receive(packet)
    return true, "Enviado aos servidores ativos."
end

return City
