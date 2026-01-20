-- ethereal form
-- atravessa paredes livremente

return {
    id = "wall",
    name = "ethereal form",
    desc = "phase through walls freely. ultimate mobility.",
    icon = "[#]",
    type = "passive",
    color = 0xaa66ffFF,
    apply = function(p)
        p.wall_hack = true
    end
}
