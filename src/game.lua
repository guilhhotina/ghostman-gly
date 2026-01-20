-- game loop do ghostman
-- otimizado: zero allocations no hot path (eu acho)

local mapgen = require('src/data/mapgen')
local actor = require('src/logic/actor')
local critter_ai = require('src/logic/ai/critter')
local perk_manager = require('src/perks/manager')
local view = require('src/view/render')
local effects = require('src/view/effects')
local C = require('src/const')

-- estado global
local G = {
    state = C.S_MENU,
    level = 1,
    grid = {},
    w = 0, h = 0,
    dots = 0,
    dots_x = {},
    dots_y = {},
    dots_count = 0,
    dots_active = {},  -- bitfield: 1=existe, 0=sumiu
    player = nil,
    critter = nil,
    upgrade_options = {},
    upgrade_cursor = 1,
    menu_cursor = 1,
    pause_cursor = 1,
    shake = 0,
    capture_timer = 0,
    ability_cooldown = 0,
    shotgun_cooldown = 0,
    player_idle_time = 0,
    last_player_x = 0,
    last_player_y = 0,
    dot_fade_timer = 0,
    fade_active = false,
    time_elapsed = 0,
    anim_time = 0,
    death_reason = nil,
    last_input_time = 0,
    frame_count = 0,
    saved_state = nil  -- estado anterior ao pause
}

-- pre-alocados (zero GC no game loop)
local _triggers = { false, false, false }
local _ai_context = { brave = false, dread_tiles = nil, player_idle = 0 }

-- helpers pra grid 1D
local function grid_get(x, y)
    if x < 1 or x > G.w or y < 1 or y > G.h then return C.T_WALL end
    return G.grid[(y - 1) * G.w + x]
end

local function grid_set(x, y, v)
    if x >= 1 and x <= G.w and y >= 1 and y <= G.h then
        G.grid[(y - 1) * G.w + x] = v
    end
end

-- checa cooldown de input
local function can_input(std)
    if std.milis > G.last_input_time + C.input.cooldown then
        G.last_input_time = std.milis
        return true
    end
    return false
end

local function check_input(std, key)
    return std.key.press[key] and can_input(std)
end

-- fade um dot aleatorio longe do critter
local function fade_random_dot(std)
    if not G.critter or G.dots_count < 1 then return end

    local c = G.critter
    local best_idx = nil
    local best_dist = 0

    -- acha dot mais longe do critter
    for i = 1, G.dots_count do
        if G.dots_active[i] then
            local dx = G.dots_x[i] - c.x
            local dy = G.dots_y[i] - c.y
            local dist = dx * dx + dy * dy

            if dist > 9 and dist > best_dist then
                best_dist = dist
                best_idx = i
            end
        end
    end

    if best_idx then
        local x, y = G.dots_x[best_idx], G.dots_y[best_idx]
        if grid_get(x, y) == C.T_DOT then
            grid_set(x, y, C.T_FADING)
            effects.dot_fade(std, x, y)
            G.dots_active[best_idx] = false
        end
    end
end

-- remove fading dots
local function remove_fading_dots()
    for y = 1, G.h do
        for x = 1, G.w do
            if grid_get(x, y) == C.T_FADING then
                grid_set(x, y, C.T_EMPTY)
                G.dots = G.dots - 1
            end
        end
    end
end

-- cria nivel novo
local function new_level(std)
    local size = 19 + math.min(G.level, 5) * 2
    local map = mapgen.generate(size, size, std)

    G.grid = map.grid
    G.dots = map.dots
    G.w, G.h = map.w, map.h
    G.dots_x = map.dots_x
    G.dots_y = map.dots_y
    G.dots_count = map.dots_count

    -- inicializa bitfield de dots ativos
    for i = 1, G.dots_count do
        G.dots_active[i] = true
    end

    -- salva stats do player anterior
    local old = G.player or {}
    local stats = {
        speed_mod = old.speed_mod or 0,
        wall_hack = old.wall_hack or false,
        has_fear_aura = old.has_fear_aura or false,
        fear_radius = old.fear_radius or 3,
        zoom_out = old.zoom_out or false,
        has_shotgun = old.has_shotgun or false,
        has_dash = old.has_dash or false,
        has_mark = old.has_mark or false,
        has_chains = old.has_chains or false,
        has_dread = old.has_dread or false,
        actives = old.actives or {}
    }

    -- cria actors
    G.player = actor.create(map.spawn_player.x, map.spawn_player.y, true)
    local p = G.player
    for k, v in pairs(stats) do p[k] = v end

    if p.has_dread then p.dread_tiles = {} end

    G.critter = actor.create(map.spawn_critter.x, map.spawn_critter.y, false)
    G.critter.base_speed = C.balance.base_critter_speed - (G.level * C.balance.speed_per_level)

    -- reseta estado
    G.player_idle_time = 0
    G.last_player_x = p.x
    G.last_player_y = p.y
    G.dot_fade_timer = 0
    G.fade_active = false
    G.time_elapsed = 0
    G.ability_cooldown = 0
    G.state = C.S_PLAY
    G.shake = 0
    G.death_reason = nil
    G.frame_count = 0
    G.last_input_time = std.milis

    std.app.title("ghostman - level " .. G.level)
