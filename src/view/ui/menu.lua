-- menu do ghostman
-- desenha a tela de menu

local const = require('src/const')
local framework = require('src/view/ui/framework')
local painters = require('src/view/skins/painters')
local P = {}
local menu_items = { "start", "evolution", "credits", "exit" }

function P.draw(std, cursor)
    local sw, sh = std.app.width, std.app.height
    std.draw.clear(const.pal.bg)

    -- particulas flutuantes no bg
    for i = 1, 15 do
        local t = std.milis / (2000 + i * 100)
        local x = (math.sin(i * 132 + t) * sw * 0.45) + sw / 2
        local y = (math.cos(i * 94 + t) * sh * 0.45) + sh / 2
        local alpha = math.floor(math.abs(math.sin(t * 3)) * 100) + 50
        std.draw.color(const.pal.ui_border - 0xFF + alpha)
        std.draw.rect(0, x, y, 2, 2)
    end

    -- logo com animacao de bobbing
    local bob = math.sin(std.milis / 400) * 4
    local pixel_size = math.max(4, math.floor(sw / 80))
    painters.logo_pixel(std, sw / 2, sh / 4 + bob, pixel_size, const.pal.ui_border, const.pal.ui_shadow)

    -- painel do menu
    local menu_w, menu_h = 220, 200
    local menu_x = sw / 2 - menu_w / 2
    local menu_y = sh / 2
    framework.panel(std, {
        x = menu_x,
        y = menu_y,
        w = menu_w,
        h = menu_h,
        style = "fancy",
        border = const.pal.ui_select
    })

    -- botoes do menu
    local btn_w, btn_h = 180, 32
    local start_y = menu_y + 25
    local gap = 42
    for i, item in ipairs(menu_items) do
        local y = start_y + (i - 1) * gap
        local selected = (cursor == i)
        framework.button(std, item, sw / 2 - btn_w / 2, y, btn_w, btn_h, selected)
    end

    -- separador e controles
    framework.separator(std, sw / 2 - 100, sh - 45, 200)
    framework.text(std, "[z] select   [arrows] navigate", sw / 2, sh - 30, {
        size = 10, align = "center", color = const.pal.text_dim
    })
end

return P
