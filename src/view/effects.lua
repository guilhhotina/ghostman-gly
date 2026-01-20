-- sistema de particulas
-- otimizado: object pooling, zero allocations em runtime (eu acho)

local C = require('src/const')

local math_floor = math.floor
local math_sin = math.sin
local math_cos = math.cos

-- pools de objetos (pre-alocados)
local MAX_PARTICLES = 128
local MAX_MARKERS = 32

local particles = {}
local particles_count = 0

local fade_markers = {}
local markers_count = 0

-- init pools
for i = 1, MAX_PARTICLES do
    particles[i] = {
        x = 0, y = 0, vx = 0, vy = 0,
        life = 0, max_life = 0, size = 0,
        type = 0, color = 0, alpha = 0,
        gravity = 0, friction = 0, active = false
    }
end

for i = 1, MAX_MARKERS do
    fade_markers[i] = { x = 0, y = 0, life = 0, max_life = 0, phase = 0, active = false }
end

-- reseta tudo
local function reset()
    for i = 1, MAX_PARTICLES do
        particles[i].active = false
    end
    particles_count = 0

    for i = 1, MAX_MARKERS do
        fade_markers[i].active = false
    end
    markers_count = 0
end

-- acha slot livre
local function get_free_particle()
    for i = 1, MAX_PARTICLES do
        if not particles[i].active then
            return particles[i]
        end
    end
    -- se cheio, recicla o mais velho
    return particles[1]
end

-- explosao
local function explode(std, x, y)
    for i = 1, 15 do
        local p = get_free_particle()
        local angle = std.math.random(0, 628) / 100
        local speed = std.math.random(60, 200) / 100

        p.x = x
        p.y = y
        p.vx = math_cos(angle) * speed
        p.vy = math_sin(angle) * speed - 0.5
        p.life = std.math.random(40, 90)
        p.max_life = 90
        p.size = std.math.random(25, 55) / 100
        p.type = 1  -- goo
        p.alpha = 1
        p.gravity = 0.012
        p.friction = 0.985
        p.active = true

        particles_count = particles_count + 1
    end
end

-- pellet de shotgun
local function pellet(std, x, y, dx, dy)
    local p = get_free_particle()
    p.x = x
    p.y = y
    p.vx = dx * 0.9
    p.vy = dy * 0.9
    p.life = 15
    p.max_life = 15
    p.size = 0.3
    p.type = 2  -- bullet
    p.alpha = 1
    p.gravity = 0
    p.friction = 0.98
    p.active = true
    particles_count = particles_count + 1
end

-- faisca magica
local function magic_spark(std, x, y, color)
    for i = 1, 10 do
        local p = get_free_particle()
        local angle = std.math.random(0, 628) / 100
        local speed = std.math.random(30, 80) / 100

        p.x = x
        p.y = y
        p.vx = math_cos(angle) * speed
        p.vy = math_sin(angle) * speed
        p.life = std.math.random(15, 30)
        p.max_life = 30
        p.size = std.math.random(15, 35) / 100
        p.type = 3  -- magic
        p.color = color
        p.alpha = 1
        p.gravity = -0.005
        p.friction = 0.92
        p.active = true
        particles_count = particles_count + 1
    end
end

-- marcador de dot fading
local function dot_fade(std, x, y)
    for i = 1, MAX_MARKERS do
        if not fade_markers[i].active then
            local m = fade_markers[i]
            m.x = x
            m.y = y
            m.life = 60
            m.max_life = 60
            m.phase = std.math.random(0, 628) / 100
            m.active = true
            markers_count = markers_count + 1
            return
        end
    end
end

-- update
local function update(std, G)
    local dt = std.delta / 16.666

    -- particulas
    for i = 1, MAX_PARTICLES do
        local p = particles[i]
        if p.active then
            p.vy = p.vy + p.gravity * dt
            p.vx = p.vx * p.friction
            p.vy = p.vy * p.friction
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.life = p.life - dt
            p.alpha = p.life / p.max_life

            if p.life <= 0 then
                p.active = false
                particles_count = particles_count - 1
            end
        end
    end

    -- markers
    for i = 1, MAX_MARKERS do
        local m = fade_markers[i]
        if m.active then
            m.life = m.life - dt
            if m.life <= 0 then
                m.active = false
                markers_count = markers_count - 1
            end
        end
    end
end

-- draw
local function draw(std, cs, ox, oy, G)
    -- fade markers
    for i = 1, MAX_MARKERS do
        local m = fade_markers[i]
        if m.active then
            local s = cs * 0.6 * (math_sin(m.phase) * 0.3 + 0.7) * (m.life / m.max_life)
            std.draw.color(C.pal.dot_fading)
            std.draw.rect(0, ox + (m.x - 1) * cs + cs * 0.2, oy + (m.y - 1) * cs + cs * 0.2, s, s)
        end
    end

    -- particulas
    for i = 1, MAX_PARTICLES do
        local p = particles[i]
        if p.active and p.alpha > 0.05 then
            local color
            if p.type == 1 then
                color = C.pal.blood
            elseif p.type == 2 then
                color = 0xffffccFF
            else
                color = p.color
            end

            local s = p.size * cs
            std.draw.color(color)
            std.draw.rect(0, ox + (p.x - 1) * cs + cs / 2 - s / 2, oy + (p.y - 1) * cs + cs / 2 - s / 2, s, s)
        end
    end
end

return {
    reset = reset,
    explode = explode,
    pellet = pellet,
    magic_spark = magic_spark,
    dot_fade = dot_fade,
    update = update,
    draw = draw
}
