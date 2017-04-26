FILE = "examples/debug.asm"
MONITOR = "machine.memory"

default: stackvm

debug: stackvm
	bin/stackvm build $(FILE) -o debug.bc -s
	bin/stackvm run debug.bc --debugger

monitor: stackvm
	bin/stackvm monitor $(MONITOR) -s 3

stackvm_release:
	mkdir -p bin
	crystal build src/stackvm.cr -o bin/stackvm --error-trace --no-debug --release

stackvm:
	mkdir -p bin
	crystal build src/stackvm.cr -o bin/stackvm --error-trace

clean:
	find . -name ".DS_Store" | xargs rm
	find . -name "*.swp" | xargs rm
	find . -name "*.swo" | xargs rm
	rm -rf bin
