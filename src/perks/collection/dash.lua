-- dash perk: phantom dash
-- dash 3 tiles instantaneamente, cooldown de 2s

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

            -- garante inteiros pro grid
            local cx = math.floor(p.x + 0.5)
            local cy = math.floor(p.y + 0.5)

            local new_x = cx + vec.x * dash_dist
            local new_y = cy + vec.y * dash_dist

            -- clamp pra dentro do mapa (margem de 2 tiles)
            new_x = math.max(2, math.min(G.w - 1, new_x))
            new_y = math.max(2, math.min(G.h - 1, new_y))

            -- wall check CORRIGIDO (grid 1D)
            local function is_wall(tx, ty)
                if tx < 1 or tx > G.w or ty < 1 or ty > G.h then return true end
                -- acesso 1D correto: (y-1)*w + x
                return G.grid[(ty - 1) * G.w + tx] == const.T_WALL
            end

            if not p.wall_hack and is_wall(new_x, new_y) then
                -- raycast reverso pra nao entrar na parede
                for i = dash_dist - 1, 1, -1 do
                    local check_x = cx + vec.x * i
                    local check_y = cy + vec.y * i
                    if not is_wall(check_x, check_y) then
                        new_x = check_x
                        new_y = check_y
                        break
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
