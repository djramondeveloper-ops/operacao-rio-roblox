local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Schema = require(script.Parent.ProfileSchema)
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

local function save(session, release, data)
    local snapshot = Schema.Decode(Schema.Copy(data or session.Data))
    if not snapshot then
        warn("[OPERAÇÃO RIO] Perfil em memória inválido", session.Key)
        return false, false
    end

    session.Busy = true
    local ok, result = pcall(update, session.Key, function(record)
        if type(record) ~= "table" or record.Owner ~= session.Token then
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
    if session.Data and not session.Uncertain then
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

local function usable(player)
    local session = sessions[player]
    if session and not session.Closing and not session.Frozen and session.Expires
        and session.Expires > os.time() then
        return session
    end
    return nil
end

function Profiles.GetAccount(player)
    local session = usable(player)
    return if session then session.Data else nil
end

function Profiles.Get(player)
    local session = usable(player)
    if session and session.ActiveId then
        for _, character in ipairs(session.Data.Characters) do
            if character.Id == session.ActiveId then
                return character
            end
        end
    end
    return nil
end

function Profiles.SetActive(player, characterId)
    local session = usable(player)
    if not session then
        return false
    end
    if characterId == nil then
        session.ActiveId = nil
        return true
    end
    for _, character in ipairs(session.Data.Characters) do
        if character.Id == characterId then
            session.ActiveId = characterId
            return true
        end
    end
    return false
end

-- Criação e exclusão só são confirmadas depois da gravação do novo perfil.
function Profiles.Commit(player, mutate)
    local session = usable(player)
    if not session or session.Busy then
        return false, "Perfil ocupado. Tente de novo em instantes."
    end
    local candidate = Schema.Copy(session.Data)
    local accepted, message = mutate(candidate)
    if not accepted then
        return false, message
    end
    session.Frozen = true
    local saved = save(session, false, candidate)
    if not saved then
        session.Uncertain = true
        session.Expires = 0
        if player.Parent == Players then
            player:Kick("Não foi possível confirmar a gravação. Reconecte para consultar seu perfil.")
        end
        return false, "Gravação indisponível."
    end
    session.Data = candidate
    session.Frozen = false
    return true, message
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
            local data = if current == nil then Schema.New() else Schema.Decode(current.Data)
            if not data then
                return nil
            end
            return { Data = data, Owner = session.Token, Expires = now + LEASE }
        end)
        if ok and record then
            session.Data = Schema.Decode(Schema.Copy(record.Data))
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
    elseif Profiles.GetAccount(player) then
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
                if session.Data and not session.Busy and not session.Closing and not session.Frozen then
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
