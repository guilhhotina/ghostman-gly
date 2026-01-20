-- render otimizado
-- tecnicas NES: tile culling, sprite batching, cache de cores

local C = require('src/const')
local skins = require('src/view/skins/init')
local effects = require('src/view/effects')
local ui = require('src/view/ui/init')

local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local math_sin = math.sin

-- camera state
local cam = { x = 0, y = 0, zoom = 1 }

-- helper pro grid 1D
local function grid_get(G, x, y)
    if x < 1 or x > G.w or y < 1 or y > G.h then return C.T_WALL end
    return G.grid[(y - 1) * G.w + x]
end

-- draw principal
local function draw_game(std, G)
    -- menu/credits/evolution: so UI
    if G.state == C.S_MENU or G.state == C.S_CREDITS or G.state == C.S_EVOLUTION then
        ui.draw(std, G)
        return
    end

    local p = G.player
    if not p then
        ui.draw(std, G)
        return
    end

    local dt = std.delta
    local sw, sh = std.app.width, std.app.height

    -- zoom (nao atualiza se pausado)
    if G.state ~= C.S_PAUSE then
        local target_zoom = p.zoom_out and 0.55 or 1.15
        local zoom_speed = p.zoom_out and 0.04 or 0.08
        cam.zoom = cam.zoom + (target_zoom - cam.zoom) * zoom_speed
    end

    -- tile size
    local cs = math_max(8, math_floor(math_min(sw, sh) / 20 * cam.zoom))

    -- camera follow (nao atualiza se pausado)
    if G.state ~= C.S_PAUSE then
        cam.x = cam.x + (p.real_x - cam.x) * C.smooth.camera_lerp
        cam.y = cam.y + (p.real_y - cam.y) * C.smooth.camera_lerp
    end

    -- offset
    local ox = math_floor(sw / 2 - cam.x * cs)
    local oy = math_floor(sh / 2 - cam.y * cs)

    -- shake
    if G.shake > 0 then
        ox = ox + math_sin(std.milis * 0.05) * G.shake * 0.5
        oy = oy + math.cos(std.milis * 0.065) * G.shake * 0.5
    end

    -- culling bounds (visivel na tela)
    local vl = math_floor(-ox / cs)
    local vt = math_floor(-oy / cs)
    local vr = vl + math_floor(sw / cs) + 2
    local vb = vt + math_floor(sh / cs) + 2

    vl = math_max(1, vl)
    vt = math_max(1, vt)
    vr = math_min(G.w, vr)
    vb = math_min(G.h, vb)

    -- luz base (distancia ao quadrado)
    local light_max = p.zoom_out and 1200 or 144

    -- desenha tiles visiveis
    for y = vt, vb do
        for x = vl, vr do
            local tile = grid_get(G, x, y)

            -- calcula luz
            local dx = x - p.real_x
            local dy = y - p.real_y
            local d2 = dx * dx + dy * dy
            local light = d2 > light_max and 0.2 or math_max(0.2, 1.0 - d2 / light_max)

            local px = ox + (x - 1) * cs
            local py = oy + (y - 1) * cs

            -- desenha baseado no tipo
            if tile == C.T_WALL then
                skins.draw(std, "wall", x, y, px, py, cs, light, std.milis, nil)
            elseif tile == C.T_EMPTY then
                local dread = p.has_dread and p.dread_tiles and p.dread_tiles[x .. "," .. y]
                skins.draw(std, "floor", x, y, px, py, cs, light, std.milis, dread)
            elseif tile == C.T_DOT then
                skins.draw(std, "dot", x, y, px, py, cs, light, std.milis, nil)
            elseif tile == C.T_FADING then
                skins.draw(std, "dot_fading", x, y, px, py, cs, light, std.milis, nil)
            end
        end
    end

    -- effects
    effects.draw(std, cs, ox, oy, G)

    -- critter
    local c = G.critter
    if c and G.state ~= C.S_CAPTURE then
        local cx = ox + (c.real_x - 1) * cs
        local cy = oy + (c.real_y - 1) * cs
        skins.draw_critter(std, cx, cy, cs, c, std.milis)
    end

    -- player
    local px = ox + (p.real_x - 1) * cs
    local py = oy + (p.real_y - 1) * cs
    skins.draw_player(std, px, py, cs, p, std.milis)

    -- UI
    ui.draw(std, G, false)
end

return { draw = draw_game }
