-- tela de evolucao do ghostman
-- mostra a arvore de perks e quais o player ja tem
-- diagrama circular com conexoes entre perks

local const = require('src/const')
local common = require('src/view/ui/common')

local P = {}

-- desenha a tela de evolucao
-- player pode ser nil se ainda nao iniciou o jogo
function P.draw(std, player)
    local sw, sh = std.app.width, std.app.height

    -- titulo
    std.text.font_size(24)
    std.draw.color(const.pal.ui_select)
    local title_w = std.text.mensure("evolution tree")
    std.text.print(sw / 2 - title_w / 2, 40, "evolution tree")

    -- centro do diagrama
    local cx, cy = sw / 2, sh / 2 + 30
    local radius = 120

    -- definicao dos nos da arvore
    -- cada no = um perk ou estado
    -- check: funcao que ve se o player tem esse perk
    local nodes = {
        -- start: ponto inicial (sempre ativo)
        { name = "start",     x = 0,              y = -radius,        check = nil },
        -- speed: perk de velocidade
        { name = "speed",     x = radius * 0.95,  y = -radius * 0.31, check = function(p) return p and p.speed_mod < 0 end },
        -- vision: perk de zoom
        { name = "vision",    x = radius * 0.59,  y = radius * 0.81,  check = function(p) return p and p.zoom_out end },
        -- fear: perk de aura de medo
        { name = "fear",      x = -radius * 0.59, y = radius * 0.81,  check = function(p) return p and p.has_fear_aura end },
        -- ethereal: perk de atravessar paredes
        { name = "ethereal",  x = -radius * 0.95, y = -radius * 0.31, check = function(p) return p and p.wall_hack end },
        -- boomstick: perk de shotgun
        { name = "boomstick", x = 0,              y = 0,              check = function(p) return p and p.has_shotgun end }
    }

    -- desenha conexoes (linhas entre os nos)
    std.draw.color(const.pal.ui_border)
    local connections = {
        { 1, 3 }, { 3, 5 }, { 5, 2 }, { 2, 4 }, { 4, 1 }, -- circulo exterior
        { 1, 6 }, { 3, 6 }, { 5, 6 }                      -- conexoes ao centro (boomstick)
    }

    for _, pair in ipairs(connections) do
        local n1, n2 = nodes[pair[1]], nodes[pair[2]]
        std.draw.line(cx + n1.x, cy + n1.y, cx + n2.x, cy + n2.y)
    end

    -- desenha os nos (retangulos com nome)
    for i, node in ipairs(nodes) do
        local nx, ny = cx + node.x, cy + node.y
        local active = node.check and node.check(player)

        -- cores: verde se ativo, cinza se nao
        local bg = active and const.pal.ui_success or const.pal.ui_panel
        local border = active and const.pal.text_highlight or const.pal.ui_border
        local txt_col = active and const.pal.bg or const.pal.text

        -- start sempre destacado
        if node.name == "start" then
            bg = const.pal.ui_select
            txt_col = const.pal.bg
        end

        -- desenha retangulo
        std.draw.color(bg)
        std.draw.rect(0, nx - 35, ny - 12, 70, 24)
        std.draw.color(border)
        std.draw.rect(1, nx - 35, ny - 12, 70, 24)

        -- nome
        std.text.font_size(10)
        std.draw.color(txt_col)
        local name_w = std.text.mensure(node.name)
        std.text.print(nx - name_w / 2, ny - 5, node.name)
    end

    -- habilidades especiais (dash e chains)
    if player and (player.has_dash or player.has_chains) then
        std.draw.color(const.pal.ui_select)
        std.draw.rect(0, cx - 40, cy - 15, 80, 30)
        std.draw.color(const.pal.bg)
        std.draw.rect(1, cx - 40, cy - 15, 80, 30)

        std.text.font_size(10)
        std.draw.color(const.pal.ui_select)
        common.text_centered(std, "ultimate", cx, cy - 4, 10, const.pal.ui_select)
    end

    -- instrucoes
    std.text.font_size(12)
    std.draw.color(const.pal.text_dim)
    common.text_centered(std, "[z] return to menu", sw / 2, sh - 40, 12, const.pal.text_dim)
end

return P
