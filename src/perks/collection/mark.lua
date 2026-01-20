return {
    id = "mark",
    name = "hunter's mark",
    desc = "sempre ve onde o critter ta. mesmo atraves das paredes.",
    icon = "{!}",
    type = "passive",
    color = 0xffff44FF,
    apply = function(p)
        p.has_mark = true
    end
}
