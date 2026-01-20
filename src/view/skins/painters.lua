-- painters otimizado
-- sprites compilados como streams de bytes (run-length encoding)

local C = require('src/const')
local sprites = require('src/view/skins/sprites')

local math_ceil = math.ceil
local math_floor = math.floor
local math_sin = math.sin
local math_cos = math.cos

-- sprites compilados (pre-processados uma vez)
local compiled = {}

-- compila sprite 8x8 em stream de rects
local function compile_sprite(name, matrix)
    local stream = {}
    local idx = 1

    for py = 1, 8 do
        local row = matrix[py]
        if row then
            local cur_c = nil
            local run_start = 1

            for px = 1, 8 do
                local c = row[px]
                if c ~= cur_c then
                    if cur_c and cur_c > 0 then
                        stream[idx] = run_start - 1
                        stream[idx + 1] = py - 1
                        stream[idx + 2] = px - run_start
                        stream[idx + 3] = cur_c
                        idx = idx + 4
                    end
                    cur_c = c
                    run_start = px
                end
            end

            if cur_c and cur_c > 0 then
                stream[idx] = run_start - 1
                stream[idx + 1] = py - 1
                stream[idx + 2] = 9 - run_start
                stream[idx + 3] = cur_c
                idx = idx + 4
            end
        end
    end

    compiled[name] = stream
end

-- compila sprites na carga
compile_sprite("wall", sprites.wall)
compile_sprite("floor", sprites.floor)
compile_sprite("dot", sprites.dot)

-- desenha sprite compilado
local function draw_compiled(std, x, y, s, name, c1, c2, c3)
    if s < 8 then
        if c1 then
            std.draw.color(c1)
            std.draw.rect(0, x, y, s, s)
        end
        return
    end

    local stream = compiled[name]
    if not stream then return end

    local ps = s / 8
    local i = 1

    while i <= #stream do
        local px, py, pw, ci = stream[i], stream[i + 1], stream[i + 2], stream[i + 3]
        local col = (ci == 1 and c1) or (ci == 2 and c2) or (ci == 3 and c3)

        if col then
            std.draw.color(col)
            std.draw.rect(0, x + px * ps, y + py * ps, pw * ps + 0.5, ps + 0.5)
        end
        i = i + 4
    end
end

-- parede
local function wall_bricks(std, x, y, s, c_top, c_side, milis)
    std.draw.color(c_side)
    std.draw.rect(0, x, y, s, s)
    draw_compiled(std, x, y, s, "wall", c_top, 0x88888833, 0x00000044)
end

-- chao
local function floor_tile(std, x, y, s, col, milis, dread)
    std.draw.color(col)
    std.draw.rect(0, x, y, s + 1, s + 1)

    if dread then
        std.draw.color(0x550055FF)
        std.draw.rect(0, x + 2, y + 2, s - 4, s - 4)
    else
        draw_compiled(std, x, y, s, "floor", 0xFFFFFF0A, 0xFFFFFF15, nil)
    end
end

-- dot
local function dot_pixel(std, x, y, s, col, glow, milis)
    local pulse = math_sin(milis * 0.004) * 0.15 + 0.85
    local gs = s * 0.6 * pulse

    std.draw.color(glow)
    std.draw.rect(0, x + (s - gs) / 2, y + (s - gs) / 2, gs, gs)
    draw_compiled(std, x, y, s, "dot", col, 0xFFFFFFAA, nil)
end

-- dot fading
local function dot_fading(std, x, y, s, milis)
    local pulse = math_sin(milis * 0.01) * 0.5 + 0.5
    local sz = s * 0.4 * (0.5 + pulse * 0.5)
    std.draw.color(C.pal.dot_fading)
    std.draw.rect(0, x + (s - sz) / 2, y + (s - sz) / 2, sz, sz)
end

