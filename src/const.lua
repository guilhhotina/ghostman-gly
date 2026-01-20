-- constantes do ghostman
-- otimizado pra arm/mips, suponho q evite hashmap lookups
--
-- UML STATE MACHINE:
-- ┌─────────┐
-- │ MENU(0) │◄──────────────────────────┐
-- └────┬────┘                           │
--      │ start                          │ restart
--      ▼                                │
-- ┌─────────┐  death   ┌────────────┐   │
-- │ PLAY(1) │─────────►│ GAMEOVER(2)│───┘
-- └────┬────┘          └────────────┘
--      │ capture
--      ▼
-- ┌──────────┐  timer  ┌───────────┐  select
-- │CAPTURE(4)│────────►│ UPGRADE(3)│─────────┐
-- └──────────┘         └───────────┘         │
--      ▲                                     │
--      └─────────────────────────────────────┘
--
-- TILE TYPES: 0=empty, 1=wall, 2=dot, 3=fading
-- DIRECTIONS: 1=none, 2=up, 3=down, 4=left, 5=right

local P = {
    input = { cooldown = 100 },
    smooth = {
        actor_lerp = 0.18,
        actor_lerp_fast = 0.28,
        camera_lerp = 0.08,
        bob_speed = 0.008,
        bob_amplitude = 2.5,
        shake_decay = 0.06
    },
    balance = {
        dot_fade_start = 15000,
        dot_fade_interval = 2000,
        idle_threshold = 2000,
        base_critter_speed = 155,
        speed_per_level = 6,
        courage_speed_bonus = 25,
        ai_think_interval = 4  -- critter pensa a cada N frames
    },

    -- states como inteiros (zero hashmap lookup)
    S_MENU = 0,
    S_PLAY = 1,
    S_GAMEOVER = 2,
    S_UPGRADE = 3,
    S_CAPTURE = 4,
    S_EVOLUTION = 5,
    S_CREDITS = 6,
    S_PAUSE = 7,

    -- tiles como inteiros
    T_EMPTY = 0,
    T_WALL = 1,
    T_DOT = 2,
    T_FADING = 3,

    -- directions como inteiros
    D_NONE = 1,
    D_UP = 2,
    D_DOWN = 3,
    D_LEFT = 4,
    D_RIGHT = 5,

    -- vetores pre-computados (array = O(1) lookup)
    vectors = {
        { x = 0, y = 0 },   -- 1: none
        { x = 0, y = -1 },  -- 2: up
        { x = 0, y = 1 },   -- 3: down
        { x = -1, y = 0 },  -- 4: left
        { x = 1, y = 0 }    -- 5: right
    },

    -- paleta estilo NES (32 cores max)
    pal = {
        bg = 0x0a0a1aFF,
        bg_alt = 0x0f0f24FF,
        wall_top = 0x4a4a6aFF,
        wall_side = 0x2a2a40FF,
        blood = 0xFFD700FF,
        blood_stain = 0x886600FF,
        blood_splat = 0xFFD700AA,
        ghost = 0x88eeffFF,
        ghost_glow = 0x88eeff44,
        ghost_eye = 0x1a1a2eFF,
        ghost_pupil = 0x000000FF,
        ghost_angry = 0xff6688FF,
        critter = 0xff6666FF,
        critter_dark = 0xcc3333FF,
        critter_belly = 0xffaaaaFF,
        critter_eye = 0xffffffFF,
        critter_pupil = 0x000000FF,
        critter_brave = 0xffaa44FF,
        dot = 0xffd700FF,
        dot_glow = 0xffd70066,
        dot_fading = 0xff880088,
        ui_bg = 0x1a1a2aEE,
        ui_panel = 0x252540FF,
        ui_border = 0xaa88ffFF,
        ui_select = 0xff66aaFF,
        ui_dim = 0x000000AA,
        ui_shadow = 0x00000066,
        ui_warning = 0xff4444FF,
        ui_success = 0x44ff88FF,
        text = 0xf0f0f0FF,
        text_dim = 0x7080a0FF,
        text_highlight = 0xffffaaFF,
        perk_chains = 0x8888ffFF
    }
}

return P
