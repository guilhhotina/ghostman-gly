-- shotgun perk
-- tank controls edition: segure pra mira, solta pra fogo

local effects = require('src/view/effects')
local const = require('src/const')

-- polyfill pra atan2 (compatibilidade)
local function get_angle(y, x)
    if math.atan2 then return math.atan2(y, x) end
    return math.atan(y, x)
end

-- atira shotgun
local function fire(std, p, G)
    if G.shotgun_cooldown > 0 then return false end

    G.shotgun_cooldown = 1000
    G.shake = 15

    -- usa aim_angle do player
    local base_angle = p.aim_angle

    -- recuo visual
    p.real_x = p.real_x - math.cos(base_angle) * 0.4
    p.real_y = p.real_y - math.sin(base_angle) * 0.4
    p.target_squash = -0.4

    -- solta 10 pelotas
    for i = 1, 10 do
        local spread = (std.math.random() - 0.5) * 0.5 -- cone de tiro
        local final_angle = base_angle + spread

        local speed = 0.5 + std.math.random() * 0.6

        local vx = math.cos(final_angle) * speed
        local vy = math.sin(final_angle) * speed

        effects.pellet(std, p.real_x, p.real_y, vx, vy)
    end

    -- checa se acertou o critter
    local cx, cy = G.critter.real_x, G.critter.real_y
    local dist = std.math.dis(p.real_x, p.real_y, cx, cy)

    if dist < 8 then
        local angle_critter = get_angle(cy - p.real_y, cx - p.real_x)
        local diff = math.abs(angle_critter - base_angle)
        if diff > math.pi then diff = math.abs(diff - 2 * math.pi) end

        -- cone de acerto (~45 graus)
        if diff < 0.7 then
            return "capture"
        end
    end
    return false
end

return {
    id = "shotgun",
    name = "boomstick",
    desc = "segure pra mira (pra move), solta pra fogo.",
    icon = "}-",
    type = "active",
    color = 0xffaa44FF,

    apply = function(p)
        p.has_shotgun = true
        p.aim_angle = 0
    end,

    update = function(p, std, G, triggered)
        if triggered then
            -- inicio da mira
            if not p.aiming then
                p.aiming = true
                local vec = const.vectors[p.curr_dir]
                if vec.x == 0 and vec.y == 0 then
                    vec = const.vectors[p.prev_dir or 5]
                end
                p.aim_angle = get_angle(vec.y, vec.x)
            end

            -- rotacao enquanto segura
            local rotation_speed = 0.008 * std.delta

            if std.key.press.left then
                p.aim_angle = p.aim_angle - rotation_speed
                -- atualiza direcao visual dos olhos
                if math.cos(p.aim_angle) < -0.5 then
                    p.curr_dir = 4
                elseif math.cos(p.aim_angle) > 0.5 then
                    p.curr_dir = 5
                elseif math.sin(p.aim_angle) < -0.5 then
                    p.curr_dir = 2
                else
                    p.curr_dir = 3
                end
            end

            if std.key.press.right then
                p.aim_angle = p.aim_angle + rotation_speed
                if math.cos(p.aim_angle) < -0.5 then
                    p.curr_dir = 4
                elseif math.cos(p.aim_angle) > 0.5 then
                    p.curr_dir = 5
                elseif math.sin(p.aim_angle) < -0.5 then
                    p.curr_dir = 2
                else
                    p.curr_dir = 3
                end
            end

            -- trava movimento
            p.move_timer = std.milis + 100
        else
            -- soltou o botao: fogo!
            if p.aiming then
                p.aiming = false
                return fire(std, p, G)
            end
        end
        return false
    end
}