-- fantasma
local function ghost_classic(std, x, y, s, col, milis, opts)
    local sq = opts.squash or 0
    local sx = 1 - sq * 0.15
    local sy = 1 + sq * 0.1

    if opts.dashing then
        local vert = opts.curr_dir == 2 or opts.curr_dir == 3
        sx = vert and 0.6 or 1.4
        sy = vert and 1.4 or 0.6
    end

    local w = s * 0.85 * sx
    local h = s * 0.9 * sy
    local cx = x + (s - w) / 2
    local cy = y + s - h

    -- glow
    std.draw.color(C.pal.ghost_glow)
    std.draw.rect(0, cx - 2, cy + h * 0.3, w + 4, h * 0.7)

    -- corpo
    local body_col = opts.aiming and C.pal.ghost_angry or col
    std.draw.color(body_col)
    std.draw.rect(0, cx + w * 0.1, cy, w * 0.8, h * 0.6)
    std.draw.rect(0, cx, cy + h * 0.3, w, h * 0.5)

    -- tentaculos
    local wb = milis * 0.012
    local tw = w / 3
    local by = cy + h * 0.75

    for i = 0, 2 do
        std.draw.rect(0, cx + tw * i, by + math_sin(wb + i * 2) * 3, tw, h * 0.25)
    end
end

-- olhos
local function eyes_happy(std, x, y, s, dir, aim, milis, squash)
    squash = squash or 0
    local sf = 1.0
    if squash < 0 then sf = 1.0 + squash * 0.8 end

    local ew = s * 0.18
    local eh = (aim and s * 0.12 or s * 0.22) * sf
    local ey = y + s * 0.32

    if squash < 0 then ey = ey - squash * s * 0.1 end

    local lx = (dir == 4 and -2) or (dir == 5 and 2) or 0
    local ly = (dir == 2 and -2) or (dir == 3 and 2) or 0

    local lex = x + s * 0.25 + lx
    local rex = x + s * 0.55 + lx
    local eyy = ey + ly

    std.draw.color(C.pal.ghost_eye)
    std.draw.rect(0, lex, eyy, ew, eh)
    std.draw.rect(0, rex, eyy, ew, eh)

    if not aim then
        local p = ew * 0.6
        std.draw.color(C.pal.ghost_pupil)
        std.draw.rect(0, lex + ew * 0.2 + lx * 0.3, eyy + eh * 0.3, p, p)
        std.draw.rect(0, rex + ew * 0.2 + lx * 0.3, eyy + eh * 0.3, p, p)
    end
end

-- shotgun
local function gun_shotgun(std, x, y, s, angle, milis)
    local cx = x + s / 2
    local cy = y + s / 2
    local r = s * 0.6

    local gx = cx + math_cos(angle) * r
    local gy = cy + math_sin(angle) * r

    local function draw_line(px, py, len, thick, col)
        std.draw.color(col)
        local steps = math_ceil(len / 2)
        local dx = math_cos(angle) * (len / steps)
        local dy = math_sin(angle) * (len / steps)

        for i = 0, steps do
            std.draw.rect(0, px + dx * i - thick / 2, py + dy * i - thick / 2, thick, thick)
        end
    end

    draw_line(gx, gy, s * 0.24, 4, 0x8B4513FF)
    draw_line(gx + math_cos(angle) * s * 0.24, gy + math_sin(angle) * s * 0.24, s * 0.36, 3, 0xAAAAAAFF)
end

-- laser de mira
local function aim_laser(std, x, y, s, angle, milis)
    local cx = x + s / 2
    local cy = y + s / 2
    local p = math_sin(milis * 0.018) * 0.3 + 0.7

    std.draw.color(C.pal.critter)
    for i = 1, 10, 2 do
        local dist = s * 0.6 + i * s * 0.25
        local ds = 2 * p
        std.draw.rect(0, cx + math_cos(angle) * dist - ds / 2, cy + math_sin(angle) * dist - ds / 2, ds, ds)
    end
end

