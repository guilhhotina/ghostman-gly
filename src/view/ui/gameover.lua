-- tela de game over

local C = require('src/const')
local fw = require('src/view/ui/framework')

local function get_msg(reason)
    if reason == "eaten" then
        return "you stood still..."
    elseif reason == "starved" then
        return "the critter survived..."
    end
    return "the hunt has ended..."
end

local function draw(std, G)
    local sw, sh = std.app.width, std.app.height

    std.draw.color(C.pal.ui_dim)
    std.draw.rect(0, 0, 0, sw, sh)

    fw.panel(std, { x = sw / 2 - 140, y = sh / 2 - 80, w = 280, h = 160 })

    fw.text(std, "game over", sw / 2, sh / 2 - 50, {
        size = 24,
        align = "center",
        color = C.pal.ui_select
    })

    fw.text(std, get_msg(G.death_reason), sw / 2, sh / 2 - 10, {
        size = 14,
        align = "center",
        color = C.pal.text_dim
    })

    if math.floor(std.milis / 500) % 2 == 0 then
        fw.text(std, "press z to restart", sw / 2, sh / 2 + 30, {
            size = 12,
            align = "center",
            color = C.pal.ui_select
        })
    end
end

return { draw = draw }
