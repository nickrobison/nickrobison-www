PKGS := mirage core jbuild depext

.PHONY: depends tools clean

depends:
	opam install -y $(PKGS)


parser.byte:
	corebuild tools/parser.byte 

tools: parser.byte

clean:
	@rm -rf _build tools/_build
	mirage clean -f src/config.ml
