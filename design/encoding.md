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

Registers are represented as 8 bit values. The first three bits make up the header, the rest
is the register code.

```
    +- Register code
    |
    v
000 00000
^
|
|
|
|
|
+- Register mode
```

Register modes work like this

```
000:  00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
001:  00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
010:  00000000 00000000 00000000 00000000
100:  00000000 00000000
110:  00000000
011:                                      00000000 00000000 00000000 00000000
101:                                      00000000 00000000
111:                                      00000000
```

## Instructions

Instructions are represented as 8 bit values.

```
+- Opcode
|
|
v
00000000
```

## Size specifiers

Size specifiers are represented as 32-bit values and are used to denote a given amount of bytes
in an argument.
