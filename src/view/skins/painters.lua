-- painters de sprites do ghostman
-- funcoes de desenho para cada tipo de skin

local const = require('src/const')
local sprites = require('src/view/skins/sprites')
local P = {}
local math_ceil, math_floor, math_sin = math.ceil, math.floor, math.sin
local _geo_flat = {}

-- compila sprite 8x8 em stream de rects (run-length encoding)
local function compile_flat(name, matrix)
    local stream = {}
    local idx = 1
    for py = 1, 8 do
        local row = matrix[py]
        if row then
            local current_c = nil
            local run_start = 1
            for px = 1, 8 do
                local c = row[px]
                if c ~= current_c then
                    if current_c and current_c > 0 then
                        stream[idx], stream[idx + 1], stream[idx + 2], stream[idx + 3] = run_start - 1, py - 1,
                            px - run_start, current_c
                        idx = idx + 4
                    end
                    current_c = c
                    run_start = px
                end
            end
            if current_c and current_c > 0 then
                stream[idx], stream[idx + 1], stream[idx + 2], stream[idx + 3] = run_start - 1, py - 1, 9 - run_start,
                    current_c
                idx = idx + 4
            end
        end
    end
    _geo_flat[name] = stream
end

compile_flat('wall', sprites.wall)
compile_flat('floor', sprites.floor)
compile_flat('dot', sprites.dot)

-- desenha sprite compilado
local function draw_flat(std, x, y, s, geo_name, c1, c2, c3)
    if s < 8 then
        if c1 then
            std.draw.color(c1); std.draw.rect(0, x, y, s, s)
        end
        return
    end
    local stream = _geo_flat[geo_name]
    if not stream then return end
    local ps = s / 8
    local i = 1
    while i <= #stream do
        local px, py, pw, c_idx = stream[i], stream[i + 1], stream[i + 2], stream[i + 3]
        local col = (c_idx == 1 and c1) or (c_idx == 2 and c2) or (c_idx == 3 and c3)
        if col then
            std.draw.color(col)
            std.draw.rect(0, x + px * ps, y + py * ps, pw * ps + 0.5, ps + 0.5)
        end
        i = i + 4
    end
end

-- parede com tijolos
function P.wall_bricks(std, x, y, s, c_top, c_side, c_stain, milis)
    std.draw.color(c_side)
    std.draw.rect(0, x, y, s, s)
    draw_flat(std, x, y, s, 'wall', c_top, 0x88888833, 0x00000044)
    if c_stain then
        local dw = s * 0.2
        std.draw.color(const.pal.blood_stain)
        for i = 1, 2 do
            local off = math.sin(x + i) * 2
            std.draw.rect(0, x + (i * 8) % s, y, dw, s * 0.6 + off)
        end
    end
end

-- chao com tile
function P.floor_tile(std, x, y, s, col, milis, has_dread)
    std.draw.color(col)
    std.draw.rect(0, x, y, s + 1, s + 1)
    if has_dread then
        std.draw.color(0x550055FF)
        std.draw.rect(0, x + 2, y + 2, s - 4, s - 4)
    else
        draw_flat(std, x, y, s, 'floor', 0xFFFFFF0A, 0xFFFFFF15, nil)
    end
end

-- dot brilhando
function P.dot_pixel(std, x, y, s, col, glow_col, milis)
    local pulse = math.sin(milis * 0.004) * 0.15 + 0.85
    local gs = s * 0.6 * pulse
    std.draw.color(glow_col)
    std.draw.rect(0, x + (s - gs) / 2, y + (s - gs) / 2, gs, gs)
    draw_flat(std, x, y, s, 'dot', col, 0xFFFFFFAA, nil)
end

-- dot fading (roxo)
function P.dot_fading(std, x, y, s, milis)
    local pulse = math.sin(milis * 0.01) * 0.5 + 0.5
    local sz = s * 0.4 * (0.5 + pulse * 0.5)
    std.draw.color(const.pal.dot_fading)
    std.draw.rect(0, x + (s - sz) / 2, y + (s - sz) / 2, sz, sz)
end

