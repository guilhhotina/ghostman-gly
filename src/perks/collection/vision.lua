-- vision perk: zoom out da camera pra ver o maze inteiro

local const = require('src/const')

return {
    id = "vision",
    name = "ALL-SEEYING EYE",
    desc = "camera zoom-out. see the whole maze!",
    icon = "[o]",
    type = "passive",
    color = 0x88ff88FF,
    apply = function(p)
        p.zoom_out = true
    end
}
