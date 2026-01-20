-- speed perk: +25% movement speed, stacks twice

return {
    id = "speed",
    name = "SPECTRAL HASTE",
    desc = "Movement +25%. Stacks twice!",
    icon = ">>>",
    type = "passive",
    color = 0x44ddffFF,
    apply = function(p)
        p.speed_mod = (p.speed_mod or 0) - 30
    end
}