-- fantasma classico
function P.ghost_classic(std, x, y, s, col, milis, opts)
    local sq = opts.squash or 0
    local sx = 1 - sq * 0.15
    local sy = 1 + sq * 0.1
    if opts.dashing then
        sx, sy = (opts.dir == 2 or opts.dir == 3) and 0.6 or 1.4, (opts.dir == 2 or opts.dir == 3) and 1.4 or 0.6
    end
    local w, h = s * 0.85 * sx, s * 0.9 * sy
    local cx, cy = x + (s - w) / 2, y + s - h
    std.draw.color(const.pal.ghost_glow)
    std.draw.rect(0, cx - 2, cy + h * 0.3, w + 4, h * 0.7)
    local body_col = opts.aiming and const.pal.ghost_angry or col
    std.draw.color(body_col)
    std.draw.rect(0, cx + w * 0.1, cy, w * 0.8, h * 0.6)
    std.draw.rect(0, cx, cy + h * 0.3, w, h * 0.5)
    local wb, tw, by = milis * 0.012, w / 3, cy + h * 0.75
    for i = 0, 2 do std.draw.rect(0, cx + tw * i, by + math_sin(wb + i * 2) * 3, tw, h * 0.25) end
    if (opts.blood_stain or 0) > 0.05 then
        local ss = w * 0.3 * opts.blood_stain
        std.draw.color(const.pal.blood_splat)
        std.draw.rect(0, cx + w * 0.2, cy + h * 0.4, ss, ss)
    end
end

-- olhos do fantasma
function P.eyes_happy(std, x, y, s, dir, aim, milis, squash)
    squash = squash or 0
    local squint_factor = 1.0
    if squash < 0 then squint_factor = 1.0 + (squash * 0.8) end

    local ew, eh = s * 0.18, (aim and s * 0.12 or s * 0.22) * squint_factor
    local ey = y + s * 0.32 + (squash < 0 and -squash * s * 0.1 or 0)
    local lx, ly = (dir == 4 and -2 or (dir == 5 and 2 or 0)), (dir == 2 and -2 or (dir == 3 and 2 or 0))
    local lex, rex, eyy = x + s * 0.25 + lx, x + s * 0.55 + lx, ey + ly

    std.draw.color(const.pal.ghost_eye)
    std.draw.rect(0, lex, eyy, ew, eh)
    std.draw.rect(0, rex, eyy, ew, eh)
    if not aim then
        local p = ew * 0.6
        std.draw.color(const.pal.ghost_pupil)
        std.draw.rect(0, lex + ew * 0.2 + lx * 0.3, eyy + eh * 0.3, p, p)
        std.draw.rect(0, rex + ew * 0.2 + lx * 0.3, eyy + eh * 0.3, p, p)
    end
end

-- shotgun rotacionada
function P.gun_shotgun_rotated(std, x, y, s, angle, milis)
    local cx, cy = x + s / 2, y + s / 2
    local r, gun_len = s * 0.6, s * 0.6
    local gx, gy = cx + math.cos(angle) * r, cy + math.sin(angle) * r
    local function draw_rot(px, py, len, thick, col)
        std.draw.color(col)
        local steps = math_ceil(len / 2)
        local dx, dy = math.cos(angle) * (len / steps), math.sin(angle) * (len / steps)
        for i = 0, steps do std.draw.rect(0, px + dx * i - thick / 2, py + dy * i - thick / 2, thick, thick) end
    end
    draw_rot(gx, gy, gun_len * 0.4, 4, 0x8B4513FF)
    draw_rot(gx + math.cos(angle) * gun_len * 0.4, gy + math.sin(angle) * gun_len * 0.4, gun_len * 0.6, 3, 0xAAAAAAFF)
end

-- laser de mira
function P.aim_laser_rotated(std, x, y, s, angle, milis)
    local cx, cy = x + s / 2, y + s / 2
    local p = math_sin(milis * 0.018) * 0.3 + 0.7
    std.draw.color(const.pal.critter)
    for i = 1, 10, 2 do
        local dist, ds = s * 0.6 + i * (s * 0.25), 2 * p
        std.draw.rect(0, cx + math.cos(angle) * dist - ds / 2, cy + math.sin(angle) * dist - ds / 2, ds, ds)
    end
