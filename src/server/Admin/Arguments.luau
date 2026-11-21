local Config = require(script.Parent.Config)
local Permissions = require(script.Parent.Permissions)
local Arguments = {}
local integer = {
    ban = { -1, Config.MaxBanDays },
    setmoney = { 0, Config.MaxCashChange },
    givemoney = { 1, Config.MaxCashChange },
    removemoney = { 1, Config.MaxCashChange },
    settime = { 0, 23 },
    giveitem = { 1, Config.MaxItemQuantity },
    removeitem = { 1, Config.MaxItemQuantity },
}
local withoutTarget = { announce = true, settime = true, setweather = true }
local text = { announce = 200, kick = 160, ban = 160, unban = 160 }
local strings = { giveitem = true, setteam = true, role = true, setweather = true }

function Arguments.Parse(action, raw)
    if type(raw) ~= "table" then
        return nil
    end
    local result = {}
    if not withoutTarget[action] and (action ~= "logs" or raw.Target ~= nil) then
        if not Permissions.UserId(raw.Target) then
            return nil
        end
        result.Target = raw.Target
    end
    local bounds = integer[action]
    if bounds then
        local value = raw.Value
        if type(value) ~= "number" or value % 1 ~= 0 or value < bounds[1] or value > bounds[2]
            or (action == "ban" and value == 0) then
            return nil
        end
        result.Value = value
    end
    if text[action] then
        local value = raw.Text
        if type(value) ~= "string" or #value > text[action] or not value:find("%S") or utf8.len(value) == nil then
            return nil
        end
        result.Text = value
    end
    if strings[action] then
        local key = raw.Key
        if type(key) ~= "string" or #key > 40 or not key:match("^[%w_]+$") then
            return nil
        end
        if action == "setweather" and key ~= "clear" and key ~= "fog" then
            return nil
        end
        result.Key = key
    end
    if action == "removeitem" then
        if not Permissions.UserId(raw.Slot) or raw.Slot > 100 then
            return nil
        end
        result.Slot = raw.Slot
    elseif action == "logs" or action == "history" then
        local page = raw.Page or 1
        if not Permissions.UserId(page) or page > math.ceil(Config.AuditCapacity / 15) then
            return nil
        end
        if raw.Key ~= nil and (type(raw.Key) ~= "string" or Config.Permissions[raw.Key] == nil) then
            return nil
        end
        result.Page = page
        result.Key = raw.Key
    end
    return result
end

return Arguments
