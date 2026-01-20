-- gerenciador de perks
-- otimizado: evita criar tables novas

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

-- pool de opcoes (reusado)
local _pool = {}
local _options = {}

-- retorna opcoes de perks
local function get_options(std, count, player)
    -- limpa pools
    for i = 1, #_pool do _pool[i] = nil end
    for i = 1, #_options do _options[i] = nil end

    local pool_count = 0

    for _, p in ipairs(collection) do
        local skip = false

        if player then
            if p.type == "active" and player.actives then
                for _, a in ipairs(player.actives) do
                    if a.id == p.id then skip = true; break end
                end
            end

            if p.id == "speed" and player.speed_mod <= -60 then skip = true end
            if p.id == "wall" and player.wall_hack then skip = true end
            if p.id == "fear" and player.has_fear_aura then skip = true end
            if p.id == "vision" and player.zoom_out then skip = true end
            if p.id == "mark" and player.has_mark then skip = true end
            if p.id == "dread" and player.has_dread then skip = true end

            if p.id == "speed" and player.speed_mod < 0 and player.speed_mod > -60 then
                skip = false
            end
        end

        if not skip then
            pool_count = pool_count + 1
            _pool[pool_count] = p
        end
    end

    for i = 1, count do
        if pool_count == 0 then break end

        local idx = std.math.random(1, pool_count)
        local perk = _pool[idx]

        if perk then
            _options[#_options + 1] = perk
            _pool[idx] = _pool[pool_count]
            _pool[pool_count] = nil
            pool_count = pool_count - 1
        end
    end

    return _options
end

-- aplica perk
local function apply(perk, player)
    if perk.apply then
        perk.apply(player)
    end

    if perk.type == "active" then
        player.actives = player.actives or {}

        if #player.actives < 3 then
            player.actives[#player.actives + 1] = perk
        else
            -- FIFO
            player.actives[1] = player.actives[2]
            player.actives[2] = player.actives[3]
            player.actives[3] = perk
        end
    end
end

return {
    get_options = get_options,
    apply = apply,
    collection = collection
}
