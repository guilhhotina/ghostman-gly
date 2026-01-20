-- fear perk
-- terror visage: congela o critter quando perto
-- inútil se o critter estiver corajoso (parado demais)!

return {
    id = "fear",
    name = "terror visage",
    desc = "freezes prey nearby. useless if they're brave!",
    icon = "(@)",
    type = "passive",
    color = 0xff4488FF,
    apply = function(p)
        p.has_fear_aura = true
        p.fear_radius = (p.fear_radius or 0) + 3
    end
}
