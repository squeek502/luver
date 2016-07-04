--[[

Copyright 2014-2016 The Luvit Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

]]

--[[lit-meta
  name = "squeek502/luvit-loader"
  description = "The loader used by lit for luvit-like requires"
  version = "1.0.0"
  tags = {"loader"}
  license = "MIT"
  author = { name = "Tim Caswell" }
]]

local hasLuvi, luvi = pcall(require, 'luvi')
local uv, pathjoin

if hasLuvi then
  uv = require('uv')
  pathLib = loadstring(luvi.bundle.readfile("deps/pathjoin.lua"), "bundle:deps/pathjoin.lua")()
else
  uv = require('luv')
  pathLib = loadfile("deps/pathjoin.lua")()
end

local pathJoin, isWindows = pathLib.pathJoin, pathLib.isWindows

local getenv = require('os').getenv

local tmpBase = isWindows and (getenv("TMP") or uv.cwd()) or
                              (getenv("TMPDIR") or '/tmp')
local binExt = isWindows and ".dll" or ".so"

local function loader(dir, path, bundleOnly)
  local errors = {}
  local fullPath
  local useBundle = bundleOnly
  local function try(tryPath)
    local prefix = useBundle and "bundle:" or ""
    local fileStat = useBundle and luvi.bundle.stat or uv.fs_stat

    local newPath = tryPath
    local stat = fileStat(newPath)
    if stat and stat.type == "file" then
      fullPath = newPath
      return true
    end
    errors[#errors + 1] = "\n\tno file '" .. prefix .. newPath .. "'"

    newPath = tryPath .. ".lua"
    stat = fileStat(newPath)
    if stat and stat.type == "file" then
      fullPath = newPath
      return true
    end
    errors[#errors + 1] = "\n\tno file '" .. prefix .. newPath .. "'"

    newPath = pathJoin(tryPath, "init.lua")
    stat = fileStat(newPath)
    if stat and stat.type == "file" then
      fullPath = newPath
      return true
    end
    errors[#errors + 1] = "\n\tno file '" .. prefix .. newPath .. "'"

  end
  if string.sub(path, 1, 1) == "." then
    -- Relative require
    if not try(pathJoin(dir, path)) then
      return table.concat(errors)
    end
  else
    while true do
      if try(pathJoin(dir, "deps", path)) or
         try(pathJoin(dir, "libs", path)) then
        break
      end
      if dir == pathJoin(dir, "..") then
        return table.concat(errors)
      end
      dir = pathJoin(dir, "..")
    end
    -- Module require
  end
  if useBundle then
    local key = "bundle:" .. fullPath
    return function ()
      if package.loaded[key] then
        return package.loaded[key]
      end
      local code = luvi.bundle.readfile(fullPath)
      local module = loadstring(code, key)()
      package.loaded[key] = module
      return module
    end, key
  end
  fullPath = uv.fs_realpath(fullPath)
  return function ()
    if package.loaded[fullPath] then
      return package.loaded[fullPath]
    end
    local module = assert(loadfile(fullPath))(fullPath)
    package.loaded[fullPath] = module
    return module
  end
end

-- Register as a normal lua package loader.
local cwd = uv.cwd()
table.insert(package.loaders, 1, function (path)

  -- Ignore built-in libraries with this loader.
  if path:match("^[a-z]+$") and package.preload[path] then
    return
  end

  local level = 3
  local caller = debug.getinfo(level, "S").source
  while caller == "=[C]" do
    level = level + 1
    caller = debug.getinfo(level, "S").source
  end
  if string.sub(caller, 1, 1) == "@" then
    return loader(pathJoin(cwd, caller:sub(2), ".."), path)
  elseif string.sub(caller, 1, 7) == "bundle:" then
    return loader(pathJoin(caller:sub(8), ".."), path, true)
  end
end)
