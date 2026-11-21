return table.freeze({
    Slots = 12,
    MaxGrams = 8000,
    Catalog = table.freeze({
        agua = table.freeze({ Name = "Água", Grams = 500, Stack = 6 }),
        lanche = table.freeze({ Name = "Lanche", Grams = 250, Stack = 6 }),
        radio = table.freeze({ Name = "Rádio", Grams = 800, Stack = 1 }),
    }),
})
