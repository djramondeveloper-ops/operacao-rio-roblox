local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local Commands = {}
local global = { announce = true, settime = true, setweather = true }

function Commands.Parse(action, input)
    local args = {}
    if not global[action] then
        local target, rest = input:match("^%s*(%S+)%s*(.*)$")
        args.Target = tonumber(target)
        input = rest or ""
    end
    if action == "kick" or action == "unban" or action == "announce" then
        args.Text = input
    elseif action == "ban" then
        local duration, reason = input:match("^(%S+)%s+(.+)$")
        args.Value, args.Text = tonumber(duration), reason
    elseif action == "giveitem" or action == "removeitem" then
        local key, value = input:match("^(%S+)%s+(%S+)%s*$")
        args.Key, args.Slot, args.Value = key, tonumber(key), tonumber(value)
    elseif action == "role" or action == "setteam" or action == "setweather" then
        args.Key = input:match("^%s*(%S+)%s*$")
    elseif action == "setmoney" or action == "givemoney" or action == "removemoney" or action == "settime" then
        args.Value = tonumber(input)
    elseif input:find("%S") then
        return nil
    end
    return args
end

function Commands.Start(catalog, dispatch, signal, pending)
    if TextChatService.ChatVersion ~= Enum.ChatVersion.TextChatService then
        return
    end
    local function bind(alias, alternate, callback)
        local command = Instance.new("TextChatCommand")
        command.Name = "OperacaoRio_" .. alias
        command.PrimaryAlias = "/" .. alias
        if alternate then
            command.SecondaryAlias = "/" .. alternate
        end
        command.Triggered:Connect(function(source, fullText)
            local player = source and Players:GetPlayerByUserId(source.UserId)
            if player then
                local input = fullText:match("^%s*%S+%s*(.*)$") or ""
                callback(player, input)
            end
        end)
        command.Parent = TextChatService
    end
    local function respond(player, response)
        signal:FireClient(player, "result", response)
    end
    bind("admin", nil, function(player)
        local response = dispatch(player, "open")
        if response.Ok then
            signal:FireClient(player, "open", response)
        else
            respond(player, response)
        end
    end)
    bind("confirmadmin", nil, function(player)
        respond(player, dispatch(player, "confirm", pending(player)))
    end)
    for _, tab in ipairs(catalog) do
        for index = 2, #tab do
            local action, _, syntax = table.unpack(tab[index])
            bind(action, if action == "goto" then "tp" else nil, function(player, input)
                local response = dispatch(player, action, Commands.Parse(action, input))
                if response.Token then
                    response.Message ..= " Use /confirmadmin em até 30 segundos."
                elseif response.Invalid then
                    response.Message = "/" .. action .. " " .. syntax
                end
                respond(player, response)
            end)
        end
    end
    for _, action in ipairs({ "spawncar", "deletecar", "repaircar" }) do
        bind(action, nil, function(player)
            local response = dispatch(player, "open")
            if response.Ok and response.Role == "FOUNDER" then
                respond(player, { Message = "Integração de veículos pendente." })
            end
        end)
    end
end

return Commands
