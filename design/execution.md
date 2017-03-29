# Execution
###### Status: Initial draft

> The virtual machine doesn't have a name yet, but to keep it short,
we refer to it as `the machine`.

## Default variables

Below are some variables you are able to pass to the machine in different contexts.
For example, if you instantiate the machine programmatically, you will be able to pass
them via a constructor call of some sorts. When launching via a CLI, `ARGV` is used.

| Name              | Type    | Description                                      | Default     |
|-------------------|---------|--------------------------------------------------|-------------|
| `MEMORY_SIZE`     | `Int64` | Amount of bytes the machine should allocate      | `1_000_000` |
| `MAX_MEMORY_SIZE` | `Int64` | Maximum amount of bytes the machine can allocate | `∞`         |

## Startup

On startup, the machine instantiates `$MEMORY_SIZE` amount of bytes. The complete memory is
zero-initialized. It then copies the contents of the executable file to the memory address `0x00`.
If the program doesn't fit into memory, the machine will exit with the `OUT_OF_MEMORY` error code.

## Memory alignment

Since the bytecodes are mostly position-dependent, they always start at offset `0x0` and grow towards
higher addresses. The stack starts immediately after the bytecodes (e.g If you have 25 bytes of instructions,
the stack starts at address `0x19`).

```
+------------------------+ <- 0x0
| Instructions           |
+------------------------+ <- Instruction-bytes
| Stack-memory           |
+------------------------+
| Heap-memory (unmanaged)|
+------------------------+ <- Max. memory size
```

## Register initialisation

All registers, except `sp` and `fp` will be zero-initialized.

## Execution loop

The `ip` register always points to the current instruction. If the instruction modified the instruction
pointer, it won't be incremented. If the instruction pointer wasn't accessed during the execution,
it will be set to the address of the next instruction.
