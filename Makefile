FILE = "examples/interrupts.asm"

debug: stackvm
	bin/stackvm build $(FILE) -o debug.bc
	bin/stackvm run debug.bc --memory=441 --debugger

run: stackvm
	bin/stackvm build $(FILE) -o debug.bc
	bin/stackvm run debug.bc --memory=441

stackvm_release:
	mkdir -p bin
	crystal build src/stackvm.cr -o bin/stackvm --error-trace --no-debug --release

stackvm:
	mkdir -p bin
	crystal build src/stackvm.cr -o bin/stackvm --error-trace

clean:
	find . -name "**/.DS_Store" | xargs rm
	find . -name "*.swp" | xargs rm
	find . -name "*.swo" | xargs rm
	rm -rf bin
