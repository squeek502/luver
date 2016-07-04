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

if not success then
  print(err)
  os.exit(-1)
end