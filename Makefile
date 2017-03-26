FILE = "repl"
debug: build
	./bin/stackvm $(FILE)

build: prepare
	crystal build src/stackvm.cr --release -o bin/stackvm

prepare:
	mkdir -p bin

test:
	crystal spec --error-trace

clean:
	find . -name "**/.DS_Store" | xargs rm
	find . -name "*.swp" | xargs rm
	find . -name "*.swo" | xargs rm
	rm -rf bin
