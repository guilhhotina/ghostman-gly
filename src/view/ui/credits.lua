-- tela de creditos do ghostman
-- mostra infos sobre o dev e agradecimentos

local const = require('src/const')
local common = require('src/view/ui/common')

local P = {}

-- draw da tela de creditos
function P.draw(std)
    local sw, sh = std.app.width, std.app.height

    -- painel de fundo
    common.panel(std, sw / 2 - 200, sh / 2 - 180, 400, 360, const.pal.ui_bg, const.pal.ui_border)

    -- titulo
    std.text.font_size(28)
    std.draw.color(const.pal.ui_border)
    local title_w = std.text.mensure("credits")
    std.text.print(sw / 2 - title_w / 2, sh / 2 - 140, "credits")

    -- linha divisoria
    std.draw.color(const.pal.ui_dim)
    std.draw.rect(0, sw / 2 - 100, sh / 2 - 110, 200, 2)

    -- desenvolvedor
    std.text.font_size(14)
    std.draw.color(const.pal.ui_select)
    local dev_w = std.text.mensure("developed by")
    std.text.print(sw / 2 - dev_w / 2, sh / 2 - 80, "developed by")

    -- nome do dev
    std.text.font_size(20)
    std.draw.color(const.pal.text)
    local guily_w = std.text.mensure("guilhhotina")
    std.text.print(sw / 2 - guily_w / 2, sh / 2 - 55, "guilhhotina")

    -- versao
    std.text.font_size(12)
    std.draw.color(const.pal.text_dim)
    local v_w = std.text.mensure("v2.5.0")
    std.text.print(sw / 2 - v_w / 2, sh / 2 - 25, "v2.5.0")

    -- linha divisoria 2
    std.draw.color(const.pal.ui_dim)
    std.draw.rect(0, sw / 2 - 80, sh / 2, 160, 2)

    -- agradecimentos
    std.text.font_size(14)
    std.draw.color(const.pal.ui_border)
    local thanks_w = std.text.mensure("special thanks")
    std.text.print(sw / 2 - thanks_w / 2, sh / 2 + 20, "special thanks")

    -- msgs deagradecimento
    std.text.font_size(12)
    std.draw.color(const.pal.text_dim)
    std.text.print(sw / 2 - 60, sh / 2 + 45, "you for playing!")
    std.text.print(sw / 2 - 50, sh / 2 + 65, "donatello")

    -- instrucao de volta ao menu
    std.text.font_size(10)
    std.draw.color(const.pal.text_dim)
    local back_w = std.text.mensure("[a] back to menu")
    std.text.print(sw / 2 - back_w / 2, sh / 2 + 130, "[a] back to menu")
end

return P
