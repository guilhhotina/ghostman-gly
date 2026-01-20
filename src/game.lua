local mapgen = require('src/data/mapgen')
local actor = require('src/logic/actor')
local critter_ai = require('src/logic/ai/critter')
local perk_manager = require('src/perks/manager')
local view = require('src/view/render')
local effects = require('src/view/effects')
local const = require('src/const')

-- estado global do jogo
local G = {
    state = const.state.menu,
    level = 1,
    grid = {},
    wall_stains = {},
    dots = 0,
    dots_list = {},
    w = 0,
    h = 0,
    player = nil,
    critter = nil,
    upgrade_options = {},
    upgrade_cursor = 1,
    menu_cursor = 1,
    shake = 0,
    capture_timer = 0,
    ability_cooldown = 0,
    shotgun_cooldown = 0,
    player_idle_time = 0,
    last_player_pos = { x = 0, y = 0 },
    dot_fade_timer = 0,
    fade_active = false,
    time_elapsed = 0,
    anim_time = 0,
    death_reason = nil,
    last_input_time = 0
}

local _fade_candidates = {}

-- checa se pode input (cooldown)
local function can_input(std)
    if std.milis > G.last_input_time + const.input.cooldown then
        G.last_input_time = std.milis
        return true
    end
    return false
end

-- helper pra checar input
local function check_input(std, key)
    return std.key.press[key] and can_input(std)
end

-- faz um dot aleatorio proximo do critter fade away
local function fade_random_dot(std)
    if not G.critter then return end
    local c = G.critter
    for k in pairs(_fade_candidates) do _fade_candidates[k] = nil end
    local count = 0
    for k, pos in pairs(G.dots_list) do
        local dist = math.abs(pos.x - c.x) + math.abs(pos.y - c.y)
        if dist > 3 then
            count = count + 1
            _fade_candidates[count] = pos
        end
    end
    if count > 0 then
        local pick = _fade_candidates[std.math.random(1, count)]
        if G.grid[pick.y][pick.x] == const.tile.dot then
            G.grid[pick.y][pick.x] = const.tile.fading
            effects.dot_fade(std, pick.x, pick.y)
            G.dots_list[pick.x .. "," .. pick.y] = nil
        end
    end
end

-- remove dots que estao fading
local function remove_fading_dots()
    for y = 1, G.h do
        for x = 1, G.w do
            if G.grid[y][x] == const.tile.fading then
                G.grid[y][x] = const.tile.empty
                G.dots = G.dots - 1
            end
        end
    end
end

-- cria um nivel novo
local function new_level(std)
    local size = 19 + math.min(G.level, 5) * 2
    local map = mapgen.generate(size, size, std)
    G.grid = map.grid
    G.wall_stains = {}
    G.dots = map.dots
    G.w, G.h = map.w, map.h
    G.dots_list = {}
    for y = 1, G.h do
        for x = 1, G.w do
            if G.grid[y][x] == const.tile.dot then
                G.dots_list[x .. "," .. y] = { x = x, y = y }
            end
        end
    end

    -- salva stats do player anterior
    local old_stats = {
        speed_mod = G.player and G.player.speed_mod or 0,
        wall_hack = G.player and G.player.wall_hack or false,
        has_fear_aura = G.player and G.player.has_fear_aura or false,
        fear_radius = G.player and G.player.fear_radius or 3,
        zoom_out = G.player and G.player.zoom_out or false,
        has_shotgun = G.player and G.player.has_shotgun or false,
        has_dash = G.player and G.player.has_dash or false,
        has_mark = G.player and G.player.has_mark or false,
        has_chains = G.player and G.player.has_chains or false,
        has_dread = G.player and G.player.has_dread or false,
        actives = G.player and G.player.actives or {}
    }

    -- cria actors novos
    G.player = actor.create(map.spawn_player.x, map.spawn_player.y, true)
    local p = G.player
    for k, v in pairs(old_stats) do p[k] = v end

    -- init dread_tiles se tem dread
    if p.has_dread then p.dread_tiles = {} end

    G.critter = actor.create(map.spawn_critter.x, map.spawn_critter.y, false)
    local c = G.critter
    c.base_speed = const.balance.base_critter_speed - (G.level * const.balance.speed_per_level)

    -- reseta estado do nivel
    G.player_idle_time = 0
    G.last_player_pos = { x = p.x, y = p.y }
    G.dot_fade_timer = 0
    G.fade_active = false
    G.time_elapsed = 0
    G.ability_cooldown = 0
    G.state = const.state.play
    G.shake = 0
    G.death_reason = nil

    -- force input cooldown pra evitar skill acidental
    G.last_input_time = std.milis

    std.app.title("ghostman - level " .. G.level)