-- critter body
local function critter_blob(std, x, y, s, col, milis, opts)
    local sq = opts.squash or 0
    local sx = 1 + sq * 0.2
    local sy = 1 - sq * 0.15

    local w = s * 0.8 * sx
    local h = s * 0.7 * sy
    local cx = x + (s - w) / 2
    local cy = y + s - h - 2

    local bounce = opts.chained and 0 or math.abs(math_sin(milis * 0.012)) * 3
    cy = cy - bounce

    -- sombra
    std.draw.color(0x00000033)
    std.draw.rect(0, cx + 2, y + s - 4, w - 4, 4)

    -- chains
    if opts.chained then
        std.draw.color(C.pal.perk_chains)
        std.draw.rect(0, cx - 3, cy + h * 0.3, w + 6, 3)
        std.draw.rect(0, cx - 3, cy + h * 0.6, w + 6, 3)
    end

    -- corpo
    local c = opts.brave and C.pal.critter_brave or col
    std.draw.color(c)
    std.draw.rect(0, cx + w * 0.1, cy, w * 0.8, h)
    std.draw.rect(0, cx, cy + h * 0.15, w, h * 0.7)

    -- barriga
    std.draw.color(C.pal.critter_belly)
    std.draw.rect(0, cx + w * 0.25, cy + h * 0.35, w * 0.5, h * 0.4)

    -- pes
    std.draw.color(C.pal.critter_dark)
    std.draw.rect(0, cx + w * 0.15, cy + h - 2, w * 0.2, h * 0.15)
    std.draw.rect(0, cx + w * 0.65, cy + h - 2, w * 0.2, h * 0.15)

    -- antenas
    local aw = math_sin(milis * 0.012) * (opts.scared and 4 or 2)
    std.draw.color(c)
    std.draw.rect(0, cx + w * 0.3, cy - 6 + aw, 2, 8)
    std.draw.rect(0, cx + w * 0.6, cy - 6 - aw, 2, 8)

    return cx, cy, w, h
end

-- critter eyes
local function critter_eyes(std, x, y, s, dir, scared, brave, body, milis)
    local cx, cy, w, h = body[1], body[2], body[3], body[4]

    local es = scared and s * 0.24 or s * 0.18
    local ey = cy + h * 0.28
    local lx = (dir == 4 and -2) or (dir == 5 and 2) or 0

    std.draw.color(C.pal.critter_eye)
    std.draw.rect(0, cx + w * 0.18, ey, es, es)
    std.draw.rect(0, cx + w * 0.54, ey, es, es)

    local p = scared and es * 0.25 or es * 0.5
    local po = (es - p) / 2

    std.draw.color(C.pal.critter_pupil)
    std.draw.rect(0, cx + w * 0.18 + po + lx, ey + po, p, p)
    std.draw.rect(0, cx + w * 0.54 + po + lx, ey + po, p, p)
end

-- logo pixel art
local function logo_pixel(std, cx, cy, s, color, shadow)
    local gap = math_floor(s / 2)
    local font = {
        G = { 1, 1, 1, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 1, 1 },
        H = { 1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 0, 1 },
        O = { 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1 },
        S = { 1, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1 },
        T = { 1, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0 },
        M = { 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1 },
        A = { 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 0, 1 },
        N = { 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1 }
    }

    local text = "GHOSTMAN"
    local start_x = cx - (#text * (3 * s + gap) - gap) / 2

    for i = 1, #text do
        local map = font[text:sub(i, i)]
        local lx = start_x + (i - 1) * (3 * s + gap)

        for idx = 0, 14 do
            if map[idx + 1] == 1 then
                local px = idx % 3
                local py = math_floor(idx / 3)

                if shadow then
                    std.draw.color(shadow)
                    std.draw.rect(0, lx + px * s + s, cy + py * s + s, s, s)
                end

                std.draw.color(color)
                std.draw.rect(0, lx + px * s, cy + py * s, s, s)
            end
        end
    end
end

return {
    wall_bricks = wall_bricks,
    floor_tile = floor_tile,
    dot_pixel = dot_pixel,
    dot_fading = dot_fading,
    ghost_classic = ghost_classic,
    eyes_happy = eyes_happy,
    gun_shotgun = gun_shotgun,
    aim_laser = aim_laser,
    critter_blob = critter_blob,
    critter_eyes = critter_eyes,
    logo_pixel = logo_pixel
}
