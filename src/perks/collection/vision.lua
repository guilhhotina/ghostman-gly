-- vision perk: zoom out da camera pra ver o maze inteiro

local const = require('src/const')

return {
    id = "vision",
    name = "all-seeing eye",
    desc = "zoom out da camera. ve o maze inteiro.",
    icon = "[o]",
    type = "passive",
    color = 0x88ff88FF,
    apply = function(p)
        p.zoom_out = true
    end
}
