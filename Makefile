# Modified by Heiko Zimmermann for Hilde, 2026.
BIN := hilde
PKG := hilde-pkg
RUN := hilde-launcher
PKG_SRC := pkg/src/*.hih pkg/src/*.hiq standard/src/*.hih standard/src/*.hiq
RUN_SRC := run/src/*.hih run/src/*.hiq standard/src/*.hih standard/src/*.hiq
SRC := lib/*.ml lib/*.mli lib/*.mll lib/*.mly lib/dune bin/dune bin/hilde.ml lib/BuiltInModules.ml
PREFIX ?= /usr/local

.PHONY: all
all: $(BIN) $(PKG) $(RUN)

lib/BuiltInModules.ml: lib/builtin/*.hih lib/builtin/*.hiq lib/prelude.h lib/prelude.c lib/mldsa.c vendor/libcrux/libcrux_internal.h scripts/zig-version.txt concat_builtins.py
	python3 concat_builtins.py

$(BIN): $(SRC)
	dune build
	cp _build/default/bin/hilde.exe $(BIN)

# The package commands, a programme written in Hilde, built with the
# compiler of this tree; the compiler hands get, verify, new and the
# others to it.
$(PKG): $(BIN) $(PKG_SRC)
	./hilde compile pkg/src/Main.hih,pkg/src/Main.hiq --modules=pkg/src:standard/src:bindings/generated --entrypoint=Pkg.Main:main --output=$(PKG)

# hilde run, a programme written in Hilde, built with the compiler of this
# tree; the compiler hands the words after run to it.
$(RUN): $(BIN) $(RUN_SRC)
	./hilde compile run/src/Main.hih,run/src/Main.hiq --modules=run/src:standard/src:bindings/generated --entrypoint=Run.Main:main --output=$(RUN)

.PHONY: test
test: $(BIN)
	dune runtest

.PHONY: install
install: $(BIN) $(PKG) $(RUN)
	install -D -m 755 hilde $(PREFIX)/bin/hilde
	install -D -m 755 hilde-pkg $(PREFIX)/bin/hilde-pkg
	install -D -m 755 hilde-launcher $(PREFIX)/bin/hilde-launcher

.PHONY: uninstall
uninstall:
	sudo rm $(PREFIX)/bin/hilde

.PHONY: clean
clean:
	rm -f $(BIN) $(PKG) $(RUN); rm -rf _build; rm -f lib/BuiltInModules.ml
