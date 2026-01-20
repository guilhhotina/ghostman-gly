-- ui framework do ghostman
-- funcoes basicas de ui: panels, buttons, text, etc

local const = require('src/const')
local P = {}

-- desenha um padrao de dither (xadrez)
local function draw_dither(std, x, y, w, h, color)
    std.draw.color(color)
    for py = y, y + h - 1, 4 do
        local offset = ((py - y) / 4) % 2 == 0 and 0 or 2
        for px = x + offset, x + w - 1, 4 do
            if px + 2 <= x + w and py + 2 <= y + h then std.draw.rect(0, px, py, 2, 2) end
        end
    end
end

-- painel com borda e sombra
function P.panel(std, opts)
    local bg, light, dark = opts.color or const.pal.ui_panel, opts.border or const.pal.ui_border, const.pal.ui_shadow
    local x, y, w, h = opts.x, opts.y, opts.w, opts.h
    std.draw.color(const.pal.ui_dim); std.draw.rect(0, x + 4, y + 4, w, h)
    std.draw.color(bg); std.draw.rect(0, x, y, w, h)
    draw_dither(std, x + 2, y + 2, w - 4, h - 4, 0x00000033)
    std.draw.color(opts.style == "fancy" and dark or light)
    std.draw.rect(1, x, y, w, h)
end

-- texto com sombra opcional
function P.text(std, str, x, y, opts)
    opts = opts or {}
    std.text.font_size(opts.size or 12)
    local w = std.text.mensure(str)
    local fx = opts.align == "center" and x - w / 2 or (opts.align == "right" and x - w or x)
    if opts.shadow then
        std.draw.color(const.pal.ui_shadow); std.text.print(fx + 1, y + 1, str)
    end
    std.draw.color(opts.color or const.pal.text)
    std.text.print(fx, y, str)
    return w
end

-- botao com animacao de selecao
function P.button(std, text, x, y, w, h, selected)
    local bg = selected and const.pal.ui_select or const.pal.ui_panel
    local oy = selected and math.sin(std.milis * 0.01) * 1.5 or 0
    P.panel(std,
        {
            x = x,
            y = y + oy,
            w = w,
            h = h,
            color = bg,
            border = selected and const.pal.text_highlight or
                const.pal.ui_border,
            style = selected and "fancy" or "flat"
        })
    P.text(std, text, x + w / 2, y + h / 2 - 6 + oy,
        { size = 12, color = selected and const.pal.bg or const.pal.text, align = "center", shadow = not selected })
end

-- linha separadora
function P.separator(std, x, y, w)
    std.draw.color(const.pal.ui_border); std.draw.rect(0, x, y, w, 1)
    std.draw.color(const.pal.ui_shadow); std.draw.rect(0, x, y + 1, w, 1)
end

-- slot de habilidade com cooldown
function P.skill_slot(std, x, y, s, key, perk, cooldown_pct)
    std.draw.color(0x000000AA); std.draw.rect(0, x, y, s, s)
    std.draw.color(perk and perk.color or const.pal.ui_border); std.draw.rect(1, x, y, s, s)
    if perk then
        P.text(std, perk.icon, x + s / 2, y + s / 2 - 6, { size = 10, align = "center", color = perk.color })
        if cooldown_pct > 0 then
            std.draw.color(0x000000CC)
            std.draw.rect(0, x + 1, y + s - math.ceil(s * cooldown_pct), s - 2, math.ceil(s * cooldown_pct))
        end
    end
    P.text(std, key, x + s / 2, y + s + 4, { size = 8, align = "center", color = const.pal.text_dim, shadow = true })
end

return P
