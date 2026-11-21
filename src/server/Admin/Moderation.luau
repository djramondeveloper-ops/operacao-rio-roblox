local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local Moderation = {}

function Moderation.Filter(actor, value)
    local result = TextService:FilterStringAsync(value, actor.UserId, Enum.TextFilterContext.PublicChat)
    local filtered = result:GetNonChatStringForBroadcastAsync()
    if filtered == "" or not string.find(filtered, "[^#%s]") then
        return nil
    end
    return filtered
end

function Moderation.Apply(action, userId, player, reason, duration)
    if action == "kick" then
        if not player then
            return false, "Jogador indisponível neste servidor."
        end
        player:Kick(reason)
        return true, "Jogador expulso."
    end
    if RunService:IsStudio() or not Players.BanningEnabled then
        return false, "Banimentos exigem servidor publicado e Players.BanningEnabled."
    end
    if action == "ban" then
        Players:BanAsync({
            UserIds = { userId },
            Duration = duration,
            DisplayReason = reason,
            PrivateReason = "Ação administrativa OPERAÇÃO RIO",
            ExcludeAltAccounts = true,
            ApplyToUniverse = true,
        })
    else
        Players:UnbanAsync({ UserIds = { userId }, ApplyToUniverse = true })
    end
    return true, if action == "ban" then "Banimento aplicado." else "Banimento revogado."
end

return Moderation
