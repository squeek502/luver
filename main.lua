local hasLuvi, luvi = pcall(require, 'luvi')
local bundleLoad = function(file)
  if hasLuvi then
    return loadstring(luvi.bundle.readfile(file), "bundle:" .. file)()
  else
   return dofile(file)
  end
end
bundleLoad("deps/luvit-loader.lua")

local uv = require('uv')
local pathjoin = require('pathjoin')

local args = {...}
local script
script = table.remove(args, 1)
if _G.arg then
  table.remove(arg, 1)
  _G.arg[-2] = arg[0]
else
  _G.arg = args
  if hasLuvi then
    _G.arg[-2] = luvi.bundle.mainPath
  end
end
_G.arg[-1] = uv.exepath()
_G.arg[0] = script

local usage = function()
  print("Usage: luver script.lua [arguments]"..[[


  Options:
    -h, --help          Print this help screen.
    -v, --version       Print the version.
  ]])
end

local function version()
  local version = bundleLoad("package.lua").version
  print(version)
end

if not script or script == "-h" or script == "--help" then
  usage()
elseif script == "-v" or script == "--version" then
  version()
else
  local success, err = xpcall(function ()
    local scriptFullPath = pathjoin.pathJoin(uv.cwd(), script)
    local fn = assert(loadfile(scriptFullPath))

    fn(unpack(args))

    -- Start the event loop
    uv.run()
  end, debug.traceback)

  local exitCode = 0
  if not success then
    local stderr
    if uv.guess_handle(2) == 'tty' then
      stderr = assert(uv.new_tty(2, false))
    else
      stderr = uv.new_pipe(false)
      uv.pipe_open(stderr, 2)
    end
    stderr:write("Uncaught Error: " .. err .. "\n")
    stderr:close()
    exitCode = -1
  end

  uv.walk(function (handle)
    if handle and not handle:is_closing() then handle:close() end
  end)
  uv.run()
end

os.exit(exitCode)