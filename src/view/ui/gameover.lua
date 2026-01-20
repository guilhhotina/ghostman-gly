-- tela de game over do ghostman
-- desenha a tela quando o jogador perde
-- perde se: critter come todos os dots, ou critter te come (se ficar parado demais)

local const = require('src/const')
local common = require('src/view/ui/common')

local P = {}

-- mensagem baseada na razao da morte
local function get_death_message(reason)
    if reason == "eaten" then
        return "you stood still... and became the prey!"
    elseif reason == "starved" then
        return "the critter survived... you starved!"
    else
        return "the hunt has ended..."
    end
end

-- draw da tela de game over
function P.draw(std)
    local sw, sh = std.app.width, std.app.height

    -- overlay escuro
    std.draw.color(const.pal.ui_dim)
    std.draw.rect(0, 0, 0, sw, sh)

    -- painel central
    common.panel(std, sw / 2 - 140, sh / 2 - 80, 280, 160, const.pal.ui_panel, const.pal.ui_border)

    -- titulo
    common.text_centered(std, "game over", sw / 2, sh / 2 - 50, 24, const.pal.ui_select)

    -- subtitulo dinamico com a razao da morte
    std.text.font_size(14)
    std.draw.color(const.pal.text_dim)

    local death_reason = rawget(_G, "G") and rawget(_G, "G").death_reason
    local msg = get_death_message(death_reason)

    std.text.print(sw / 2 - 100, sh / 2 - 10, msg)

    -- mensagem de reinicio (pisca)
    std.text.font_size(12)
    if math.floor(std.milis / 500) % 2 == 0 then
        std.draw.color(const.pal.ui_select)
        std.text.print(sw / 2 - 50, sh / 2 + 30, "press z to restart")
    end

    -- versao do jogo
    std.draw.color(const.pal.text_dim)
    std.text.font_size(10)
    std.text.print(10, sh - 20, "v2.5.0")
end

return P
