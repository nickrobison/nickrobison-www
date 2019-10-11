BUILD = dune build @install

build: main.ml
	$(BUILD) {main.bc.js,index.html}

install: build
	mkdir -p ../files/js/stats
	cp ../_build/default/stats/main.bc.js ../files/js/stats/main.bc.js
	cp ../_build/default/stats/index.html ../files/stats.html
