local RunService = game:GetService("RunService")
local Settings = require(script.Parent.Parent.Settings)

local Careers = {}

Careers.Paths = {
    civil = { "Morador", "Trabalhador", "Comerciante" },
    pmerj = { "Recruta", "Soldado", "Cabo", "Sargento" },
    bope = { "Candidato", "Operador", "Comandante" },
    aurora = { "Ingressante", "Integrante", "Líder" },
    horizonte = { "Ingressante", "Integrante", "Líder" },
}

function Careers.CanJoin(player, organization)
    if not Careers.Paths[organization] then
        return false
    end
    local allowlist = Settings.PoliceAccess[organization]
    if not allowlist then
        return true
    end
    return (Settings.StudioOpenPoliceTeams and RunService:IsStudio()) or allowlist[player.UserId] == true
end

function Careers.Enter(character, organization)
    if not character.Careers[organization] then
        character.Careers[organization] = 1
    end
    character.Team = organization
end

function Careers.Title(character)
    local path = Careers.Paths[character.Team]
    return path and path[character.Careers[character.Team]] or "Morador"
end

return Careers
