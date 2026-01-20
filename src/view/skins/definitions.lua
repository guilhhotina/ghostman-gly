-- visual dos personagens e elementos
local const = require('src/const')

return {
    player = {
        body = "ghost_classic",
        color = const.pal.ghost,
        eyes = "eyes_happy",
        accessory = "gun_shotgun"
    },
    critter = {
        body = "spiky_ball",
        color = const.pal.critter,
        eyes = "eyes_angry"
    },
    ally_leapy = {
        body = "slime",
        color = const.pal.ally_leapy,
        eyes = "eyes_determined"
    },
    ally_bursty = {
        body = "blocky",
        color = const.pal.ally_bursty,
        eyes = "eyes_pixel"
    },
    wall = {
        type = "static",
        color_top = const.pal.wall_top,
        color_side = const.pal.wall_side
    },
    floor = {
        type = "static",
        body = "floor_tile",
        color = 0x101020FF -- um pouquinho mais claro que o bg
    },
    dot = {
        type = "static",
        color = const.pal.dot
    }
}
