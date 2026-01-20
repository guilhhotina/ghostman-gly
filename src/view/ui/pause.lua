-- ghostman/src/view/ui/pause.lua
-- menu de pause
-- overlay transparente sobre o jogo com opcoes

local C = require('src/const')
local fw = require('src/view/ui/framework')

local items = { "resume", "quit to menu", "exit game" }

local function draw(std, G)
    local sw, sh = std.app.width, std.app.height

    -- overlay escuro (mais transparente que gameover)
    std.draw.color(0x000000AA)
    std.draw.rect(0, 0, 0, sw, sh)

    -- painel central
    local pw, ph = 240, 200
    local px, py = sw / 2 - pw / 2, sh / 2 - ph / 2

    fw.panel(std, {
        x = px,
        y = py,
        w = pw,
        h = ph,
        style = "fancy",
        border = C.pal.ui_select
    })

    -- titulo
    fw.text(std, "paused", sw / 2, py + 25, {
        size = 24,
        align = "center",
        color = C.pal.ui_border,
        shadow = true
    })

    -- separador
    fw.separator(std, px + 20, py + 55, pw - 40)

    -- botoes
    local bw, bh = 180, 32
    local start_y = py + 70
    local gap = 40

    for i, item in ipairs(items) do
        local y = start_y + (i - 1) * gap
        local sel = G.pause_cursor == i
        fw.button(std, item, sw / 2 - bw / 2, y, bw, bh, sel)
    end

    -- hint de controles
    fw.text(std, "[p] quick resume", sw / 2, py + ph - 20, {
        size = 10,
        align = "center",
        color = C.pal.text_dim
    })
end

return { draw = draw }
