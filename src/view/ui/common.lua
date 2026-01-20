-- wrapper de compatibilidade

local fw = require('src/view/ui/framework')
local C = require('src/const')

return {
    panel = function(std, x, y, w, h, color, border)
        fw.panel(std, { x = x, y = y, w = w, h = h, color = color, border = border, style = "fancy" })
    end,
    text_centered = function(std, text, x, y, size, color)
        return fw.text(std, text, x, y, { size = size, color = color, align = "center", shadow = true })
    end,
    button = fw.button,
    bar = function() end
}
