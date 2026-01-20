-- ui do ghostman
-- routing pra outras telas de ui

local menu = require('src/view/ui/menu')
local hud = require('src/view/ui/hud')
local upgrade = require('src/view/ui/upgrade')
local gameover = require('src/view/ui/gameover')
local evolution = require('src/view/ui/evolution')
local credits = require('src/view/ui/credits')
local const = require('src/const')
local P = {}

-- draw da ui baseado no estado do jogo
function P.draw(std, G, fps_enabled)
    local s = G.state
    if s == const.state.menu then
        menu.draw(std, G.menu_cursor)
    elseif s == const.state.play then
        hud.draw(std, G, fps_enabled)
    elseif s == const.state.upgrade then
        hud.draw(std, G, fps_enabled)
        upgrade.draw(std, G.upgrade_options, G.upgrade_cursor)
    elseif s == const.state.gameover then
        gameover.draw(std)
    elseif s == const.state.evolution then
        evolution.draw(std, G.player)
    elseif s == const.state.credits then
        credits.draw(std)
    end
end

return P
