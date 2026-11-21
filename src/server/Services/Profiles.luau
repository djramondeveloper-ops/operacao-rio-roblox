local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Items = require(ReplicatedStorage.Shared.Items)
local Settings = require(script.Parent.Parent.Settings)

local LEASE = 180
local AUTOSAVE = 45
local studio = RunService:IsStudio()
local persistent = not studio or Settings.StudioPersistence
local store = if persistent then DataStoreService:GetDataStore(
    if studio then "OperacaoRio_Studio" else "OperacaoRio_Profiles"
) else nil

local memory = {}
local sessions = {}
local shuttingDown = false
local Profiles = {}

local function update(key, transform)
    if store then
        return store:UpdateAsync(key, transform)
    end
    local nextValue = transform(memory[key])
    if nextValue then
        memory[key] = nextValue
    end
    return nextValue
end

local function decode(data)
    if type(data) ~= "table" or data.Version ~= 1 or type(data.Slots) ~= "table"
        or type(data.Team) ~= "string" then
        return nil
    end

    local slots = {}
    local grams = 0
    for key, slot in pairs(data.Slots) do
        local index = tonumber(key)
        local definition = if type(slot) == "table" and type(slot.Id) == "string"
            then Items.Catalog[slot.Id] else nil
        if type(key) ~= "string" or not index or index % 1 ~= 0
            or index < 1 or index > Items.Slots or tostring(index) ~= key
            or not definition or type(slot.Count) ~= "number" or slot.Count % 1 ~= 0
            or slot.Count < 1 or slot.Count > definition.Stack then
            return nil
        end
        slots[key] = { Id = slot.Id, Count = slot.Count }
        grams += definition.Grams * slot.Count
    end
    if grams > Items.MaxGrams then
        return nil
    end
    return { Version = 1, Team = data.Team, Slots = slots }
end

local function newData()
    return {
        Version = 1,
        Team = "civil",
        Slots = {
            ["1"] = { Id = "agua", Count = 2 },
            ["2"] = { Id = "lanche", Count = 1 },
        },
    }
end

local function save(session, release)
    local snapshot = decode(session.Data)
    if not snapshot then
        warn("[OPERAÇÃO RIO] Perfil em memória inválido", session.Key)
        return false, false
    end

    session.Busy = true
    local ok, result = pcall(update, session.Key, function(record)
        if not record or record.Owner ~= session.Token then
            return nil
        end
        if release then
            return { Data = snapshot }
        end
        return { Data = snapshot, Owner = session.Token, Expires = os.time() + LEASE }
    end)
    session.Busy = false

    if not ok then
        warn("[OPERAÇÃO RIO] Falha ao salvar perfil", session.Key, result)
        return false, false
    end
    if not result then
        session.Expires = 0
        return false, true
    end
    session.Expires = result.Expires or 0
    return true, false
end

local function close(player, session)
    if session.Closing then
        return
    end
    session.Closing = true
    while session.Busy do
        task.wait()
    end
    if session.Data then
        for attempt = 1, 3 do
            local saved, ownershipLost = save(session, true)
            if saved or ownershipLost then
                break
            end
            if attempt < 3 then
                task.wait(attempt)
            end
        end
    end
    sessions[player] = nil
end

function Profiles.Get(player)
    local session = sessions[player]
    if session and not session.Closing and session.Expires and session.Expires > os.time() then
        return session.Data
    end
    return nil
end

local function loadPlayer(player, onLoaded)
    if shuttingDown or sessions[player] or player.Parent ~= Players then
        return
    end
    local session = {
        Key = "player_" .. player.UserId,
        Token = HttpService:GenerateGUID(false),
        Busy = true,
    }
    sessions[player] = session
    for attempt = 1, 4 do
        if session.Closing then
            break
        end
        local ok, record = pcall(update, session.Key, function(current)
            if session.Closing then
                return nil
            end
            local now = os.time()
            if current ~= nil and type(current) ~= "table" then
                return nil
            end
            if current and current.Owner and current.Owner ~= session.Token
                and (type(current.Expires) ~= "number" or current.Expires > now) then
                return nil
            end
            local data = if current == nil then newData() else decode(current.Data)
            if not data then
                return nil
            end
            return { Data = data, Owner = session.Token, Expires = now + LEASE }
        end)
        if ok and record then
            session.Data = decode(record.Data)
            session.Expires = record.Expires
            break
        end
        if not ok then
            warn("[OPERAÇÃO RIO] Falha ao carregar perfil", session.Key, record)
        end
        if attempt < 4 and not session.Closing then
            task.wait(attempt * 2)
        end
    end
    session.Busy = false
    if session.Closing then
        return
    end
    if shuttingDown or player.Parent ~= Players then
        close(player, session)
    elseif Profiles.Get(player) then
        onLoaded(player, session.Data)
    else
        sessions[player] = nil
        player:Kick("Não foi possível abrir seu perfil. Tente novamente em instantes.")
    end
end

function Profiles.Start(onLoaded)
    Players.PlayerRemoving:Connect(function(player)
        local session = sessions[player]
        if session then
            close(player, session)
        end
    end)
    Players.PlayerAdded:Connect(function(player)
        loadPlayer(player, onLoaded)
    end)
    for _, player in Players:GetPlayers() do
        task.spawn(loadPlayer, player, onLoaded)
    end
    task.spawn(function()
        while not shuttingDown do
            task.wait(AUTOSAVE)
            if shuttingDown then
                break
            end
            for player, session in pairs(sessions) do
                if session.Data and not session.Busy and not session.Closing then
                    task.spawn(function()
                        if session.Closing then
                            return
                        end
                        if session.Expires > os.time() then
                            save(session, false)
                        end
                        if session.Expires <= os.time() and not session.Closing then
                            player:Kick("Sua sessão de dados expirou. Entre novamente.")
                        end
                    end)
                end
            end
        end
    end)
    game:BindToClose(function()
        shuttingDown = true
        local deadline = os.clock() + 25
        for player, session in pairs(sessions) do
            task.spawn(close, player, session)
        end
        while next(sessions) and os.clock() < deadline do
            task.wait()
        end
    end)
end

return Profiles
