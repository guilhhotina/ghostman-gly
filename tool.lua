-- tool.lua
local is_win = package.config:sub(1, 1) == "\\"
local task = arg[1] or "help"

-- config de diretorios
local PATH = {
    engine_url = "https://github.com/gly-engine/gly-engine.git",
    engine     = "vendor/gly-engine",
    game_src   = "src",
    dist       = "dist/web"
}

-- abstraçao de comandos do sistema
local CMD = is_win and {
    mkdir = "mkdir %s 2>nul",
    rm    = "rd /s /q %s 2>nul",
    cp    = "xcopy /E /I /Y %s %s >nul",
    cd    = "cd %s && %s"
} or {
    mkdir = "mkdir -p %s",
    rm    = "rm -rf %s",
    cp    = "cp -r %s/* %s",
    cd    = "(cd %s && %s)"
}

-- run cmd
local function run(fmt, ...)
    local cmd = string.format(fmt, ...)
    print(">> " .. cmd)
    local ok = os.execute(cmd)
    if not ok then
        print("[erro] cmd failed."); os.exit(1)
    end
end

-- check if engine exists, download if not
local function setup_engine()
    if not io.open(PATH.engine .. "/README.md") then
        print("[info] downloading engine...")
        run(CMD.mkdir, "vendor")
        run("git clone --depth 1 %s %s", PATH.engine_url, PATH.engine)
    end
end

-- copy game to engine folder (fix path issue with love)
local function sync_game()
    local dest = PATH.engine .. "/" .. PATH.game_src
    if is_win then run(CMD.mkdir, dest:gsub("/", "\\")) else run(CMD.mkdir, dest) end
    run(CMD.cp, PATH.game_src, dest)
end

-- run engine cli
local function engine_cli(args)
    setup_engine()
    sync_game()
    run(CMD.cd, PATH.engine, "lua source/cli/main.lua " .. args)
end

-- tasks
if task == "dev" then
    engine_cli("run src/game.lua")
elseif task == "build" then
    run(CMD.rm, "dist")
    engine_cli("build-html src/game.lua --outdir ../../" .. PATH.dist .. " --enginecdn")
elseif task == "clean" then
    run(CMD.rm, "vendor")
    run(CMD.rm, "dist")
elseif task == "deploy" then
    os.execute("lua tool.lua build")
    os.execute("fly deploy")
else
    print("uso: lua tool.lua [dev | build | clean | deploy]")
end
