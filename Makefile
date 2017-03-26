FILE = "spec/data/debug.bc"

run: build_release
	./bin/stackvm $(FILE)

debug: build_debug
	./bin/stackvm $(FILE)

build_release: prepare
	crystal build src/stackvm.cr --release -o bin/stackvm

build_debug: prepare
	crystal build src/stackvm.cr -o bin/stackvm

prepare:
	mkdir -p bin

test:
	crystal spec --error-trace

clean:
	find . -name "**/.DS_Store" | xargs rm
	find . -name "*.swp" | xargs rm
	find . -name "*.swo" | xargs rm
	rm -rf bin