end

-- captura do critter
local function capture_sequence(std)
    if not G.critter then return end
    G.state = C.S_CAPTURE
    G.capture_timer = 1200
    G.shake = 25
    effects.explode(std, G.critter.real_x, G.critter.real_y)

    local num = G.time_elapsed < 10000 and 3 or 2
    G.upgrade_options = perk_manager.get_options(std, num, G.player)
    G.upgrade_cursor = 1
end

-- morte do player
local function death_sequence(std, reason)
    G.state = C.S_GAMEOVER
    G.death_reason = reason
    G.shake = 30
    if G.player then
        effects.explode(std, G.player.real_x, G.player.real_y)
    end
end

-- init
local function init(self, std)
    if not std.math.dis then
        std.math.dis = function(x1, y1, x2, y2)
            local dx, dy = x2 - x1, y2 - y1
            return math.sqrt(dx * dx + dy * dy)
        end
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
    G.state = C.S_MENU
    G.menu_cursor = 1
    G.pause_cursor = 1
    G.last_input_time = 0
end

-- game loop
local function loop(self, std)
    local dt = std.delta
    G.anim_time = G.anim_time + dt
    G.frame_count = G.frame_count + 1

    local s = G.state
    
    -- POR ALGUM MOTIVO ISSO NAO FUNCIONA AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    if s == C.S_PLAY or s == C.S_UPGRADE or s == C.S_CAPTURE then
        if check_input(std, "p") or check_input(std, "menu") then
            G.saved_state = s
            G.state = C.S_PAUSE
            G.pause_cursor = 1
            return
        end
    end

    -- pause: nao atualiza timers se estiver pausado
    -- NAO FUNCIONA TBM NADA FUNCIONA PQ O MENU NAO FUNCIONA
    if G.state ~= C.S_PAUSE then
        -- shake decay
        if G.shake > 0 then
            local decay = (1 - C.smooth.shake_decay) ^ (dt / 16.666)
            G.shake = G.shake * decay
            if G.shake < 0.1 then G.shake = 0 end
        end

        -- cooldowns
        if G.shotgun_cooldown > 0 then G.shotgun_cooldown = G.shotgun_cooldown - dt end
        if G.ability_cooldown > 0 then G.ability_cooldown = G.ability_cooldown - dt end

        effects.update(std, G)
    end

    -- re-leitura do estado
    s = G.state

    if s == C.S_PAUSE then
        if check_input(std, "up") then G.pause_cursor = G.pause_cursor == 1 and 3 or G.pause_cursor - 1 end
        if check_input(std, "down") then G.pause_cursor = G.pause_cursor == 3 and 1 or G.pause_cursor + 1 end

        -- botão de confirmação (a cobre z, enter e botão A eu acho)
        if check_input(std, "a") then
            if G.pause_cursor == 1 then
                -- resume
                G.state = G.saved_state or C.S_PLAY
                G.last_input_time = std.milis
            elseif G.pause_cursor == 2 then
                -- quit to menu
                G.state = C.S_MENU
                G.menu_cursor = 1
                G.player = nil
                G.critter = nil
                effects.reset()
            elseif G.pause_cursor == 3 then
                -- exit game
                std.app.exit()
            end
        end

        -- atalho para fechar pause
        if check_input(std, "p") or check_input(std, "menu") then
            G.state = G.saved_state or C.S_PLAY
            G.last_input_time = std.milis
        end

    elseif s == C.S_MENU then
        if check_input(std, "up") then G.menu_cursor = G.menu_cursor == 1 and 4 or G.menu_cursor - 1 end
        if check_input(std, "down") then G.menu_cursor = G.menu_cursor == 4 and 1 or G.menu_cursor + 1 end

        -- esc pra fechar direto
        if check_input(std, "menu") then
            std.app.exit()
        end

        if check_input(std, "a") then
            if G.menu_cursor == 1 then
                G.level = 1
                new_level(std)
            elseif G.menu_cursor == 2 then
                G.state = C.S_EVOLUTION
            elseif G.menu_cursor == 3 then
                G.state = C.S_CREDITS
            elseif G.menu_cursor == 4 then
                std.app.exit()
            end
        end

    -- game over basico q tava quebrado mas agr n esta mais
    elseif s == C.S_GAMEOVER then
        if check_input(std, "a") then
            G.level = 1
            effects.reset()
            new_level(std)
        end

        if check_input(std, "menu") then
            G.state = C.S_MENU
            G.menu_cursor = 1
            G.player = nil
            G.critter = nil
            effects.reset()
        end

    elseif s == C.S_PLAY then
        G.time_elapsed = G.time_elapsed + dt
        local p, c = G.player, G.critter
        if not p or not c then return end

        -- idle detection
        if p.x == G.last_player_x and p.y == G.last_player_y then
            G.player_idle_time = G.player_idle_time + dt
        else
            G.player_idle_time = 0
            G.last_player_x = p.x
            G.last_player_y = p.y
        end
        c.brave = G.player_idle_time > C.balance.idle_threshold

        -- dot fading
        if G.time_elapsed > C.balance.dot_fade_start then G.fade_active = true end
        if G.fade_active then
            G.dot_fade_timer = G.dot_fade_timer + dt
            if G.dot_fade_timer > C.balance.dot_fade_interval then
                G.dot_fade_timer = 0
                remove_fading_dots()
                if G.dots > 3 then fade_random_dot(std) end
            end
        end

        -- perks ativos (triggers pre-alocados zero GC)
        if p.actives then
            -- mapeando teclas de ação direito
            _triggers[1] = std.key.press.a or false -- z/enter -> a
            _triggers[2] = std.key.press.b or false -- x -> b
            _triggers[3] = std.key.press.c or false -- c -> c

            for i = 1, #p.actives do
                local perk = p.actives[i]
                if perk.update then
                    if perk.update(p, std, G, _triggers[i]) == "capture" then
                        capture_sequence(std)
                        return
                    end
                end
            end
        end

        -- input de direcao
        if not (p.aiming or p.dashing) then
            if std.key.press.left then p.next_dir = C.D_LEFT end
            if std.key.press.right then p.next_dir = C.D_RIGHT end
            if std.key.press.up then p.next_dir = C.D_UP end
            if std.key.press.down then p.next_dir = C.D_DOWN end
        end

        -- update player
        actor.update(p, G, std)

        -- chains effect
        if c.chained then
            c.chain_timer = (c.chain_timer or 0) - dt
            if c.chain_timer <= 0 then
                c.chained = false
                c.speed_mod = 0
            end
        end

        -- critter AI (throttled pensa a cada N frames)
        if G.frame_count % C.balance.ai_think_interval == 0 then
            _ai_context.brave = c.brave
            _ai_context.dread_tiles = p.has_dread and p.dread_tiles or nil
            _ai_context.player_idle = G.player_idle_time

            critter_ai.think(c, p, G, std, _ai_context)
        end

        -- critter movement
        local dist = std.math.dis(p.x, p.y, c.x, c.y)
        c.scared = dist < 5 and not c.brave

        local fear_radius = p.fear_radius or 3
        local frozen = p.has_fear_aura and dist < fear_radius and not c.brave

        if not frozen then
            local brave_bonus = c.brave and C.balance.courage_speed_bonus or 0
            local orig_mod = c.speed_mod
            c.speed_mod = c.speed_mod - brave_bonus

            local moved = actor.update(c, G, std)
            c.speed_mod = orig_mod

            -- critter come dot
            if moved then
                local tile = grid_get(c.x, c.y)
                if tile == C.T_DOT or tile == C.T_FADING then
                    grid_set(c.x, c.y, C.T_EMPTY)
                    G.dots = G.dots - 1

                    -- marca dot como inativo
                    for i = 1, G.dots_count do
                        if G.dots_x[i] == c.x and G.dots_y[i] == c.y then
                            G.dots_active[i] = false
                            break
                        end
                    end
                end
            end
        end

        -- colisao
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
            G.state = C.S_GAMEOVER
            G.death_reason = "starved"
        end

    elseif s == C.S_CAPTURE then
        G.capture_timer = G.capture_timer - dt
        if G.capture_timer <= 0 then
            if #G.upgrade_options == 0 then
                G.level = G.level + 1
                new_level(std)
            else
                G.state = C.S_UPGRADE
            end
        end

    elseif s == C.S_UPGRADE then
        local num = #G.upgrade_options
        if num == 0 then
            G.level = G.level + 1
            new_level(std)
            return
        end

        if check_input(std, "left") then
            G.upgrade_cursor = G.upgrade_cursor == 1 and num or G.upgrade_cursor - 1
        end
        if check_input(std, "right") then
            G.upgrade_cursor = G.upgrade_cursor == num and 1 or G.upgrade_cursor + 1
        end

        if check_input(std, "a") then
            perk_manager.apply(G.upgrade_options[G.upgrade_cursor], G.player)
            G.level = G.level + 1
            new_level(std)
        end

        if check_input(std, "b") then
            G.state = C.S_MENU
        end

    elseif s == C.S_CREDITS or s == C.S_EVOLUTION then
        if check_input(std, "a") or check_input(std, "menu") then
            G.state = C.S_MENU
        end
    end
end

-- draw
local function draw(self, std)
    std.draw.clear(C.pal.bg)
    view.draw(std, G)
end

-- error handler
local function on_error(self, std, msg)
    print("crash: " .. tostring(msg))
    print(debug.traceback())
    return false
end

return {
    meta = { title = "ghostman", version = "2.6.2", author = "guily" },
    config = { require = "math math.random" },
    callbacks = { init = init, loop = loop, draw = draw, error = on_error }
}
