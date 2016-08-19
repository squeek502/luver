# Luver

[![Linux/OSX Build Status](https://travis-ci.org/squeek502/luver.svg?branch=master)](https://travis-ci.org/squeek502/luver)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/c1vetu3cpskb3qro/branch/master?svg=true)](https://ci.appveyor.com/project/squeek502/luver/branch/master)

Luver is a bare-bones alternative to [luvit][] that uses [lit][]'s `luvit-loader` instead of Luvit's require.

## Differences to Luvit

- No built-in libraries or dependencies other than `luvit-loader` and [luv][]/[luvi][]
- No exports table (or any other globals except for `arg`)
- No circular requires allowed

## Usage

`luver` takes a Lua script as its first parameter (`luver path/to/script.lua`). It will simply execute that script and start the `libuv` event loop for you.

### Example

```lua
-- test.lua
local uv = require('uv')
local handle = uv.new_timer()
local delay = 1000
local function ontimeout()
	uv.timer_stop(handle)
	uv.close(handle)
	print("Test")
end
uv.timer_start(handle, delay, 0, ontimeout)
```

Running `luver test.lua` would output "Test" after one second and then exit.

## Building

### Building using Lit

If you have [Lit](https://github.com/luvit/lit) installed, you can build Luver by executing:

```sh
lit make github://squeek502/luver
```

### Building from source

Building luver is easy and works cross-platform thanks to `Makefile` and `make.bat`.

```sh
git clone https://github.com/squeek502/luver.git
cd luver
make
```

If you want to use luver without constantly building, use `luvi`.

```sh
cd luver
luvi . -- path/to/script.lua
```

[luv]: https://github.com/luvit/luv/
[lit]: https://github.com/luvit/lit/
[luvi]: https://github.com/luvit/luvi/
[luvit]: https://github.com/luvit/luvit/
