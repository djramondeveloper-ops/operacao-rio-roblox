-- Configuração inicial. Comunidades são referências ficcionais, não reproduções exatas.
local GameConfig = {}

GameConfig.Communities = {
    "Complexo do Alemão",
    "Rocinha",
    "Cidade de Deus",
    "Vidigal",
    "Jacarezinho",
    "Vila Cruzeiro",
    "Morro do Borel",
}

GameConfig.Organizations = { "PMERJ", "BOPE" }
GameConfig.Territory = {
    MinimumAttackers = 3,
    MinimumDefenders = 3,
    CooldownSeconds = 3600,
    CaptureSeconds = 600,
}
GameConfig.VIP = {
    Ouro = { PassId = 0 },
    Diamante = { PassId = 0 },
    Supremo = { PassId = 0 },
}

return GameConfig
