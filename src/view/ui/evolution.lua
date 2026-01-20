-- arvore de evolucao

local C = require('src/const')
local fw = require('src/view/ui/framework')

local function draw(std, player)
    local sw, sh = std.app.width, std.app.height

    fw.text(std, "evolution tree", sw / 2, 40, {
        size = 24,
        align = "center",
        color = C.pal.ui_select
    })

    local cx, cy = sw / 2, sh / 2 + 30
    local r = 120

    local nodes = {
        { name = "start", x = 0, y = -r, check = nil },
        { name = "speed", x = r * 0.95, y = -r * 0.31, check = function(p) return p and p.speed_mod < 0 end },
        { name = "vision", x = r * 0.59, y = r * 0.81, check = function(p) return p and p.zoom_out end },
        { name = "fear", x = -r * 0.59, y = r * 0.81, check = function(p) return p and p.has_fear_aura end },
        { name = "ethereal", x = -r * 0.95, y = -r * 0.31, check = function(p) return p and p.wall_hack end },
        { name = "shotgun", x = 0, y = 0, check = function(p) return p and p.has_shotgun end }
    }

    local conns = { { 1, 3 }, { 3, 5 }, { 5, 2 }, { 2, 4 }, { 4, 1 }, { 1, 6 }, { 3, 6 }, { 5, 6 } }

    std.draw.color(C.pal.ui_border)
    for _, c in ipairs(conns) do
        local a, b = nodes[c[1]], nodes[c[2]]
        std.draw.line(cx + a.x, cy + a.y, cx + b.x, cy + b.y)
    end

    for _, n in ipairs(nodes) do
        local nx, ny = cx + n.x, cy + n.y
        local active = n.check and n.check(player)

        local bg = active and C.pal.ui_success or C.pal.ui_panel
        local txt = active and C.pal.bg or C.pal.text

        if n.name == "start" then
            bg = C.pal.ui_select
            txt = C.pal.bg
        end

        std.draw.color(bg)
        std.draw.rect(0, nx - 35, ny - 12, 70, 24)

        std.draw.color(active and C.pal.text_highlight or C.pal.ui_border)
        std.draw.rect(1, nx - 35, ny - 12, 70, 24)

        std.text.font_size(10)
        std.draw.color(txt)
        local w = std.text.mensure(n.name)
        std.text.print(nx - w / 2, ny - 5, n.name)
    end

    fw.text(std, "[z] back to menu", sw / 2, sh - 40, {
        size = 12,
        align = "center",
        color = C.pal.text_dim
    })
end

return { draw = draw }
