-- UI routing

local menu = require('src/view/ui/menu')
local hud = require('src/view/ui/hud')
local upgrade = require('src/view/ui/upgrade')
local gameover = require('src/view/ui/gameover')
local evolution = require('src/view/ui/evolution')
local credits = require('src/view/ui/credits')
local pause = require('src/view/ui/pause')
local C = require('src/const')

local function draw(std, G, fps)
    local s = G.state

    if s == C.S_MENU then
        menu.draw(std, G.menu_cursor)
    elseif s == C.S_PLAY then
        hud.draw(std, G, fps)
    elseif s == C.S_UPGRADE then
        hud.draw(std, G, fps)
        upgrade.draw(std, G.upgrade_options, G.upgrade_cursor)
    elseif s == C.S_GAMEOVER then
        gameover.draw(std, G)
    elseif s == C.S_EVOLUTION then
        evolution.draw(std, G.player)
    elseif s == C.S_CREDITS then
        credits.draw(std)
    elseif s == C.S_PAUSE then
        -- desenha o jogo por baixo (congelado) + hud
        hud.draw(std, G, fps)
        -- overlay de pause por cima
        pause.draw(std, G)
    end
end

return { draw = draw }
