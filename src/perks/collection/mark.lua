return {
    id = "mark",
    name = "HUNTER'S MARK",
    desc = "always see the critter, even through walls.",
    icon = "{!}",
    type = "passive",
    color = 0xffff44FF,
    apply = function(p)
        p.has_mark = true
    end
}
