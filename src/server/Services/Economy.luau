local Economy = {}
local MAX_MONEY = 1000000000
local HISTORY_SIZE = 30

function Economy.Positive(value)
    return type(value) == "number" and value % 1 == 0 and value >= 1 and value <= MAX_MONEY
end

function Economy.ValidLedger(data)
    if data.TransactionSequence == nil then
        return data.Transactions == nil
    end
    if not Economy.Positive(data.TransactionSequence) or type(data.Transactions) ~= "table"
        or #data.Transactions < 1 or #data.Transactions > HISTORY_SIZE then
        return false
    end
    local count = 0
    for index, entry in pairs(data.Transactions) do
        if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > #data.Transactions
            or type(entry) ~= "table" or not Economy.Positive(entry.Amount)
            or type(entry.Kind) ~= "string" or type(entry.Timestamp) ~= "number"
            or entry.Id ~= data.Id .. ":" .. tostring(data.TransactionSequence - #data.Transactions + index) then
            return false
        end
        count += 1
    end
    return count == #data.Transactions
end

function Economy.Apply(data, sequence, kind, amount)
    local expected = (data.TransactionSequence or 0) + 1
    if not Economy.Positive(sequence) or sequence ~= expected then
        return false, "Transação já consultada ou fora de sequência. Atualize o painel."
    end
    if not Economy.Positive(amount) then
        return false, "Valor inválido."
    end

    local cash, bank = data.Cash, data.Bank
    if kind == "deposit" then
        cash -= amount
        bank += amount
    elseif kind == "withdraw" then
        bank -= amount
        cash += amount
    elseif kind == "purchase" then
        cash -= amount
    elseif kind == "sale" or kind == "salary" then
        cash += amount
    else
        return false, "Operação monetária inválida."
    end
    if cash < 0 or bank < 0 or cash > MAX_MONEY or bank > MAX_MONEY then
        return false, "Saldo ou limite insuficiente."
    end

    data.Cash, data.Bank = cash, bank
    data.TransactionSequence = sequence
    local history = data.Transactions or {}
    data.Transactions = history
    table.insert(history, {
        Id = data.Id .. ":" .. tostring(sequence),
        Kind = kind,
        Amount = amount,
        Timestamp = os.time(),
    })
    if #history > HISTORY_SIZE then
        table.remove(history, 1)
    end
    return true, "Transação confirmada."
end

return Economy
