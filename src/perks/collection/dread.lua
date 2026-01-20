-- dread perk
-- deixa um rastro de medo no chao
-- critter evita os tiles por 3 segundos

return {
    id = "dread",
    name = "LINGERING DREAD",
    desc = "leave a trail of fear. prey avoids your path for 3s.",
    icon = "~~~",
    type = "passive",
    color = 0x884488FF,
    apply = function(p)
        p.has_dread = true
        p.dread_tiles = {}
    end
}
