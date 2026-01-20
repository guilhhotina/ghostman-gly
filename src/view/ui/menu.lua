-- menu principal

local C = require('src/const')
local fw = require('src/view/ui/framework')
local painters = require('src/view/skins/painters')

local items = { "start", "evolution", "credits", "exit" }

local function draw(std, cursor)
    local sw, sh = std.app.width, std.app.height
    std.draw.clear(C.pal.bg)

    -- particulas de fundo
    for i = 1, 15 do
        local t = std.milis / (2000 + i * 100)
        local x = math.sin(i * 132 + t) * sw * 0.45 + sw / 2
        local y = math.cos(i * 94 + t) * sh * 0.45 + sh / 2
        local a = math.floor(math.abs(math.sin(t * 3)) * 100) + 50

        std.draw.color(C.pal.ui_border - 0xFF + a)
        std.draw.rect(0, x, y, 2, 2)
    end

    -- logo
    local bob = math.sin(std.milis / 400) * 4
    local ps = math.max(4, math.floor(sw / 80))
    painters.logo_pixel(std, sw / 2, sh / 4 + bob, ps, C.pal.ui_border, C.pal.ui_shadow)

    -- painel
    local mw, mh = 220, 200
    local mx = sw / 2 - mw / 2
    local my = sh / 2

    fw.panel(std, { x = mx, y = my, w = mw, h = mh, style = "fancy", border = C.pal.ui_select })

    -- botoes
    local bw, bh = 180, 32
    local start_y = my + 25
    local gap = 42

    for i, item in ipairs(items) do
        local y = start_y + (i - 1) * gap
        fw.button(std, item, sw / 2 - bw / 2, y, bw, bh, cursor == i)
    end

    -- controles
    fw.separator(std, sw / 2 - 100, sh - 45, 200)
    fw.text(std, "[z] select   [arrows] navigate", sw / 2, sh - 30, {
        size = 10,
        align = "center",
        color = C.pal.text_dim
    })
end

return { draw = draw }
