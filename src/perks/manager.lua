-- perks manager
-- gerencia a collection de perks e seleção de upgrades

local collection = {
    require('src/perks/collection/speed'),
    require('src/perks/collection/ethereal'),
    require('src/perks/collection/fear'),
    require('src/perks/collection/vision'),
    require('src/perks/collection/boomstick'),
    require('src/perks/collection/dash'),
    require('src/perks/collection/mark'),
    require('src/perks/collection/chains'),
    require('src/perks/collection/dread')
}

-- retorna opções de perks pra mostrar na tela de upgrade
local function get_options(std, count, player)
    local options = {}
    local pool = {}

    for i, p in ipairs(collection) do
        local dominated = false
        if player then
            -- ativos: evita ter o mesmo perk duas vezes
            if p.type == "active" then
                if player.actives then
                    for _, active in ipairs(player.actives) do
                        if active.id == p.id then dominated = true end
                    end
                end
            end

            -- passivas: checa se ja tem
            if p.id == "speed" and player.speed_mod <= -60 then dominated = true end
            if p.id == "wall" and player.wall_hack then dominated = true end
            if p.id == "fear" and player.has_fear_aura then dominated = true end
            if p.id == "vision" and player.zoom_out then dominated = true end
            if p.id == "mark" and player.has_mark then dominated = true end
            if p.id == "dread" and player.has_dread then dominated = true end

            -- speed stack: permite ate -60
            if p.id == "speed" and player.speed_mod < 0 and player.speed_mod > -60 then
                dominated = false
            end
        end
        if not dominated then
            table.insert(pool, p)
        end
    end

    -- escolhe perks aleatorios
    for i = 1, count do
        if #pool == 0 then break end
        local idx = std.math.random(1, #pool)
        idx = math.max(1, math.min(#pool, idx))
        local perk = pool[idx]
        if perk then
            table.insert(options, perk)
            table.remove(pool, idx)
        end
    end

    return options
end

-- aplica um perk no player
local function apply(perk, player)
    if perk.apply then
        perk.apply(player)
    end

    -- perks ativos vao pro array de actives
    if perk.type == "active" then
        player.actives = player.actives or {}

        -- se tem espaco, adiciona
        -- se nao, remove o mais velho (fifo)
        if #player.actives < 3 then
            table.insert(player.actives, perk)
        else
            table.remove(player.actives, 1)
            table.insert(player.actives, perk)
        end
    end
end

return {
    get_options = get_options,
    apply = apply,
    collection = collection
}
