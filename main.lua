local hasLuvi, luvi = pcall(require, 'luvi')
if hasLuvi then
  loadstring(luvi.bundle.readfile("deps/luvit-loader.lua"), "bundle:deps/luvit-loader.lua")()
else
  dofile("deps/luvit-loader.lua")
end

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

os.exit(exitCode)