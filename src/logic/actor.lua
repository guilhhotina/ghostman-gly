-- sistema de atores
-- otimizado: local refs, cache de speed, menos allocations

local C = require('src/const')

-- local refs (evita table lookup)
local math_min = math.min
local math_max = math.max
local math_abs = math.abs
local math_sin = math.sin
local math_sqrt = math.sqrt

-- smooth lerp com falloff exponencial
local function smooth_lerp(current, target, speed, dt)
    local norm = dt / 16.666
    local factor = 1 - (1 - speed) ^ norm
    if factor > 1 then factor = 1 end
    if factor < 0 then factor = 0 end
    return current + (target - current) * factor
end

-- cria ator
local function create(x, y, is_player)
    return {
        x = x,
        y = y,
        real_x = x,
        real_y = y,
        vel_x = 0,
        vel_y = 0,
        next_dir = 1,
        curr_dir = 1,
        prev_dir = 1,
        move_timer = 0,
        base_speed = is_player and 140 or 170,
        speed_mod = 0,
        frame = 0,
        anim_time = 0,
        wall_hack = false,
        is_moving = false,
        just_moved = false,
        dashing = false,
        aiming = false,
        aim_angle = 0,
        bob_offset = 0,
        bob_phase = 0,
        squash = 0,
        target_squash = 0,
        _cached_speed = 0,
        _last_update = 0
    }
end

-- helper pra grid 1D
local function grid_get(G, x, y)
    if x < 1 or x > G.w or y < 1 or y > G.h then return C.T_WALL end
    return G.grid[(y - 1) * G.w + x]
end

-- valida posicao
local function is_valid(G, x, y, wall_hack)
    local tile = grid_get(G, x, y)
    if wall_hack then return tile ~= nil end
    return tile ~= C.T_WALL
end

-- update de ator
local function update(a, G, std)
    local dt = std.delta
    local milis = std.milis
    local smooth = C.smooth

    -- cache speed
    if a._last_update ~= milis then
        a._cached_speed = math_max(20, a.base_speed + a.speed_mod)
        a._last_update = milis
    end

    -- lerp adaptativo
    local lerp_speed = smooth.actor_lerp
    local dx = a.x - a.real_x
    local dy = a.y - a.real_y
    local dist = dx * dx + dy * dy

    if dist > 9 or a.dashing then
        lerp_speed = smooth.actor_lerp_fast
    end

    local old_rx, old_ry = a.real_x, a.real_y
    a.real_x = smooth_lerp(a.real_x, a.x, lerp_speed, dt)
    a.real_y = smooth_lerp(a.real_y, a.y, lerp_speed, dt)

    -- velocidade
    local dt_s = dt / 1000 + 0.001
    a.vel_x = (a.real_x - old_rx) / dt_s
    a.vel_y = (a.real_y - old_ry) / dt_s

    -- bobbing
    a.bob_phase = a.bob_phase + dt * smooth.bob_speed
    if a.bob_phase > 6.28318 then
        a.bob_phase = a.bob_phase - 6.28318
    end
    a.bob_offset = math_sin(a.bob_phase) * smooth.bob_amplitude

    -- squash decay
    a.squash = smooth_lerp(a.squash, a.target_squash, 0.15, dt)
    if math_abs(a.squash) < 0.01 then a.squash = 0 end
    a.target_squash = smooth_lerp(a.target_squash, 0, 0.1, dt)

    a.anim_time = a.anim_time + dt
    a.just_moved = false

    -- movimento
    if milis > a.move_timer then
        local moved = false
        local vn = C.vectors[a.next_dir]
        local vc = C.vectors[a.curr_dir]

        -- muda direcao
        if a.next_dir ~= 1 and is_valid(G, a.x + vn.x, a.y + vn.y, a.wall_hack) then
            a.prev_dir = a.curr_dir
            a.curr_dir = a.next_dir
            vc = vn
        end

        -- tenta mover
        local tx, ty = a.x + vc.x, a.y + vc.y
        if is_valid(G, tx, ty, a.wall_hack) then
            a.x = tx
            a.y = ty
            moved = true
            a.just_moved = true
            a.frame = (a.frame + 1) % 10000
            a.target_squash = 0.3
        end

        a.is_moving = moved
        a.move_timer = milis + a._cached_speed
        return moved
    end
    return false
end

return {
    create = create,
    update = update,
    smooth_lerp = smooth_lerp
}
