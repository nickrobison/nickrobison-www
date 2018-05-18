PKGS := mirage core depext jbuilder

.PHONY: depends tools clean build deploy

build:
	scripts/build.sh

deploy:
	scripts/deploy.sh

depends:
	opam install -y $(PKGS)
	opam pin add -y cowabloga https://github.com/nickrobison/cowabloga.git

parser.byte:
	corebuild tools/parser.byte

tools: parser.byte

clean:
	@rm -rf _build tools/_build
	mirage clean -f src/config.ml
