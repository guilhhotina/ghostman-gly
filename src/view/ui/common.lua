-- ui common do ghostman
-- wrapper de compatibilidade pro codigo antigo

local framework = require('src/view/ui/framework')
local const = require('src/const')

local P = {}

-- painel antigo com o sistema novo (fancy)
function P.panel(std, x, y, w, h, color, border)
    framework.panel(std, {
        x = x,
        y = y,
        w = w,
        h = h,
        color = color,
        border = border,
        style = "fancy"
    })
end

-- texto centralizado
function P.text_centered(std, text, x, y, size, color)
    local w, _ = framework.text(std, text, x, y, {
        size = size,
        color = color,
        align = "center",
        shadow = true
    })
    return w
end

-- botao
function P.button(std, text, x, y, w, h, selected)
    framework.button(std, text, x, y, w, h, selected)
end

-- barra de progresso
function P.bar(std, x, y, w, h, pct, color_fill, color_bg)
    framework.progress_bar(std, x, y, w, h, pct, color_fill)
end

return P
