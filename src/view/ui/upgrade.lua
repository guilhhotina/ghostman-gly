-- tela de upgrade

local C = require('src/const')
local fw = require('src/view/ui/framework')

local function draw(std, options, cursor)
    local sw, sh = std.app.width, std.app.height
    local cx = sw / 2
    local num = #options

    std.draw.color(C.pal.ui_dim)
    std.draw.rect(0, 0, 0, sw, sh)

    local pw = math.max(200, 140 * num + 40)
    local ph = 280
    local py = sh / 2 - ph / 2

    fw.panel(std, { x = cx - pw / 2, y = py, w = pw, h = ph, style = "fancy" })

    fw.text(std, "evolution!", cx, py + 25, {
        size = 24,
        align = "center",
        color = C.pal.text_highlight,
        shadow = true
    })

    if num > 2 then
        fw.text(std, "fast capture bonus!", cx, py + 52, {
            size = 11,
            align = "center",
            color = C.pal.ui_success
        })
    end

    if num == 0 then
        fw.text(std, "maximum power!", cx, sh / 2, {
            align = "center",
            color = C.pal.text_dim
        })
        return
    end

    local cw, ch = 120, 170
    local gap = 15
    local tw = cw * num + gap * (num - 1)
    local sx = cx - tw / 2
    local cy = sh / 2 - 30

    for i, opt in ipairs(options) do
        if not opt then break end

        local x = sx + (i - 1) * (cw + gap)
        local sel = cursor == i

        if sel then
            std.draw.color(C.pal.ui_border)
            std.draw.rect(0, x - 4, cy - 4, cw + 8, ch + 8)
        end

        fw.panel(std, {
            x = x,
            y = cy,
            w = cw,
            h = ch,
            color = sel and C.pal.ui_select or C.pal.ui_panel,
            border = sel and C.pal.text_highlight or C.pal.ui_border,
            style = sel and "fancy" or "flat"
        })

        fw.text(std, opt.name or "?", x + cw / 2, cy + 18, {
            size = 11,
            align = "center",
            color = sel and C.pal.bg or C.pal.text
        })

        std.text.font_size(32)
        std.draw.color(opt.color or C.pal.ui_border)
        local iw = std.text.mensure(opt.icon or "?")
        std.text.print(x + cw / 2 - iw / 2, cy + 45, opt.icon or "?")

        fw.separator(std, x + 10, cy + 85, cw - 20)

        -- desc wordwrap
        local desc = opt.desc or ""
        local line_y = cy + 95
        local pos = 1

        while pos <= #desc and line_y < cy + ch - 25 do
            local end_pos = math.min(pos + 17, #desc)
            fw.text(std, desc:sub(pos, end_pos), x + cw / 2, line_y, {
                size = 9,
                align = "center",
                color = sel and C.pal.bg or C.pal.text_dim
            })
            line_y = line_y + 11
            pos = end_pos + 1
        end

        local tt = opt.type == "active" and "[active]" or "[passive]"
        local tc = opt.type == "active" and C.pal.critter or C.pal.ui_success
        if sel then tc = C.pal.bg end

        fw.text(std, tt, x + cw / 2, cy + ch - 18, {
            size = 8,
            align = "center",
            color = tc
        })
    end
end

return { draw = draw }