end

-- corpo do critter (bichinho redondinho)
function P.critter_blob(std, x, y, s, col, milis, opts)
    local sq = opts.squash or 0
    local sx, sy = 1 + sq * 0.2, 1 - sq * 0.15
    local w, h = s * 0.8 * sx, s * 0.7 * sy
    local cx, cy = x + (s - w) / 2, y + s - h - 2
    local b = opts.chained and 0 or math.abs(math_sin(milis * 0.012)) * 3
    cy = cy - b
    std.draw.color(0x00000033)
    std.draw.rect(0, cx + 2, y + s - 4, w - 4, 4)
    if opts.chained then
        std.draw.color(const.pal.perk_chains)
        std.draw.rect(0, cx - 3, cy + h * 0.3, w + 6, 3)
        std.draw.rect(0, cx - 3, cy + h * 0.6, w + 6, 3)
    end
    local c = opts.brave and const.pal.critter_brave or col
    std.draw.color(c)
    std.draw.rect(0, cx + w * 0.1, cy, w * 0.8, h)
    std.draw.rect(0, cx, cy + h * 0.15, w, h * 0.7)
    std.draw.color(const.pal.critter_belly)
    std.draw.rect(0, cx + w * 0.25, cy + h * 0.35, w * 0.5, h * 0.4)
    std.draw.color(const.pal.critter_dark)
    std.draw.rect(0, cx + w * 0.15, cy + h - 2, w * 0.2, h * 0.15)
    std.draw.rect(0, cx + w * 0.65, cy + h - 2, w * 0.2, h * 0.15)
    local aw = math_sin(milis * 0.012) * (opts.scared and 4 or 2)
    std.draw.color(c)
    std.draw.rect(0, cx + w * 0.3, cy - 6 + aw, 2, 8)
    std.draw.rect(0, cx + w * 0.6, cy - 6 - aw, 2, 8)
    return cx, cy, w, h
end

-- olhos do critter
function P.critter_eyes(std, x, y, s, dir, scared, brave, body, milis)
    local cx, cy, w, h = body[1], body[2], body[3], body[4]
    local es = scared and s * 0.24 or s * 0.18
    local ey = cy + h * 0.28
    local lx = (dir == 4 and -2) or (dir == 5 and 2) or 0
    std.draw.color(const.pal.critter_eye)
    std.draw.rect(0, cx + w * 0.18, ey, es, es)
    std.draw.rect(0, cx + w * 0.54, ey, es, es)
    local p, po = scared and es * 0.25 or es * 0.5, (es - (scared and es * 0.25 or es * 0.5)) / 2
    std.draw.color(const.pal.critter_pupil)
    std.draw.rect(0, cx + w * 0.18 + po + lx, ey + po, p, p)
    std.draw.rect(0, cx + w * 0.54 + po + lx, ey + po, p, p)
end

-- logo pixel art "ghostman"
function P.logo_pixel(std, cx, cy, s, color, shadow_color)
    local gap = math_floor(s / 2)
    local font = { G = { 1, 1, 1, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 1, 1 }, H = { 1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 0, 1 }, O = { 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1 }, S = { 1, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1 }, T = { 1, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0 }, M = { 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1 }, A = { 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 0, 1 }, N = { 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1 } }
    local text = "GHOSTMAN"
    local start_x = cx - (#text * (3 * s + gap) - gap) / 2
    for i = 1, #text do
        local map = font[text:sub(i, i)]
        local lx = start_x + (i - 1) * (3 * s + gap)
        for idx = 0, 14 do
            if map[idx + 1] == 1 then
                local px, py = idx % 3, math_floor(idx / 3)
                if shadow_color then
                    std.draw.color(shadow_color); std.draw.rect(0, lx + px * s + s, cy + py * s + s, s, s)
                end
                std.draw.color(color); std.draw.rect(0, lx + px * s, cy + py * s, s, s)
            end
        end
    end
end

return P
