-- map generator - creates random mazes using recursive backtracking
-- result is a maze with corridors and some open rooms

local const = require('src/const')

-- generate a random map with w x h dimensions
-- returns table with grid, dots, dimensions and spawn positions
local function generate(w, h, std)
    -- create empty 2d grid filled with walls
    local grid = {}

    -- init: fill everything with walls
    local y = 1
    while y <= h do
        grid[y] = {}
        local x = 1
        while x <= w do
            grid[y][x] = const.tile.wall
            x = x + 1
        end
        y = y + 1
    end

    -- phase 2: recursive backtracking
    -- creates a perfect maze (all points reachable)
    -- carves corridors from a starting point

    local stack = {}
    local start_x = 3
    local start_y = 3

    grid[start_y][start_x] = const.tile.empty
    table.insert(stack, { x = start_x, y = start_y })

    while #stack > 0 do
        local current = stack[#stack]
        local neighbors = {}

        -- directions: up, down, left, right
        -- value 2 means "skip one tile" (corridor width 1)
        local dirs = { { 0, -2 }, { 0, 2 }, { -2, 0 }, { 2, 0 } }

        local i = 1
        while i <= 4 do
            local dx, dy = dirs[i][1], dirs[i][2]
            local nx, ny = current.x + dx, current.y + dy

            -- check if neighbor is valid and still a wall
            if nx > 1 and nx < w and ny > 1 and ny < h and grid[ny][nx] == const.tile.wall then
                table.insert(neighbors, { x = nx, y = ny, dx = dx, dy = dy })
            end
            i = i + 1
        end

        if #neighbors > 0 then
            local next_cell = neighbors[std.math.random(1, #neighbors)]

            -- carve the wall between current and neighbor
            local wx = current.x + next_cell.dx / 2
            local wy = current.y + next_cell.dy / 2
            grid[wy][wx] = const.tile.empty

            grid[next_cell.y][next_cell.x] = const.tile.empty
            table.insert(stack, { x = next_cell.x, y = next_cell.y })
        else
            table.remove(stack)
        end
    end

    -- phase 3: add loops (openings)
    -- perfect maze has only one path - add openings to make it interesting

    local i = 1
    local loops = math.floor((w * h) / 10)

    while i <= loops do
        local rx = std.math.random(2, w - 1)
        local ry = std.math.random(2, h - 1)

        if grid[ry][rx] == const.tile.wall then
            local open_neighbors = 0

            if grid[ry - 1] and grid[ry - 1][rx] == const.tile.empty then open_neighbors = open_neighbors + 1 end
            if grid[ry + 1] and grid[ry + 1][rx] == const.tile.empty then open_neighbors = open_neighbors + 1 end
            if grid[ry][rx - 1] == const.tile.empty then open_neighbors = open_neighbors + 1 end
            if grid[ry][rx + 1] == const.tile.empty then open_neighbors = open_neighbors + 1 end

            -- exactly 2 empty neighbors = create opening
            if open_neighbors == 2 then
                grid[ry][rx] = const.tile.empty
            end
        end
        i = i + 1
    end

    -- phase 4: place dots
    -- dots are the critter's goal

    local dots = 0
    y = 1
    while y <= h do
        local x = 1
        while x <= w do
            if grid[y][x] == const.tile.empty then
                -- 80% chance to have a dot
                if std.math.random(1, 100) > 20 then
                    grid[y][x] = const.tile.dot
                    dots = dots + 1
                end
            end
            x = x + 1
        end
        y = y + 1
    end

    -- phase 5: find spawn positions
    -- player and critter should be on empty tiles, preferably far apart

    local function find_empty()
        local limit = 1000
        while limit > 0 do
            local rx = std.math.random(2, w - 1)
            local ry = std.math.random(2, h - 1)

            if grid[ry][rx] == const.tile.empty then
                return { x = rx, y = ry }
            end
            limit = limit - 1
        end

        return { x = 2, y = 2 }
    end

    local sp = find_empty()
    local sc = find_empty()

    grid[sp.y][sp.x] = const.tile.empty
    grid[sc.y][sc.x] = const.tile.empty

    -- return generated data
    return {
        grid = grid,
        dots = dots,
        w = w,
        h = h,
        spawn_player = sp,
        spawn_critter = sc
    }
end

return { generate = generate }
