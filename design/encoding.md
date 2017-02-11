# Binary encoding
###### Status: Initial draft

> The virtual machine doesn't have a name yet, but to keep it short,
we refer to it as `the machine`.

This document contains the specification of the binary encoding of instructions,
immediate values, constants, registers, jump addresses, block ordering and
global constants.

## Content ordering

This section describes the way a file contains bytecodes, constants and method symbols.

```
+--------------+
| Symbol table |
+--------------+
| Bytecodes    |
+--------------+
| Constants    |
+--------------+
```

Each file starts with a symbol table containing the offsets to all methods and constants the file contains.
After that, the file's instructions follow. At the very end are the constants the file exports.

The following format is used to describe a single table entry. There is no limit as to how many
symbol table entries a file can contain. Single table entries don't require a separator between them.
After the table ends, a single null-byte (`0x00`) is expected. This mark tells the parser to stop
parsing the symbol table.

```
+-----------------------------------+
| Null-terminated symbol name       |
+-----------------------------------+
| Content length in bytes (64-bits) |
+-----------------------------------+
| Offset pointer (64-bits)          |
+-----------------------------------+
```

Index `0` of the offset-pointer points at the byte *after* the null-byte marking the end of the table
(e.g If the table takes up 30 bytes, the offset `0` would point at byte `31`).

### Symbol table

Example for a symbol table.

```
| Symbol name       | Content-length | Offset pointer |
|-------------------|----------------|----------------|
| `main`            | `90`           | `0x000`        |
| `add`             | `100`          | `0x05A`        |
| `sub`             | `100`          | `0x0BE`        |
| `stringconstant`  | `12`           | `0x122`        |
| `float32constant` | `4`            | `0x302`        |
```

### Registers

Registers are represented as 8-bit values.
The below table contains the values of each register.

```
   +- Register code
   |
   |
   vvvvvv
00 000000
^^
||
||
|+- First half / Right half
|
+- Complete / Sub-portion
```

The first bit tells wether the full register is targeted or only a sub-portion.
The second bit, only meaningful if the first bit is set to `1`, sets
wether the first or second half is targeted.
Bits 3 - 8 make up the register value.

| Name           | Value            |
|----------------|------------------|
| `r0` .. `r15`  | `0x00` .. `0x0F` |
| `ip`           | `0x10`           |
| `sp`           | `0x11`           |
| `fp`           | `0x12`           |
| `ax`           | `0x13`           |
| `gbg`          | `0x14`           |
| `cx0` .. `cx2` | `0x15` .. `0x17` |

### Instructions

Instructions are represented as 16-bit values.

The first three bits make up the header. It contains information about the signedness of the instruction
and on what type it should operate on.

Each part of the header has it's own name (`S`, `T`, `B`)

In the below diagram, `0` stands for the left value and `1` for the right value.

```
+- Header
|
|   +- Instruction opcode
|   |
vvv vvvvvvvvvvvvv
000 0000000000000
^^^
|||
||+- B - 32-bit / 64-bit
||
|+- T - Integer / Floating-point
|
+- S - Signed / Unsigned
```

### Size specifiers

Size specifiers are represented as 64-bit values and can be used to denote a
given amount of bytes in an argument.

### Labels / Addresses

Addresses are encoded as 64-bit values.
They are pointers into the machine's heap memory.
