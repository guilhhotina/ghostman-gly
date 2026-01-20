-- chains perk: slows the critter when nearby
-- 5s cooldown

local effects = require('src/view/effects')
local const = require('src/const')

return {
    id = "chains",
    name = "SPECTRAL CHAINS",
    desc = "slows prey nearby. 5s cooldown.",
    icon = "o-o",
    type = "active",
    color = 0x8888ffFF,

    apply = function(p)
        p.has_chains = true
    end,

    update = function(p, std, G, triggered)
        if triggered and G.ability_cooldown <= 0 then
            -- feedback visual imediato
            effects.magic_spark(std, p.real_x, p.real_y, 0x8888ffFF)

            local dist = std.math.dis(p.x, p.y, G.critter.x, G.critter.y)

            -- alcance aumentado de 6 pra 8 tiles
            if dist < 8 then
                -- sucesso: pegou o bicho!
                G.ability_cooldown = 5000
                G.shake = 5
                G.critter.chained = true
                G.critter.chain_timer = 3000
                G.critter.speed_mod = 50

                -- efeito magico no alvo tambem
                effects.magic_spark(std, G.critter.real_x, G.critter.real_y, 0xffffffff)
            else
                -- falha: errou o alvo
                -- cooldown curto (1s) pra nao spammar
                G.ability_cooldown = 1000
            end
        end

        return false
    end
}
