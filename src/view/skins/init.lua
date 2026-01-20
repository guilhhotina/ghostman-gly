-- skins do ghostman
-- cache de cores com quantizacao

local painters = require('src/view/skins/painters')
local C = require('src/const')

-- cache de cores (evita recalcular)
local color_cache = {}
local cache_size = 0
local MAX_CACHE = 256
local last_clear = 0

-- quantiza luz (0.1 steps = 10 valores possiveis)
local function quantize_light(light)
    return math.floor(light * 10 + 0.5) / 10
end

-- aplica luz com cache
local function apply_light(color, light, milis)
    -- limpa cache periodicamente
    if milis and milis - last_clear > 15000 then
        color_cache = {}
        cache_size = 0
        last_clear = milis
    end

    local q = quantize_light(light)
    local key = color * 100 + math.floor(q * 100)

    if color_cache[key] then
        return color_cache[key]
    end

    -- calcula cor com luz
    local l = math.min(1.3, math.max(0, light))
    local r = math.floor(color / 0x1000000)
    local g = math.floor((color / 0x10000) % 0x100)
    local b = math.floor((color / 0x100) % 0x100)
    local a = color % 0x100

    r = math.min(255, math.floor(r * l))
    g = math.min(255, math.floor(g * l))
    b = math.min(255, math.floor(b * l))

    local result = r * 0x1000000 + g * 0x10000 + b * 0x100 + a

    if cache_size < MAX_CACHE then
        color_cache[key] = result
        cache_size = cache_size + 1
    end

    return result
end

-- cores base
local WALL_TOP = C.pal.wall_top
local WALL_SIDE = C.pal.wall_side
local FLOOR_COL = 0x101020FF
local DOT_COL = C.pal.dot
local DOT_GLOW = C.pal.dot_glow
local GHOST_COL = C.pal.ghost
local CRITTER_COL = C.pal.critter

-- draw de tile
local function draw(std, skin_type, x, y, dx, dy, size, light, milis, dread)
    if skin_type == "wall" then
        local ct = apply_light(WALL_TOP, light, milis)
        local cs = apply_light(WALL_SIDE, light, milis)
        painters.wall_bricks(std, dx, dy, size, ct, cs, milis)

    elseif skin_type == "floor" then
        local c = apply_light(FLOOR_COL, light, milis)
        painters.floor_tile(std, dx, dy, size, c, milis, dread)

    elseif skin_type == "dot" then
        local c = apply_light(DOT_COL, light, milis)
        local g = apply_light(DOT_GLOW, light, milis)
        painters.dot_pixel(std, dx, dy, size, c, g, milis)

    elseif skin_type == "dot_fading" then
        painters.dot_fading(std, dx, dy, size, milis)
    end
end

-- draw player
local function draw_player(std, dx, dy, size, p, milis)
    local c = apply_light(GHOST_COL, 1.0, milis)
    painters.ghost_classic(std, dx, dy, size, c, milis, p)
    painters.eyes_happy(std, dx, dy, size, p.curr_dir, p.aiming, milis, p.squash)

    if p.has_shotgun then
        local angle = p.aiming and p.aim_angle or
            (p.curr_dir == C.D_UP and 4.71 or p.curr_dir == C.D_DOWN and 1.57 or p.curr_dir == C.D_LEFT and 3.14 or 0)
        painters.gun_shotgun(std, dx, dy, size, angle, milis)
        if p.aiming then
            painters.aim_laser(std, dx, dy, size, angle, milis)
        end
    end
end

-- draw critter
local function draw_critter(std, dx, dy, size, c, milis)
    local col = apply_light(CRITTER_COL, 1.0, milis)
    local body = { painters.critter_blob(std, dx, dy, size, col, milis, c) }
    painters.critter_eyes(std, dx, dy, size, c.curr_dir, c.scared, c.brave, body, milis)
end

return {
    draw = draw,
    draw_player = draw_player,
    draw_critter = draw_critter,
    apply_light = apply_light
}
