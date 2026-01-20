-- effects do ghostman
-- particulas, decals e FX visuais

local const = require('src/const')
local math_floor = math.floor
local particles, decals, floor_pools, fade_markers = {}, {}, {}, {}
local particles_count, decals_count, floor_pools_count, fade_markers_count = 0, 0, 0, 0
local actor_stains = {}

-- reseta tudo
local function reset()
    particles = {}; decals = {}; floor_pools = {}; fade_markers = {}; actor_stains = {}
    particles_count, decals_count, floor_pools_count, fade_markers_count = 0, 0, 0, 0
end

-- explosao de particulas (sangue/goo)
local function explode(std, x, y)
    for i = 1, 15 do
        local angle = std.math.random(0, 628) / 100
        local speed = std.math.random(60, 200) / 100
        particles_count = particles_count + 1
        particles[particles_count] = {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed - 0.5,
            life = std.math.random(40, 90),
            max_life = 90,
            size = std.math.random(25, 55) / 100,
            type = "goo",
            alpha = 1,
            gravity = 0.012,
            friction = 0.985
        }
    end
end

-- uma pelota de shotgun
local function pellet(std, x, y, dx, dy)
    particles_count = particles_count + 1
    particles[particles_count] = {
        x = x,
        y = y,
        vx = dx * 0.9,
        vy = dy * 0.9,
        life = 15,
        max_life = 15,
        size = 0.3,
        type = "bullet",
        alpha = 1,
        gravity = 0,
        friction = 0.98
    }
end

-- faísca magica (efeito de habilidade)
local function magic_spark(std, x, y, color)
    for i = 1, 10 do
        local angle = std.math.random(0, 628) / 100
        local speed = std.math.random(30, 80) / 100
        particles_count = particles_count + 1
        particles[particles_count] = {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = std.math.random(15, 30),
            max_life = 30,
            size = std.math.random(15, 35) / 100,
            type = "magic",
            color = color,
            alpha = 1,
            gravity = -0.005,
            friction = 0.92
        }
    end
end

-- marcador de dot fading (pra animacao)
local function dot_fade(std, x, y)
    fade_markers_count = fade_markers_count + 1
    fade_markers[fade_markers_count] = { x = x, y = y, life = 60, max_life = 60, phase = std.math.random(0, 628) / 100 }
end

-- update das particulas
local function update(std, G)
    local dt = std.delta / 16.666
    local i = 1
    while i <= particles_count do
        local p = particles[i]
        p.vy = p.vy + p.gravity * dt
        p.vx = p.vx * p.friction; p.vy = p.vy * p.friction
        p.x = p.x + p.vx * dt; p.y = p.y + p.vy * dt
        p.life = p.life - dt
        p.alpha = p.life / p.max_life
        if p.life <= 0 then
            particles[i] = particles[particles_count]; particles[particles_count] = nil; particles_count =
                particles_count - 1
        else
            i = i + 1
        end
    end
    i = 1
    while i <= fade_markers_count do
        fade_markers[i].life = fade_markers[i].life - dt
        if fade_markers[i].life <= 0 then
            fade_markers[i] = fade_markers[fade_markers_count]; fade_markers[fade_markers_count] = nil; fade_markers_count =
                fade_markers_count - 1
        else
            i = i + 1
        end
    end
end

-- desenha effects
local function draw(std, cs, ox, oy, G)
    -- dots fading (quadradinho roxo que pisca)
    for i = 1, fade_markers_count do
        local f = fade_markers[i]
        local s = cs * 0.6 * (math.sin(f.phase) * 0.3 + 0.7) * (f.life / f.max_life)
        std.draw.color(const.pal.dot_fading)
        std.draw.rect(0, ox + (f.x - 1) * cs + cs * 0.2, oy + (f.y - 1) * cs + cs * 0.2, s, s)
    end

    -- particulas
    for i = 1, particles_count do
        local p = particles[i]
        if p.alpha > 0.05 then
            local color = const.pal.blood
            if p.type == "magic" then color = p.color end
            if p.type == "bullet" then color = const.pal.shotgun_blast end
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
    dot_fade = dot_fade,
    magic_spark = magic_spark,
    update = update,
    draw = draw,
    get_actor_stain = function() return 0 end
}
