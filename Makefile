APP_FILES=$(shell find . -type f -name '*.lua')
BIN_ROOT=lit/luvi-binaries/$(shell uname -s)_$(shell uname -m)
LIT_VERSION=3.5.4

LUVER_TAG=$(shell git describe)
LUVER_ARCH=$(shell uname -s)_$(shell uname -m)

PREFIX?=/usr/local
PHONY?=test lint size trim lit

test: lit luver
	./luver tests/run.lua

clean:
	git clean -dx -f


lit:
	curl -L https://github.com/luvit/lit/raw/$(LIT_VERSION)/get-lit.sh | sh

luver: lit $(APP_FILES)
	./lit make

install: luver lit
	mkdir -p $(PREFIX)/bin
	install luver $(PREFIX)/bin/
	install lit $(PREFIX)/bin/
	install luvi $(PREFIX)/bin/

uninstall:
	rm -f $(PREFIX)/bin/luver
	rm -f $(PREFIX)/bin/lit

lint:
	find deps -name "*.lua" | xargs luacheck

size:
	find deps -type f -name '*.lua' | xargs  -I{} sh -c "luajit -bs {} - | echo \`wc -c\` {}" | sort -n

trim:
	find . -type f -name '*.lua' -print0 | xargs -0 perl -pi -e 's/ +$$//'
