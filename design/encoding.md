# Binary encoding
###### Status: Initial draft

> The virtual machine doesn't have a name yet, but to keep it short,
we refer to it as `the machine`.

This document contains the specification of the binary encoding of instructions,
immediate values, constants, registers, jump addresses, block ordering and
global constants.

## Content ordering

This section describes the way a valid executable file has to be structured.

```
+--------------+
| Bytecodes    |
+--------------+
| Constants    |
+--------------+
```

Each file begins with the bytecodes of the program. The constants section directly follows the bytecode section.
There is no border or marker between these two sections, they just directly follow each other.

At startup, the whole file is loaded into memory at address `0x0`. Execution will begin at address `0x0`.
If the program allows execution flow to the constant section, this may cause undefined behaviour.

It is the sole role of the compiler to generate code that behaves correctly. The machine doesn't do any section-checking
at all.

## Registers

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

## Instructions

Instructions are represented as 16-bit values.

The first three bits make up the header. It contains information about the signedness of the instruction
and on what type it should operate on. The definitions of the header bit can change for each instruction.

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

## Size specifiers

Size specifiers are represented as 32-bit values and are used to denote a given amount of bytes
in an argument.
