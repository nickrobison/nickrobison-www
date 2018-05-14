PKGS := mirage core jbuild

.PHONY: depends tools clean build deploy

build:
	@scripts/build.sh

install:

depends:
	opam install -y $(PKGS)

parser.byte:
	corebuild tools/parser.byte

tools: parser.byte

clean:
	@rm -rf _build tools/_build
	mirage clean -f src/config.ml
