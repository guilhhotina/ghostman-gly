-- render do ghostman
-- desenha o jogo na tela

local const = require('src/const')
local skins = require('src/view/skins/init')
local effects = require('src/view/effects')
local ui = require('src/view/ui/init')
local math_floor, math_max, math_min = math.floor, math.max, math.min

-- camera
local cam = { x = 0, y = 0, zoom = 1 }

-- funcao principal de desenho
local function draw_game(std, G)
    -- se for menu, so desenha ui
    if G.state == const.state.menu or G.state == const.state.credits or G.state == const.state.evolution then
        ui.draw(std, G)
        return
    end

    local p = G.player
    if not p then
        ui.draw(std, G); return
    end

    local dt = std.delta
    local target_zoom = p.zoom_out and 0.55 or 1.15
    cam.zoom = cam.zoom + (target_zoom - cam.zoom) * (p.zoom_out and 0.04 or 0.08)

    -- tamanho do tile na tela
    local cs = math_max(8, math_floor(math_min(std.app.width, std.app.height) / 20 * cam.zoom))

    -- camera segue o player
    cam.x = cam.x + (p.real_x - cam.x) * 0.08
    cam.y = cam.y + (p.real_y - cam.y) * 0.08

    -- offset base
    local ox = math_floor(std.app.width / 2 - cam.x * cs)
    local oy = math_floor(std.app.height / 2 - cam.y * cs)

    -- shake effect
    if G.shake > 0 then
        ox = ox + math.sin(std.milis * 0.05) * G.shake * 0.5
        oy = oy + math.cos(std.milis * 0.065) * G.shake * 0.5
    end

    -- calcula area visivel
    local vl, vt = math_floor(-ox / cs), math_floor(-oy / cs)
    local vr, vb = vl + math_floor(std.app.width / cs) + 2, vt + math_floor(std.app.height / cs) + 2
    vl, vt, vr, vb = math_max(1, vl), math_max(1, vt), math_min(G.w, vr), math_min(G.h, vb)

    -- desenha tiles visiveis
    for y = vt, vb do
        local row = G.grid[y]
        if row then
            for x = vl, vr do
                local tile = row[x]
                local light = 1.0
                local d = (x - p.real_x) ^ 2 + (y - p.real_y) ^ 2

                -- luz baseda na distancia
                if d > (p.zoom_out and 1200 or 144) then
                    light = 0.2
                else
                    light = math_max(0.2, 1.0 - d / (p.zoom_out and 1200 or 144))
                end

                local dx, dy = ox + (x - 1) * cs, oy + (y - 1) * cs

                -- desenha tile baseado no tipo
                if tile == const.tile.wall then
                    skins.draw(std, "wall", x, y, dx, dy, cs, light, std.milis, {})
                elseif tile == const.tile.empty then
                    skins.draw(std, "floor", x, y, dx, dy, cs, light, std.milis,
                        { dread = p.has_dread and p.dread_tiles and p.dread_tiles[x .. "," .. y] })
                elseif tile == const.tile.dot then
                    skins.draw(std, "dot", x, y, dx, dy, cs, light, std.milis, {})
                elseif tile == const.tile.fading then
                    skins.draw(std, "dot_fading", x, y, dx, dy, cs, light, std.milis, {})
                end
            end
        end
    end

    -- effects (particulas)
    effects.draw(std, cs, ox, oy, G)

    -- critter
    local c = G.critter
    if c and G.state ~= const.state.capture then
        skins.draw(std, "critter", c.real_x, c.real_y, ox + (c.real_x - 1) * cs, oy + (c.real_y - 1) * cs, cs, 1.0,
            std.milis,
            { dir = c.curr_dir, scared = c.scared, brave = c.brave, chained = c.chained, squash = c.squash })
    end

    -- player
    skins.draw(std, "player", p.real_x, p.real_y, ox + (p.real_x - 1) * cs, oy + (p.real_y - 1) * cs, cs, 1.0, std.milis,
        {
            has_shotgun = p.has_shotgun,
            has_dash = p.has_dash,
            has_chains = p.has_chains,
            dir = p.curr_dir,
            aiming = p.aiming,
            aim_angle = p.aim_angle,
            dashing = p.dashing,
            squash = p.squash
        })

    -- ui
    ui.draw(std, G, false)
end

return { draw = draw_game }