end

-- sequencia de captura (pega o critter)
local function capture_sequence(std)
    if not G.critter then return end
    G.state = const.state.capture
    G.capture_timer = 1200
    G.shake = 25
    effects.explode(std, G.critter.real_x, G.critter.real_y)
    local num_options = G.time_elapsed < 10000 and 3 or 2
    G.upgrade_options = perk_manager.get_options(std, num_options, G.player)
    G.upgrade_cursor = 1
end

-- sequencia de morte
local function death_sequence(std, reason)
    G.state = const.state.gameover
    G.death_reason = reason
    G.shake = 30
    if G.player then effects.explode(std, G.player.real_x, G.player.real_y) end
end

-- init do jogo
local function init(self, std)
    if not std.math.dis then
        std.math.dis = function(x1, y1, x2, y2) return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2) end
    end
    local sys_random = math.random
    std.math.random = function(a, b)
        if not a then return sys_random() end
        if not b then return sys_random(math.floor(a)) end
        return sys_random(math.floor(a), math.floor(b))
    end
    G.level = 1
    G.player = nil
    G.anim_time = 0
    effects.reset()
    G.state = const.state.menu
    G.menu_cursor = 1
    G.last_input_time = 0
end

-- game loop
local function loop(self, std)
    local dt = std.delta
    G.anim_time = G.anim_time + dt

    -- shake decay
    if G.shake > 0 then
        local decay = (1 - const.smooth.shake_decay) ^ (dt / 16.666)
        G.shake = G.shake * decay
        if G.shake < 0.1 then G.shake = 0 end
    end

    -- cooldowns
    if G.shotgun_cooldown > 0 then G.shotgun_cooldown = G.shotgun_cooldown - dt end
    if G.ability_cooldown > 0 then G.ability_cooldown = G.ability_cooldown - dt end

    effects.update(std, G)

    local s = G.state
    if s == const.state.menu then
        -- menu navigation
        if check_input(std, "up") then G.menu_cursor = G.menu_cursor == 1 and 4 or G.menu_cursor - 1 end
        if check_input(std, "down") then G.menu_cursor = G.menu_cursor == 4 and 1 or G.menu_cursor + 1 end

        -- menu actions
        if check_input(std, "z") or check_input(std, "a") or check_input(std, "enter") then
            if G.menu_cursor == 1 then
                G.level = 1
                new_level(std)
            elseif G.menu_cursor == 2 then
                G.state = const.state.evolution
            elseif G.menu_cursor == 3 then
                G.state = const.state.credits
            elseif G.menu_cursor == 4 then
                std.app.exit()
            end
        end
    elseif s == const.state.play then
        G.time_elapsed = G.time_elapsed + dt
        local p, c = G.player, G.critter
        if not p or not c then return end

        -- idle detection (courage mechanic)
        if p.x == G.last_player_pos.x and p.y == G.last_player_pos.y then
            G.player_idle_time = G.player_idle_time + dt
        else
            G.player_idle_time = 0
            G.last_player_pos.x, G.last_player_pos.y = p.x, p.y
        end
        c.brave = G.player_idle_time > const.balance.idle_threshold

        -- dot fading (anti-camping)
        if G.time_elapsed > const.balance.dot_fade_start then G.fade_active = true end
        if G.fade_active then
            G.dot_fade_timer = G.dot_fade_timer + dt
            if G.dot_fade_timer > const.balance.dot_fade_interval then
                G.dot_fade_timer = 0
                remove_fading_dots()
                if G.dots > 3 then fade_random_dot(std) end
            end
        end

        -- perks ativos
        if p.actives then
            local triggers = { std.key.press.z or std.key.press.a, std.key.press.x or std.key.press.b, std.key.press.c }
            for i, perk in ipairs(p.actives) do
                if perk.update then
                    if perk.update(p, std, G, triggers[i] or false) == "capture" then
                        capture_sequence(std); return
                    end
                end
            end
        end

        -- input de direcao
        if not (p.aiming or p.dashing) then
            if std.key.press.left then p.next_dir = 4 end
            if std.key.press.right then p.next_dir = 5 end
            if std.key.press.up then p.next_dir = 2 end
            if std.key.press.down then p.next_dir = 3 end
        end

        -- update actors
        actor.update(p, G.grid, std)

        -- chains effect
        if c.chained then
            c.chain_timer = (c.chain_timer or 0) - dt
            if (c.chain_timer or 0) <= 0 then
                c.chained = false; c.speed_mod = 0
            end
        end

        -- critter ai
        local dist = std.math.dis(p.x, p.y, c.x, c.y)
        c.scared = dist < 5 and not c.brave
        critter_ai.think(c, p, G.grid, std,
            { brave = c.brave, dread_tiles = p.has_dread and p.dread_tiles or {}, player_idle = G.player_idle_time })

        -- fear aura
        local fear_radius = p.fear_radius or 3
        local frozen = p.has_fear_aura and dist < fear_radius and not c.brave

        -- critter movement
        if not frozen then
            local brave_bonus = c.brave and const.balance.courage_speed_bonus or 0
            local om = c.speed_mod
            c.speed_mod = c.speed_mod - brave_bonus
            local moved = actor.update(c, G.grid, std)
            c.speed_mod = om

            -- critter come dot
            if moved then
                local tile = G.grid[c.y] and G.grid[c.y][c.x]
                if tile == const.tile.dot or tile == const.tile.fading then
                    G.grid[c.y][c.x] = const.tile.empty
                    G.dots = G.dots - 1
                    G.dots_list[c.x .. "," .. c.y] = nil
                end
            end
        end

        -- collision detection
        local pdist = std.math.dis(p.real_x, p.real_y, c.real_x, c.real_y)
        if pdist < 0.75 then
            if c.brave then
                death_sequence(std, "eaten")
            else
                capture_sequence(std)
            end
            return
        end

        -- starvation
        if G.dots <= 0 then
            G.state = const.state.gameover; G.death_reason = "starved"
        end
    elseif s == const.state.capture then
        G.capture_timer = G.capture_timer - dt
        if G.capture_timer <= 0 then
            if #G.upgrade_options == 0 then
                G.level = G.level + 1; new_level(std)
            else
                G.state = const.state.upgrade
            end
        end
    elseif s == const.state.upgrade then
        local num_opts = #G.upgrade_options
        if num_opts == 0 then
            G.level = G.level + 1; new_level(std); return
        end
        -- upgrade navigation
        if check_input(std, "left") then G.upgrade_cursor = G.upgrade_cursor == 1 and num_opts or G.upgrade_cursor - 1 end
        if check_input(std, "right") then G.upgrade_cursor = G.upgrade_cursor == num_opts and 1 or G.upgrade_cursor + 1 end
        -- select upgrade
        if check_input(std, "z") or check_input(std, "a") then
            perk_manager.apply(G.upgrade_options[G.upgrade_cursor], G.player)
            G.level = G.level + 1; new_level(std)
        end
    elseif s == const.state.gameover then
        -- restart
        if check_input(std, "z") or check_input(std, "a") then init(self, std) end
    elseif s == const.state.evolution or s == const.state.credits then
        -- back to menu
        if check_input(std, "z") or check_input(std, "a") or check_input(std, "x") then G.state = const.state.menu end
    end
end

-- render
local function draw(self, std)
    std.draw.clear(const.pal.bg)
    view.draw(std, G)
end

-- error handler
local function on_error(self, std, msg)
    print("crash: " .. tostring(msg))
    print(debug.traceback())
    return false
end

return {
    meta = { title = "ghostman", version = "2.5.0", author = "guily" },
    config = { require = "math math.random" },
    callbacks = { init = init, loop = loop, draw = draw, error = on_error }
}
