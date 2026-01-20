-- AI do critter (presa)
-- otimizado: reusa tables, BFS com pool, scoring simplificado

local C = require('src/const')

-- pools pre-alocados
local _queue = {}
local _visited = {}
local _neighbors = {}

-- helper pro grid 1D
local function grid_get(G, x, y)
    if x < 1 or x > G.w or y < 1 or y > G.h then return C.T_WALL end
    return G.grid[(y - 1) * G.w + x]
end

-- BFS pra pathfinding direto (brave mode)
local function bfs_path(sx, sy, tx, ty, G)
    -- limpa pools
    for k in pairs(_visited) do _visited[k] = nil end

    local w, h = G.w, G.h
    local dirs = { C.D_UP, C.D_DOWN, C.D_LEFT, C.D_RIGHT }
    local head, tail = 1, 0

    -- seed inicial
    for i = 1, 4 do
        local v = C.vectors[dirs[i]]
        local nx, ny = sx + v.x, sy + v.y
        local key = ny * 1000 + nx

        if nx >= 1 and nx <= w and ny >= 1 and ny <= h then
            if grid_get(G, nx, ny) ~= C.T_WALL and not _visited[key] then
                _visited[key] = true
                tail = tail + 1
                _queue[tail] = { x = nx, y = ny, d = dirs[i], s = 1 }
            end
        end
    end

    while head <= tail do
        local cur = _queue[head]
        head = head + 1

        if cur.x == tx and cur.y == ty then
            return cur.d
        end

        if cur.s > 80 then goto continue end

        for i = 1, 4 do
            local v = C.vectors[dirs[i]]
            local nx, ny = cur.x + v.x, cur.y + v.y
            local key = ny * 1000 + nx

            if nx >= 1 and nx <= w and ny >= 1 and ny <= h then
                if grid_get(G, nx, ny) ~= C.T_WALL and not _visited[key] then
                    _visited[key] = true
                    tail = tail + 1
                    _queue[tail] = { x = nx, y = ny, d = cur.d, s = cur.s + 1 }
                end
            end
        end

        ::continue::
    end
    return nil
end

-- funcao principal de IA
local function think(me, ghost, G, std, ctx)
    ctx = ctx or {}
    local brave = ctx.brave or false
    local dread = ctx.dread_tiles

    -- brave: pathfinding direto pro player
    if brave then
        local d = bfs_path(me.x, me.y, ghost.x, ghost.y, G)
        if d then
            me.next_dir = d
            return
        end
    end

    -- modo normal: scoring
    local best_score = -999999
    local best_dir = me.curr_dir
    local dirs = { C.D_UP, C.D_DOWN, C.D_LEFT, C.D_RIGHT }

    for i = 1, 4 do
        local d = dirs[i]
        local v = C.vectors[d]
        local tx, ty = me.x + v.x, me.y + v.y
        local tile = grid_get(G, tx, ty)

        if tile ~= C.T_WALL then
            local score = 0
            local gdx, gdy = tx - ghost.x, ty - ghost.y
            local gdist = math.abs(gdx) + math.abs(gdy)

            -- foge do ghost
            if gdist < 8 then
                score = score - (10 - gdist) * 20
            else
                score = score + 10
            end

            -- evita dread tiles
            if dread then
                local key = tx .. "," .. ty
                if dread[key] then
                    score = score - 200
                end
            end

            -- busca dots
            if tile == C.T_DOT then
                local danger = 0
                if gdist < 3 then danger = 100
                elseif gdist < 5 then danger = 50 end
                score = score + (100 - danger)
            elseif tile == C.T_FADING then
                score = score + 150
            end

            -- prefere mesma direcao
            if d == me.curr_dir then
                score = score + 12
            end

            -- evita voltar
            local opp = { [C.D_UP] = C.D_DOWN, [C.D_DOWN] = C.D_UP, [C.D_LEFT] = C.D_RIGHT, [C.D_RIGHT] = C.D_LEFT }
            if d == opp[me.curr_dir] then
                score = score - 25
            end

            -- look ahead
            local t2 = grid_get(G, tx + v.x, ty + v.y)
            if t2 == C.T_DOT then
                score = score + 20
            end

            -- randomness
            score = score + std.math.random(0, 15)

            if score > best_score then
                best_score = score
                best_dir = d
            end
        end
    end

    me.next_dir = best_dir
end

return { think = think }
