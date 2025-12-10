local map_str, map, p, g, t_mv, t_gh, dots, state, t_anim = {
    "###################",
    "#........#........#",
    "#.##.###.#.###.##.#",
    "#.................#",
    "#.##.#.#####.#.##.#",
    "#....#...#...#....#",
    "####.###.#.###.####",
    "#........g........#",
    "####.###.#.###.####",
    "#........p........#",
    "###################"
}, {}, {}, {}, 0, 0, 0, 'play', 0

for y=1, #map_str do
    map[y] = {}; for x=1, #map_str[y] do
        local c = map_str[y]:sub(x,x); map[y][x] = c
        if c == '.' then dots = dots + 1 end
        if c == 'p' then p = {x=x, y=y, dx=1, dy=0, nx=0, ny=0, frame=0}; map[y][x] = ' ' end
        if c == 'g' then g = {x=x, y=y, dx=0, dy=0}; map[y][x] = ' ' end
    end
end

local function valid(x, y) return map[y] and map[y][x] ~= '#' end

local function tick(data, std)
    if state ~= 'play' then if std.key.press.a then std.app.reset() end return end
    if std.key.press.left then p.nx, p.ny = -1, 0 elseif std.key.press.right then p.nx, p.ny = 1, 0 end
    if std.key.press.up then p.nx, p.ny = 0, -1 elseif std.key.press.down then p.nx, p.ny = 0, 1 end

    if std.milis > t_mv then -- pac logic
        t_mv, p.frame = std.milis + 150, (p.frame + 1) % 2
        if valid(p.x + p.nx, p.y + p.ny) and (p.nx~=0 or p.ny~=0) then p.dx, p.dy = p.nx, p.ny end
        if valid(p.x + p.dx, p.y + p.dy) then p.x, p.y = p.x + p.dx, p.y + p.dy end
        if map[p.y][p.x] == '.' then map[p.y][p.x] = ' '; dots = dots - 1 end
    end

    if std.milis > t_gh then -- ghost ai
        t_gh = std.milis + 250
        local best, min = nil, 9999
        for _, d in ipairs({{0,-1},{0,1},{-1,0},{1,0}}) do
            local tx, ty, dist = g.x + d[1], g.y + d[2], 0
            dist = math.abs(tx - p.x) + math.abs(ty - p.y)
            if valid(tx, ty) and dist < min then min, best = dist, d end
        end
        if best then g.x, g.y, g.dx, g.dy = g.x + best[1], g.y + best[2], best[1], best[2] end
    end
    if p.x == g.x and p.y == g.y then state = 'lose' elseif dots == 0 then state = 'win' end
end

local function draw_char(std, type, x, y, s, dir_x, dir_y, frame)
    if type == 'p' then -- pacman procedural
        std.draw.color(std.color.yellow)
        std.draw.rect(0, x, y, s, s) -- body
        if frame == 0 then -- mouth logic
            std.draw.color(std.color.black)
            local mx, my, ms = x + s/3, y + s/3, s/3
            if dir_x == 1 then mx = x + s/2 elseif dir_x == -1 then mx = x end
            if dir_y == 1 then my = y + s/2 elseif dir_y == -1 then my = y end
            std.draw.rect(0, mx, my, s/2, s/2)
        end
    else -- ghost procedural
        std.draw.color(std.color.red); std.draw.rect(0, x, y, s, s) -- body
        std.draw.color(std.color.white) -- eyes
        local ex, ey = x + s/4 + (dir_x*2), y + s/4 + (dir_y*2)
        std.draw.rect(0, ex, ey, 4, 4); std.draw.rect(0, ex + 6, ey, 4, 4)
        std.draw.color(std.color.blue) -- pupils
        std.draw.rect(0, ex+1+(dir_x), ey+1+(dir_y), 2, 2); std.draw.rect(0, ex + 7+(dir_x), ey+1+(dir_y), 2, 2)
    end
end

local function draw(data, std)
    local sw, sh = std.app.width, std.app.height
    local cell = math.min(sw / #map[1], sh / #map)
    local ox, oy = (sw - (#map[1]*cell))/2, (sh - (#map*cell))/2
    
    std.draw.clear(0x111111FF) -- soft bg
    for y=1, #map do
        for x=1, #map[y] do
            local px, py = ox + (x-1)*cell, oy + (y-1)*cell
            if map[y][x] == '#' then -- shaky walls effect
                std.draw.color(0x0000FFFF) -- blue neon
                local off = math.sin(std.milis/150 + x + y) * 2
                std.draw.rect(1, px + off, py + off, cell, cell)
            elseif map[y][x] == '.' then 
                std.draw.color(0xFFAAAAAA); std.draw.rect(0, px+cell/2-2, py+cell/2-2, 4, 4) 
            end
        end
    end

    draw_char(std, 'p', ox + (p.x-1)*cell, oy + (p.y-1)*cell, cell-2, p.dx, p.dy, p.frame)
    draw_char(std, 'g', ox + (g.x-1)*cell, oy + (g.y-1)*cell, cell-2, g.dx, g.dy, 0)

    if state ~= 'play' then
        std.draw.color(0x000000BB); std.draw.rect(0, 0, 0, sw, sh)
        std.draw.color(state == 'win' and std.color.green or std.color.red)
        std.text.print_ex(sw/2, sh/2, state:upper().."! PRESS 'A' TO RESET", 0)
    end
end

return { meta={title='GhostMan', version='0.3', author='Guilhotina'}, callbacks={loop=tick, draw=draw} }
