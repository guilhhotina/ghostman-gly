-- ui framework
-- otimizado: menos funcoes, mais direto

local C = require('src/const')

-- dither pattern
local function dither(std, x, y, w, h, color)
    std.draw.color(color)
    for py = y, y + h - 1, 4 do
        local off = ((py - y) / 4) % 2 == 0 and 0 or 2
        for px = x + off, x + w - 1, 4 do
            if px + 2 <= x + w and py + 2 <= y + h then
                std.draw.rect(0, px, py, 2, 2)
            end
        end
    end
end

-- painel
local function panel(std, opts)
    local x, y, w, h = opts.x, opts.y, opts.w, opts.h
    local bg = opts.color or C.pal.ui_panel
    local border = opts.border or C.pal.ui_border

    -- sombra
    std.draw.color(C.pal.ui_dim)
    std.draw.rect(0, x + 4, y + 4, w, h)

    -- fundo
    std.draw.color(bg)
    std.draw.rect(0, x, y, w, h)

    -- dither
    dither(std, x + 2, y + 2, w - 4, h - 4, 0x00000033)

    -- borda
    std.draw.color(opts.style == "fancy" and C.pal.ui_shadow or border)
    std.draw.rect(1, x, y, w, h)
end

-- texto
local function text(std, str, x, y, opts)
    opts = opts or {}
    std.text.font_size(opts.size or 12)

    local w = std.text.mensure(str)
    local fx = x

    if opts.align == "center" then
        fx = x - w / 2
    elseif opts.align == "right" then
        fx = x - w
    end

    if opts.shadow then
        std.draw.color(C.pal.ui_shadow)
        std.text.print(fx + 1, y + 1, str)
    end

    std.draw.color(opts.color or C.pal.text)
    std.text.print(fx, y, str)
    return w
end

-- botao
local function button(std, txt, x, y, w, h, sel)
    local bg = sel and C.pal.ui_select or C.pal.ui_panel
    local oy = sel and math.sin(std.milis * 0.01) * 1.5 or 0

    panel(std, {
        x = x,
        y = y + oy,
        w = w,
        h = h,
        color = bg,
        border = sel and C.pal.text_highlight or C.pal.ui_border,
        style = sel and "fancy" or "flat"
    })

    text(std, txt, x + w / 2, y + h / 2 - 6 + oy, {
        size = 12,
        color = sel and C.pal.bg or C.pal.text,
        align = "center",
        shadow = not sel
    })
end

-- separador
local function separator(std, x, y, w)
    std.draw.color(C.pal.ui_border)
    std.draw.rect(0, x, y, w, 1)
    std.draw.color(C.pal.ui_shadow)
    std.draw.rect(0, x, y + 1, w, 1)
end

-- slot de skill
local function skill_slot(std, x, y, s, key, perk, cd)
    std.draw.color(0x000000AA)
    std.draw.rect(0, x, y, s, s)

    std.draw.color(perk and perk.color or C.pal.ui_border)
    std.draw.rect(1, x, y, s, s)

    if perk then
        text(std, perk.icon, x + s / 2, y + s / 2 - 6, {
            size = 10,
            align = "center",
            color = perk.color
        })

        if cd > 0 then
            std.draw.color(0x000000CC)
            local ch = math.ceil(s * cd)
            std.draw.rect(0, x + 1, y + s - ch, s - 2, ch)
        end
    end

    text(std, key, x + s / 2, y + s + 4, {
        size = 8,
        align = "center",
        color = C.pal.text_dim,
        shadow = true
    })
end

return {
    panel = panel,
    text = text,
    button = button,
    separator = separator,
    skill_slot = skill_slot
}
