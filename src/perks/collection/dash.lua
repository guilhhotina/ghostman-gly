-- dash perk: phantom dash
-- dahs 3 tiles instantaneamente, cooldown de 2s

local const = require('src/const')

return {
    id = "dash",
    name = "PHANTOM DASH",
    desc = "dash 3 tiles instantly. cooldown 2s.",
    icon = "~>",
    type = "active",
    color = 0xff8844FF,

    apply = function(p)
        p.has_dash = true
    end,

    update = function(p, std, G, triggered)
        if triggered and G.ability_cooldown <= 0 then
            G.ability_cooldown = 2000
            G.shake = 8

            local vec = const.vectors[p.curr_dir]
            local dash_dist = 3

            local new_x = p.x + vec.x * dash_dist
            local new_y = p.y + vec.y * dash_dist

            -- clamp pra dentro do mapa (margem de 2 tiles)
            new_x = math.max(2, math.min(G.w - 1, new_x))
            new_y = math.max(2, math.min(G.h - 1, new_y))

            -- wall check
            if not p.wall_hack and G.grid[new_y] and G.grid[new_y][new_x] == const.tile.wall then
                for i = dash_dist - 1, 1, -1 do
                    local check_x = p.x + vec.x * i
                    local check_y = p.y + vec.y * i
                    if check_x > 1 and check_x < G.w and check_y > 1 and check_y < G.h then
                        if G.grid[check_y][check_x] ~= const.tile.wall then
                            new_x = check_x
                            new_y = check_y
                            break
                        end
                    end
                end
            end

            -- aplica movimento
            p.x = new_x
            p.y = new_y

            -- animacao de dash
            p.dash_timer = 200
            p.dashing = true

            -- checa captura
            local dist = std.math.dis(p.x, p.y, G.critter.x, G.critter.y)
            if dist < 1.5 then
                return "capture"
            end
        end

        -- update da animacao
        if p.dash_timer and p.dash_timer > 0 then
            p.dash_timer = p.dash_timer - std.delta
            if p.dash_timer <= 0 then
                p.dashing = false
                p.dash_timer = 0
            end
        else
            p.dashing = false
        end

        return false
    end
}
