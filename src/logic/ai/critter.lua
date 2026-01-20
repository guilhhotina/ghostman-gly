-- critter ai (the prey)
-- controls the critter's ai
-- decides where to move based on: ghost distance, dots, dread tiles, courage, etc
-- uses a scoring system to pick the best direction

local const = require('src/const')

-- bfs to find shortest path to target
-- returns the first direction of the shortest path
local function bfs_find_path(start_x, start_y, target_x, target_y, grid)
    local vectors = const.vectors
    local dirs = { 2, 3, 4, 5 }
    local h = #grid
    local w = #grid[1]

    -- queue of positions to explore: {{x, y, path_dir}, ...}
    local queue = {}
    local visited = {}

    -- start with 4 directions from current pos
    for _, d in ipairs(dirs) do
        local vec = vectors[d]
        local nx, ny = start_x + vec.x, start_y + vec.y

        if nx >= 1 and nx <= w and ny >= 1 and ny <= h then
            if grid[ny][nx] ~= const.tile.wall then
                table.insert(queue, { x = nx, y = ny, first_dir = d, steps = 1 })
                visited[nx .. "," .. ny] = true
            end
        end
    end

    local head = 1
    while head <= #queue do
        local current = queue[head]
        head = head + 1

        -- found target!
        if current.x == target_x and current.y == target_y then
            return current.first_dir
        end

        -- cap depth to avoid infinite loops on big maps
        if current.steps > 100 then
            goto continue
        end

        -- explore neighbors
        for _, d in ipairs(dirs) do
            local vec = vectors[d]
            local nx, ny = current.x + vec.x, current.y + vec.y
            local key = nx .. "," .. ny

            if nx >= 1 and nx <= w and ny >= 1 and ny <= h then
                if grid[ny][nx] ~= const.tile.wall and not visited[key] then
                    visited[key] = true
                    table.insert(queue, {
                        x = nx,
                        y = ny,
                        first_dir = current.first_dir,
                        steps = current.steps + 1
                    })
                end
            end
        end

        ::continue::
    end

    -- no path found, keep current direction
    return nil
end

-- main think function
-- called every frame to decide next move
local function think(me, ghost, grid, std, context)
    context = context or {}
    local brave = context.brave or false
    local dread_tiles = context.dread_tiles or {}

    -- brave mode: use bfs for direct pathfinding
    if brave then
        local path_dir = bfs_find_path(me.x, me.y, ghost.x, ghost.y, grid)
        if path_dir then
            me.next_dir = path_dir
            return
        end
        -- if bfs fails, fall back to scoring
    end

    -- normal mode: scoring system
    local best_score = -999999
    local best_dir = me.curr_dir
    local possible = { 2, 3, 4, 5 }

    -- helpers
    local function dot_danger(dx, dy)
        local ghost_dist = math.abs(dx - ghost.x) + math.abs(dy - ghost.y)
        if ghost_dist < 3 then return 100 end
        if ghost_dist < 5 then return 50 end
        return 0
    end

    local function has_dread(x, y)
        local key = x .. "," .. y
        return dread_tiles[key] ~= nil
    end

    for _, d in ipairs(possible) do
        local vec = const.vectors[d]
        local tx, ty = me.x + vec.x, me.y + vec.y
        local row = grid[ty]

        if row and row[tx] ~= const.tile.wall then
            local score = 0
            local dist = math.abs(tx - ghost.x) + math.abs(ty - ghost.y)

            -- scared mode
            if dist < 8 then
                score = score - (10 - dist) * 20
            else
                score = score + 10
            end

            -- dread
            if has_dread(tx, ty) then
                score = score - 200
            end

            -- dots
            local tile = row[tx]
            if tile == const.tile.dot then
                local danger = dot_danger(tx, ty)
                score = score + (100 - danger)
            elseif tile == const.tile.fading then
                score = score + 150
            end

            -- keep going same direction
            if d == me.curr_dir then
                score = score + 12
            end

            -- opposite direction
            local opposite = { [2] = 3, [3] = 2, [4] = 5, [5] = 4 }
            if d == opposite[me.curr_dir] then
                score = score - 25
            end

            -- look ahead
            local tx2, ty2 = tx + vec.x, ty + vec.y
            local row2 = grid[ty2]
            if row2 and row2[tx2] ~= const.tile.wall then
                if row2[tx2] == const.tile.dot then
                    score = score + 20
                end
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
