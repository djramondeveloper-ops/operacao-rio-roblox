local Config = require(script.Parent.Config)
local Persistence = require(script.Parent.Persistence)
local Audit = {}

function Audit.Write(entry)
    Persistence.Update("audit_v1", function(old)
        assert(old == nil or type(old) == "table", "Histórico administrativo inválido")
        local records = {}
        local cutoff = os.time() - Config.AuditRetentionDays * 86400
        for _, row in ipairs(old or {}) do
            if row.At >= cutoff and (row.Id ~= entry.Id or row.Result ~= entry.Result) then
                table.insert(records, row)
            end
        end
        table.insert(records, entry)
        while #records > Config.AuditCapacity do
            table.remove(records, 1)
        end
        return records
    end)
end

function Audit.Read(target, action, page, disciplineOnly)
    local records = Persistence.Read("audit_v1") or {}
    local results = {}
    local matched = 0
    local cutoff = os.time() - Config.AuditRetentionDays * 86400
    for index = #records, 1, -1 do
        local row = records[index]
        local discipline = row.Action == "kick" or row.Action == "ban" or row.Action == "unban"
        if row.At >= cutoff and (not target or row.Target == target) and (not action or row.Action == action)
            and (not disciplineOnly or discipline and row.Result == "ok") then
            matched += 1
            if matched > (page - 1) * 15 and #results < 15 then
                table.insert(results, row)
            end
        end
    end
    return results, matched > page * 15
end

return Audit
