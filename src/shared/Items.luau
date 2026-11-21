local function item(name, description, category, grams, stack, properties)
    local definition = properties or {}
    definition.Name = name
    definition.Description = description
    definition.Category = category
    definition.Grams = grams
    definition.Stack = stack
    return table.freeze(definition)
end

return table.freeze({
    Slots = 12,
    MaxGrams = 8000,
    BackpackSlots = 6,
    BackpackGrams = 4000,
    Catalog = table.freeze({
        agua = item("Água", "Garrafa de água.", "Consumíveis", 500, 6),
        lanche = item("Lanche", "Refeição leve embalada.", "Consumíveis", 250, 6),
        radio = item("Rádio", "Equipamento de comunicação.", "Equipamentos", 800, 1, { Durability = 100 }),
        celular = item("Celular", "Aparelho móvel. Aplicativos pendentes.", "Equipamentos", 220, 1),
        mochila = item("Mochila", "Adiciona seis slots e quatro quilos de capacidade.", "Equipamentos", 450, 1),
        kit_medico = item("Kit médico", "Recupera até 25 pontos de vida.", "Consumíveis", 600, 3, { Heal = 25 }),
        colete = item("Colete", "Equipamento de proteção.", "Equipamentos", 1600, 1, { Durability = 100 }),
        algemas = item("Algemas", "Equipamento de serviço autorizado.", "Policial", 350, 1,
            { PoliceOnly = true, Durability = 100 }),
        documento = item("Documentos", "Pasta de documentos do personagem.", "Utilidades", 30, 1),
        ferramentas = item("Ferramentas", "Kit básico de manutenção.", "Utilidades", 950, 1, { Durability = 100 }),
        municao_servico = item("Munição de serviço", "Carga de munição do equipamento de serviço.", "Policial", 25, 50,
            { PoliceOnly = true }),
        escudo = item("Escudo", "Equipamento reservado ao BOPE.", "Policial", 2800, 1,
            { PoliceOnly = true, Organization = "bope", Rank = 2, Durability = 100 }),
    }),
})
