-- tela de upgrade do ghostman
-- mostra cards de perks pra escolher

local const = require('src/const')
local framework = require('src/view/ui/framework')

local P = {}

function P.draw(std, options, cursor)
    local sw, sh = std.app.width, std.app.height
    local cx = sw / 2
    local num_opts = #options

    -- overlay escuro
    std.draw.color(const.pal.ui_dim)
    std.draw.rect(0, 0, 0, sw, sh)

    -- painel principal
    local panel_w = math.max(200, 140 * num_opts + 40)
    local panel_h = 280
    local py = sh / 2 - panel_h / 2

    framework.panel(std, {
        x = cx - panel_w / 2,
        y = py,
        w = panel_w,
        h = panel_h,
        style = "fancy"
    })

    -- titulo
    framework.text(std, "evolution!", cx, py + 25, {
        size = 24,
        align = "center",
        color = const.pal.text_highlight,
        shadow = true
    })

    -- bonus por captura rapida
    if num_opts > 2 then
        framework.text(std, "fast capture bonus!", cx, py + 52, {
            size = 11,
            align = "center",
            color = const.pal.ui_success
        })
    end

    -- sem perks disponiveis
    if num_opts == 0 then
        framework.text(std, "maximum power reached!", cx, sh / 2, {
            align = "center",
            color = const.pal.text_dim
        })
        return
    end

    -- cards de perks
    local card_w, card_h = 120, 170
    local gap = 15
    local total_w = card_w * num_opts + gap * (num_opts - 1)
    local start_x = cx - total_w / 2
    local card_y = sh / 2 - 30

    for i, opt in ipairs(options) do
        if not opt then break end

        local card_x = start_x + (i - 1) * (card_w + gap)
        local selected = (cursor == i)

        -- highlight externo se selecionado
        if selected then
            std.draw.color(const.pal.ui_border)
            std.draw.rect(0, card_x - 4, card_y - 4, card_w + 8, card_h + 8)
        end

        local bg = selected and const.pal.ui_select or const.pal.ui_panel
        local border = selected and const.pal.text_highlight or const.pal.ui_border

        -- desenha card
        framework.panel(std, {
            x = card_x,
            y = card_y,
            w = card_w,
            h = card_h,
            color = bg,
            border = border,
            style = selected and "fancy" or "flat"
        })

        -- nome do perk
        local name_col = selected and const.pal.bg or const.pal.text
        framework.text(std, opt.name or "unknown", card_x + card_w / 2, card_y + 18, {
            size = 11,
            align = "center",
            color = name_col
        })

        -- icone grande
        std.text.font_size(32)
        std.draw.color(opt.color or (selected and const.pal.bg or const.pal.ui_border))
        local icon_w = std.text.mensure(opt.icon or "?")
        std.text.print(card_x + card_w / 2 - icon_w / 2, card_y + 45, opt.icon or "?")

        -- descricao com wordwrap simples
        framework.separator(std, card_x + 10, card_y + 85, card_w - 20)

        local desc = opt.desc or ""
        local max_chars = 18
        local line_y = card_y + 95
        local pos = 1
        local desc_col = selected and const.pal.bg or const.pal.text_dim

        while pos <= #desc and line_y < card_y + card_h - 25 do
            local end_pos = math.min(pos + max_chars - 1, #desc)
            local line = string.sub(desc, pos, end_pos)
            framework.text(std, line, card_x + card_w / 2, line_y, {
                size = 9,
                align = "center",
                color = desc_col
            })
            line_y = line_y + 11
            pos = end_pos + 1
        end

        -- tipo (active ou passive)
        local type_text = opt.type == "active" and "[active]" or "[passive]"
        local type_color = opt.type == "active" and const.pal.critter or const.pal.ally_leapy
        if selected then type_color = const.pal.bg end

        framework.text(std, type_text, card_x + card_w / 2, card_y + card_h - 18, {
            size = 8,
            align = "center",
            color = type_color
        })
    end
end

return P
