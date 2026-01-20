local const = require('src/const')

-- otimização local das funcs matemáticas
local math_min = math.min
local math_max = math.max
local math_abs = math.abs
local math_sin = math.sin
local math_sqrt = math.sqrt

local function ease_out_quad(t)
    return 1 - (1 - t) * (1 - t)
end

local function ease_out_cubic(t)
    return 1 - (1 - t) * (1 - t) * (1 - t)
end

local function ease_in_out_sine(t)
    return -(math.cos(3.14159 * t) - 1) / 2
end

-- smooth lerp com falloff exponencial
local function smooth_lerp(current, target, speed, dt)
    local normalized_dt = dt / 16.666
    local factor = 1 - (1 - speed) ^ normalized_dt
    factor = math_min(1, math_max(0, factor))
    return current + (target - current) * factor
end

local function smooth_lerp_eased(current, target, speed, dt, ease_func)
    local normalized_dt = dt / 16.666
    local factor = 1 - (1 - speed) ^ normalized_dt
    factor = math_min(1, math_max(0, factor))
    if ease_func then
        factor = ease_func(factor)
    end
    return current + (target - current) * factor
end

-- cria um ator novo
-- x, y: posição no grid
-- is_player: true se for o fantasma, false se for o critter
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
        _last_update = 0,
        _cached_speed = 0
    }
end

-- verifica se uma posição é válida (dentro do grid e não é parede)
local function is_valid(grid, x, y, wall_hack)
    local row = grid[y]
    if not row then return false end
    local cell = row[x]
    if not cell then return false end
    if wall_hack then return true end
    return cell ~= const.tile.wall
end

-- atualiza um ator
-- actor: o ator a atualizar
-- grid: o mapa do jogo
-- std: sistema
local function update(actor, grid, std)
    local dt = std.delta
    local milis = std.milis
    local smooth = const.smooth

    -- cache da speed pra evitar recalcular
    if actor._last_update ~= milis then
        actor._cached_speed = math_max(20, actor.base_speed + actor.speed_mod)
        actor._last_update = milis
    end

    -- movimento mais rapido se estiver longe da posicao target
    local lerp_speed = actor.dashing and smooth.actor_lerp_fast or smooth.actor_lerp
    local dist_x = math_abs(actor.x - actor.real_x)
    local dist_y = math_abs(actor.y - actor.real_y)
    local total_dist = math_sqrt(dist_x * dist_x + dist_y * dist_y)

    if total_dist > 3 then
        lerp_speed = smooth.actor_lerp_fast
    end

    local old_real_x = actor.real_x
    local old_real_y = actor.real_y

    -- interpola posicao real para a posicao no grid
    actor.real_x = smooth_lerp(actor.real_x, actor.x, lerp_speed, dt)
    actor.real_y = smooth_lerp(actor.real_y, actor.y, lerp_speed, dt)

    -- calcula velocidade em tiles por segundo
    actor.vel_x = (actor.real_x - old_real_x) / (dt / 1000 + 0.001)
    actor.vel_y = (actor.real_y - old_real_y) / (dt / 1000 + 0.001)

    -- animacao de bobbing (efeito de flutuar)
    actor.bob_phase = actor.bob_phase + dt * smooth.bob_speed
    if actor.bob_phase > 6.28318 then
        actor.bob_phase = actor.bob_phase - 6.28318
    end
    actor.bob_offset = math_sin(actor.bob_phase) * smooth.bob_amplitude

    -- squash and stretch
    actor.squash = smooth_lerp(actor.squash, actor.target_squash, 0.15, dt)
    if math_abs(actor.squash) < 0.01 then
        actor.squash = 0
    end
    actor.target_squash = smooth_lerp(actor.target_squash, 0, 0.1, dt)

    actor.anim_time = actor.anim_time + dt
    local speed = actor._cached_speed

    actor.just_moved = false
    -- checa se ja pode mover (cooldown)
    if milis > actor.move_timer then
        local moved = false
        local vn = const.vectors[actor.next_dir]
        local vc = const.vectors[actor.curr_dir]

        -- muda direcao se a nova direcao for valida
        if actor.next_dir ~= 1 and is_valid(grid, actor.x + vn.x, actor.y + vn.y, actor.wall_hack) then
            actor.prev_dir = actor.curr_dir
            actor.curr_dir = actor.next_dir
            vc = vn
        end

        -- tenta mover
        local tx, ty = actor.x + vc.x, actor.y + vc.y
        if is_valid(grid, tx, ty, actor.wall_hack) then
            actor.x = tx
            actor.y = ty
            moved = true
            actor.just_moved = true
            actor.frame = (actor.frame + 1) % 10000
            actor.target_squash = 0.3
        end

        actor.is_moving = moved
        actor.move_timer = milis + speed
        return moved
    end
    return false
end

return {
    create = create,
    update = update,
    smooth_lerp = smooth_lerp,
    smooth_lerp_eased = smooth_lerp_eased,
    ease_out_quad = ease_out_quad,
    ease_out_cubic = ease_out_cubic,
    ease_in_out_sine = ease_in_out_sine
}
