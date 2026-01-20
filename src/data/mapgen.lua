-- gerador de mapas
-- recursive backtracking
-- retorna grid 1D otimizado pra cache de CPU

local C = require('src/const')

-- converte x,y pra indice 1D
local function xy_to_idx(x, y, w)
    return (y - 1) * w + x
end

-- gera mapa aleatorio
local function generate(w, h, std)
    -- grid 1D (melhor cache locality)
    local grid = {}
    local size = w * h

    -- preenche com paredes
    for i = 1, size do
        grid[i] = C.T_WALL
    end

    -- helper pra acessar grid
    local function get(x, y)
        if x < 1 or x > w or y < 1 or y > h then return C.T_WALL end
        return grid[(y - 1) * w + x]
    end

    local function set(x, y, v)
        if x >= 1 and x <= w and y >= 1 and y <= h then
            grid[(y - 1) * w + x] = v
        end
    end

    -- recursive backtracking
    local stack = {}
    local stack_top = 0
    local start_x, start_y = 3, 3

    set(start_x, start_y, C.T_EMPTY)
    stack_top = stack_top + 1
    stack[stack_top] = start_x + start_y * 1000  -- pack x,y em um int

    local dirs = { { 0, -2 }, { 0, 2 }, { -2, 0 }, { 2, 0 } }
    local neighbors = {}  -- reusado evita GC

    while stack_top > 0 do
        local packed = stack[stack_top]
        local cx = packed % 1000
        local cy = math.floor(packed / 1000)

        -- acha vizinhos validos
        local n_count = 0
        for i = 1, 4 do
            local dx, dy = dirs[i][1], dirs[i][2]
            local nx, ny = cx + dx, cy + dy

            if nx > 1 and nx < w and ny > 1 and ny < h and get(nx, ny) == C.T_WALL then
                n_count = n_count + 1
                neighbors[n_count] = i
            end
        end

        if n_count > 0 then
            local pick = neighbors[std.math.random(1, n_count)]
            local dx, dy = dirs[pick][1], dirs[pick][2]
            local nx, ny = cx + dx, cy + dy

            -- cava corredor
            set(cx + dx / 2, cy + dy / 2, C.T_EMPTY)
            set(nx, ny, C.T_EMPTY)

            stack_top = stack_top + 1
            stack[stack_top] = nx + ny * 1000
        else
            stack_top = stack_top - 1
        end
    end

    -- adiciona loops
    local loops = math.floor(size / 10)
    for _ = 1, loops do
        local rx = std.math.random(2, w - 1)
        local ry = std.math.random(2, h - 1)

        if get(rx, ry) == C.T_WALL then
            local open = 0
            if get(rx, ry - 1) == C.T_EMPTY then open = open + 1 end
            if get(rx, ry + 1) == C.T_EMPTY then open = open + 1 end
            if get(rx - 1, ry) == C.T_EMPTY then open = open + 1 end
            if get(rx + 1, ry) == C.T_EMPTY then open = open + 1 end

            if open == 2 then set(rx, ry, C.T_EMPTY) end
        end
    end

    -- coloca dots e conta
    local dots = 0
    local dots_x = {}  -- arrays separados melhor que table de tables
    local dots_y = {}
    local dots_count = 0

    for y = 1, h do
        for x = 1, w do
            if get(x, y) == C.T_EMPTY then
                if std.math.random(1, 100) > 20 then
                    set(x, y, C.T_DOT)
                    dots = dots + 1
                    dots_count = dots_count + 1
                    dots_x[dots_count] = x
                    dots_y[dots_count] = y
                end
            end
        end
    end

    -- acha spawns
    local function find_empty()
        for _ = 1, 1000 do
            local rx = std.math.random(2, w - 1)
            local ry = std.math.random(2, h - 1)
            if get(rx, ry) == C.T_EMPTY then
                return rx, ry
            end
        end
        return 2, 2
    end

    local sp_x, sp_y = find_empty()
    local sc_x, sc_y = find_empty()

    set(sp_x, sp_y, C.T_EMPTY)
    set(sc_x, sc_y, C.T_EMPTY)

    return {
        grid = grid,
        dots = dots,
        dots_x = dots_x,
        dots_y = dots_y,
        dots_count = dots_count,
        w = w,
        h = h,
        spawn_player = { x = sp_x, y = sp_y },
        spawn_critter = { x = sc_x, y = sc_y }
    }
end

return { generate = generate }
