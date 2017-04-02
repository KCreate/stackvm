# Execution
###### Status: Initial draft

> The virtual machine doesn't have a name yet, but to keep it short,
we refer to it as `the machine`.

## Default variables

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

## Standard calling convention

The machine provides the `call` and `ret` instructions, which implement the standard calling
convention used in the machine. If you're not happy with my implementation, you can roll
your own and access the `ip`, `sp` and `fp` registers manually.

Below is an example of how you would call another function.

The program below calculates the sum of `25` and `45` and saves the result in the `r0` register.

```assembly
main:
  loadi r0, qword, 25 ; load qword 25 into r0
  loadi r1, qword, 45 ; load qword 45 into r1

  add sp, sp, 8       ; reserve 8 bytes for the return value
  rpush r0            ; pushes r0 onto the stack
  rpush r1            ; pushes r1 onto the stack

  call add            ; calls add using standard calling convention
  rpop r0, qword      ; pop return value into r0

  halt
add:
  rpush r0            ; push r0 onto the stack
  rpush r1            ; push r1 onto the stack

  load r0, qword, -16 ; read qword at fp - 16 into r0
  load r1, qword, -8  ; read qword at fp - 8 into r1
  add r0, r0, r1      ; add r0 and r1 and save into r0
  store -24, r0       ; store r0 at fp - 24

  rpop r1, qword      ; restore r1 from the stack
  rpop r0, qword      ; restore r0 from the stack

  ret
```
