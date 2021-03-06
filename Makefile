.PHONY: depends tools clean build deploy

build:
	scripts/build.sh

deploy:
	scripts/deploy.sh

depends:
	opam install -y .

parser.byte:
	corebuild tools/parser.byte

tools: parser.byte

clean:
	@rm -rf _build tools/_build
	mirage clean -f src/config.ml
