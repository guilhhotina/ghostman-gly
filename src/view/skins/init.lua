-- skins do ghostman
-- cache de cores + quantizacao de luz

local painters = require('src/view/skins/painters')
local defs = require('src/view/skins/definitions')
local const = require('src/const')

local P = {}

-- cache de cores pra evitar garbage
local color_cache = {}
local color_cache_size = 0
local MAX_COLOR_CACHE = 512

-- limpa cache de tempos em tempos
local last_cache_clear = 0

-- quantiza luz pra reduzir variacoes (0.1 steps)
local function get_cache_key(color, light)
    local quantized_light = math.floor(light * 10 + 0.5) / 10
    return color * 100 + math.floor(quantized_light * 100)
end

-- aplica iluminacao com cache
local function apply_light(color, light, milis)
    -- limpa cache a cada 10s
    if milis and milis - last_cache_clear > 10000 then
        color_cache = {}
        color_cache_size = 0
        last_cache_clear = milis
    end

    local key = get_cache_key(color, light)

    -- retorna do cache se existir
    if color_cache[key] then
        return color_cache[key]
    end

    -- calcula cor nova com iluminacao
    light = math.min(1.3, math.max(0.0, light))

    local r = math.floor(color / 0x1000000)
    local g = math.floor((color / 0x10000) % 0x100)
    local b = math.floor((color / 0x100) % 0x100)
    local a = color % 0x100

    r = math.min(255, math.floor(r * light))
    g = math.min(255, math.floor(g * light))
    b = math.min(255, math.floor(b * light))

    local result = (r * 0x1000000) + (g * 0x10000) + (b * 0x100) + a

    -- adiciona ao cache se nao lotou
    if color_cache_size < MAX_COLOR_CACHE then
        color_cache[key] = result
        color_cache_size = color_cache_size + 1
    end

    return result
end

-- funcao principal de draw de skins
local function draw(std, skin_type, x, y, dx, dy, size, light, anim, opts)
    opts = opts or {}

    if skin_type == "wall" then
        local c_top = apply_light(defs.wall.color_top, light, anim)
        local c_side = apply_light(defs.wall.color_side, light, anim)
        local c_stain = opts.stain or nil
        painters.wall_bricks(std, dx, dy, size, c_top, c_side, c_stain, anim)
    elseif skin_type == "floor" then
        local c = apply_light(defs.floor.color, light, anim)
        painters.floor_tile(std, dx, dy, size, c, anim, opts.dread)
    elseif skin_type == "dot" then
        local c = apply_light(defs.dot.color, light, anim)
        local glow = apply_light(const.pal.dot_glow, light, anim)
        painters.dot_pixel(std, dx, dy, size, c, glow, anim)
    elseif skin_type == "dot_fading" then
        painters.dot_fading(std, dx, dy, size, anim)
    elseif skin_type == "player" then
        local c = apply_light(defs.player.color, light, anim)
        painters.ghost_classic(std, dx, dy, size, c, anim, opts)
        painters.eyes_happy(std, dx, dy, size, opts.dir, opts.aiming, anim, opts.squash)

        if opts.has_shotgun then
            local angle = opts.aiming and opts.aim_angle or
                (opts.dir == 2 and 4.71 or opts.dir == 3 and 1.57 or opts.dir == 4 and 3.14 or 0)

            painters.gun_shotgun_rotated(std, dx, dy, size, angle, anim)

            if opts.aiming then
                painters.aim_laser_rotated(std, dx, dy, size, angle, anim)
            end
        end
    elseif skin_type == "critter" then
        local c = apply_light(defs.critter.color, light, anim)
        local body_data = { painters.critter_blob(std, dx, dy, size, c, anim, opts) }
        painters.critter_eyes(std, dx, dy, size, opts.dir, opts.scared, opts.brave, body_data, anim)
    end
end

return {
    draw = draw,
    apply_light = apply_light
}
