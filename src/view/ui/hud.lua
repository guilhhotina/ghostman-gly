-- HUD do jogo

local C = require('src/const')
local fw = require('src/view/ui/framework')

local fps_smooth = 60

local function update_fps(std)
    local cur = 1000 / (std.delta + 0.001)
    fps_smooth = fps_smooth + (cur - fps_smooth) * 0.1
    return fps_smooth
end

local function draw(std, G, show_fps)
    local sw, sh = std.app.width, std.app.height
    local p = G.player

    -- painel de info
    fw.panel(std, { x = 8, y = 8, w = 140, h = 50, style = "flat" })
    fw.text(std, "level", 18, 14, { size = 11, color = C.pal.text_dim })
    fw.text(std, tostring(G.level), 70, 11, { size = 18, color = C.pal.text })
    fw.text(std, "dots: " .. G.dots, 18, 35, { size = 12, color = C.pal.dot, shadow = true })

    -- fps
    if show_fps == 1 then
        local fps = update_fps(std)
        local col = fps > 50 and C.pal.ui_success or C.pal.ui_warning
        fw.text(std, "fps: " .. math.floor(fps), sw - 40, 15, {
            size = 10,
            align = "right",
            color = col,
            shadow = true
        })
    end

    -- fade warning
    if G.fade_active then
        if math.floor(std.milis / 200) % 2 == 0 then
            fw.text(std, "!", 100, 37, { size = 10, color = C.pal.ui_warning })
        end
    end

    -- hint de pause (canto superior direito)
    fw.text(std, "[p] pause", sw - 10, 8, {
        size = 9,
        align = "right",
        color = C.pal.text_dim
    })

    -- skill slots
    local ss = 24
    local gap = 8
    local sx = sw / 2 - (ss * 3 + gap * 2) / 2
    local sy = sh - 40
    local keys = { "[z]", "[x]", "[c]" }

    for i = 1, 3 do
        local perk = p.actives and p.actives[i]
        local cd = 0

        if perk then
            if perk.id == "shotgun" and G.shotgun_cooldown > 0 then
                cd = G.shotgun_cooldown / 900
            elseif (perk.id == "dash" or perk.id == "chains") and G.ability_cooldown > 0 then
                local max = perk.id == "chains" and 5000 or 2000
                cd = G.ability_cooldown / max
            end
        end

        fw.skill_slot(std, sx + (i - 1) * (ss + gap), sy, ss, keys[i], perk, cd)
    end

    -- aiming text
    if p.aiming then
        fw.text(std, "[ release to fire ]", sw / 2, sh - 60, {
            size = 10,
            align = "center",
            color = C.pal.critter,
            shadow = true
        })
    end
end

return { draw = draw, update_fps = update_fps }
