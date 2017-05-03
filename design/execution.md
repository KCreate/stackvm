# Execution
###### Status: Initial draft

> The virtual machine doesn't have a name yet, but to keep it short,
we refer to it as `the machine`.

## Memory layout

The machine has 8 megabytes (8'000'000 bytes) of memory. This results in an address space
starting at `0x00000000` up to `0x007a1200`. All addresses above that limit will cause a
crash when accessed.

```
+--------------------------------+ 0x00000000 : 3,572,754 bytes
| Unreserved space               |
| |                              |
| |                              |
| v                              |
|                                |
|                                |
|                                |
| ^                              |
| |                              |
| |                              |
| Stack memory (grows downwards) |
+--------------------------------+ 0x00400000 : 3'767'274 bytes
| Reserved for machine internals |
+--------------------------------+ 0x00797bea : 4 bytes
| Interrupt handler address      |
+--------------------------------+ 0x00797bee : 16 bytes
| Interrupt memory               |
+--------------------------------+ 0x00797bfe : 1 byte
| Interrupt code                 |
+--------------------------------+ 0x00797bff : 1 byte
| Interrupt status               |
+--------------------------------+ 0x00797c00 : 38,400 bytes
| VRAM (240x160)                 |
+--------------------------------+ 0x007a1200
```

## Register initialisation

- `r0` to `r59` are zero-initialized
- `ip` gets set to the value of the `entry_addr` column in the program header.
- `sp` is initialized to `0x00400000`
- `fp` is intiialized to `0x007a1200`
- `flags` is zero-intialized

## Stack memory

The stack starts at `0x003fffff` and grows towards lower addresses.

## Execution loop

The `ip` register always points to the current instruction. If the instruction modified the instruction
pointer, it won't be incremented. If the instruction pointer wasn't changed, it will be set to the
address of the next instruction.

## Standard calling convention

The machine provides the `call` and `ret` instructions, which implement the standard calling
convention used in the machine. If you're not happy with my implementation, you can roll
your own and access the `ip`, `sp` and `fp` registers manually.

Below is an example of how you would call another function.

The program below calculates the sum of `25` and `45` and saves the result in the `r0` register.

```assembly
; registers we'll use for calculations
.def calc1 r1
.def calc2 r2

.def return_value r0

.org 0x00
.label entry_addr
.label main
    push dword, 0               ; reserve 4 bytes for return value
    push dword, 25              ; push argument 1
    push dword, 45              ; push argument 2
    push dword, qword           ; push bytesize of arguments
    call _add                   ; call the _add label
    rpop return_value           ; pop the result into the return_value register

.label _add
    load calc1, 12              ; load the first argument into calc1
    load calc2, 8               ; load the second argument into calc2
    add calc1, calc2            ; add calc2 to calc1
    store calc1, 16             ; write to return value
    ret                         ; return from the subroutine
```

Below is a diagram of how the stack is organized when entering the `add` block.

```
+- High addresses
|
+-----------------------------+
| Return value : 4 Bytes      | <- Return value
+-----------------------------+
| Argument 1 : 4 Bytes        | <-- Function arguments
| Argument 2 : 4 Bytes        | <-/
| Argument count : 4 Bytes    | <- How many bytes are arguments?
+-----------------------------+
| Return address : 4 Bytes    |
| Old Frame pointer : 4 Bytes | <- Stack frame
+-----------------------------+
|
+- Low addresses
```

The `call` instruction simply pushes the current frame pointer and the address of the next
instruction. It then updates the `fp` register to point to the address of the previously pushed
old frame pointer and jumps to the specified address.

The `ret` instruction restores the `fp` register to the value that's inside the current
stack frame, pops off as many bytes as the argument count specifies and jumps to the return
address.
