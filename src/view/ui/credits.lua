-- creditos

local C = require('src/const')
local fw = require('src/view/ui/framework')

local function draw(std)
    local sw, sh = std.app.width, std.app.height

    fw.panel(std, { x = sw / 2 - 200, y = sh / 2 - 180, w = 400, h = 360 })

    fw.text(std, "credits", sw / 2, sh / 2 - 140, {
        size = 28,
        align = "center",
        color = C.pal.ui_border
    })

    std.draw.color(C.pal.ui_dim)
    std.draw.rect(0, sw / 2 - 100, sh / 2 - 110, 200, 2)

    fw.text(std, "developed by", sw / 2, sh / 2 - 80, {
        size = 14,
        align = "center",
        color = C.pal.ui_select
    })

    fw.text(std, "guilhhotina", sw / 2, sh / 2 - 55, {
        size = 20,
        align = "center",
        color = C.pal.text
    })

    fw.text(std, "v2.6.0", sw / 2, sh / 2 - 25, {
        size = 12,
        align = "center",
        color = C.pal.text_dim
    })

    std.draw.color(C.pal.ui_dim)
    std.draw.rect(0, sw / 2 - 80, sh / 2, 160, 2)

    fw.text(std, "special thanks", sw / 2, sh / 2 + 20, {
        size = 14,
        align = "center",
        color = C.pal.ui_border
    })

    fw.text(std, "you for playing!", sw / 2, sh / 2 + 45, {
        size = 12,
        align = "center",
        color = C.pal.text_dim
    })

    fw.text(std, "donatello", sw / 2, sh / 2 + 65, {
        size = 12,
        align = "center",
        color = C.pal.text_dim
    })

    fw.text(std, "[z] back to menu", sw / 2, sh / 2 + 130, {
        size = 10,
        align = "center",
        color = C.pal.text_dim
    })
end

return { draw = draw }
