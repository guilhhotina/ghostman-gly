-- hud do ghostman
-- mostra level, dots, fps e slots de habilidades

local const = require('src/const')
local framework = require('src/view/ui/framework')

local P = {}
local fps_smooth = 60

-- update do fps com media movel
function P.update_fps(std)
    local current_fps = 1000 / (std.delta + 0.001)
    fps_smooth = fps_smooth + (current_fps - fps_smooth) * 0.1
    return fps_smooth
end

-- draw da hud
function P.draw(std, G, show_fps)
    local sw, sh = std.app.width, std.app.height
    local p = G.player

    -- painel superior com level e dots
    framework.panel(std, {
        x = 8,
        y = 8,
        w = 140,
        h = 50,
        style = "flat"
    })

    framework.text(std, "level", 18, 14, { size = 11, color = const.pal.text_dim })
    framework.text(std, tostring(G.level), 70, 11, { size = 18, color = const.pal.text })
    framework.text(std, "dots: " .. G.dots, 18, 35, { size = 12, color = const.pal.dot, shadow = true })

    -- contador de fps
    if show_fps == 1 then
        local fps = P.update_fps(std)
        local fps_col = fps > 50 and const.pal.ui_success or const.pal.ui_warning
        framework.text(std, "fps: " .. math.floor(fps), sw - 40, 15, {
            size = 10,
            align = "right",
            color = fps_col,
            shadow = true
        })
    end

    -- indicador de fade (anti-camping)
    if G.fade_active then
        local blink = math.floor(std.milis / 200) % 2 == 0
        if blink then
            framework.text(std, "!", 100, 37, { size = 10, color = const.pal.ui_warning })
        end
    end

    -- slots de habilidades
    local slot_size = 24
    local slot_gap = 8
    local start_x = sw / 2 - ((slot_size * 3 + slot_gap * 2) / 2)
    local start_y = sh - 40

    local keys = { "[z]", "[x]", "[c]" }

    for i = 1, 3 do
        local perk = p.actives and p.actives[i]
        local cooldown = 0

        if perk then
            if perk.id == "shotgun" and G.shotgun_cooldown > 0 then
                cooldown = G.shotgun_cooldown / 900
            elseif (perk.id == "dash" or perk.id == "chains") and G.ability_cooldown > 0 then
                local max_cd = perk.id == "chains" and 5000 or 2000
                cooldown = G.ability_cooldown / max_cd
            end
        end

        framework.skill_slot(std, start_x + (i - 1) * (slot_size + slot_gap), start_y, slot_size, keys[i], perk, cooldown)
    end

    -- texto de mira
    if p.aiming then
        local cx, cy = sw / 2, sh / 2
        framework.text(std, "[ release to fire ]", cx, sh - 60, {
            size = 10, align = "center", color = const.pal.critter, shadow = true
        })
    end
end

return P
