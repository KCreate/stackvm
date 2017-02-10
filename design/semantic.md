# Design
###### Status: Initial draft

> The virtual machine doesn't have a name yet, but to keep it short,
we refer to it as `the machine`.

This document contains the specification for registers, error codes, available instructions,
the instruction format and supported types of the machine.

The machine follows the model of a stack-machine, but still supports the use of registers
and linear random-access-memory.

## Registers

| Name           | Opcode           | Description          |
|----------------|------------------|----------------------|
| `r0` .. `r15`  | `0x00` .. `0x0F` | General purpose      |
| `ip`           | `0x10`           | Instruction pointer  |
| `sp`           | `0x11`           | Stack pointer        |
| `fp`           | `0x12`           | Frame pointer        |
| `ax`           | `0x13`           | Return register      |
| `gbg`          | `0x14`           | Garbage register     |
| `cx0` .. `cx2` | `0x15` .. `0x16` | Counter registers    |

Each register can hold a 64-bit value.

You can target the lower or upper half of a register by putting a `l` or `u` char in front of it's name.
They respectively stand for lower and upper.

Below is an example with the `r0` register.
```
r0 - 64-bits - Complete register
|
+------------------------------------------------------------------

00000000000000000000000000000000   00000000000000000000000000000000

+-------------------------------   +-------------------------------
|                                  |
lr0 - 32-bits - Lower half         ur0 - 32-bits - Upper half

```

When reading from these registers, they return a 32-bit integer.
If you write a value bigger than 32-bits to one of the sub-registers, the value will be truncated
to fit (higher-order bits will be truncated).

The `ip` register contains a pointer, pointing into heap memory, to the instruction that's next to be executed.
Both the stack and frame-pointers point into stack memory.

Each register is represented as a 8-bit value.

## Memory

| Name  | Purpose                                   | Permissions          |
|-------|-------------------------------------------|----------------------|
| Stack | Calculations, Call stack                  | Read, Write          |
| Heap  | Random-access-memory, instruction storage | Read, Write, Execute |

These are two separate fixed-size regions of memory, not able to overlap.
Both regions are addressable with 8-bit precision.

For example, to read two 32-bit integers, you'd begin at memory offsets `0x00` and `0x04`.
Similarly, to read two 64-bit integers, you'd use `0x00` and `0x08`.

## Value types

Calculations inside the machine support the following types:

- `32-bit Integer`
- `64-bit Integer`
- `32-bit Floating-point`
- `64-bit Floating-point`

Neither of these values are inherently signed or unsigned, the operations on them however are.

## Size types

Size types differ from regular types in the sense that they only limit the amount of bytes used for a value type.

Available size types are:

- `BYTE` - `8-bits`
- `WORD` - `16-bits`
- `DWORD` - `32-bits`
- `QWORD` - `64-bits`

You can use these types in places where an instruction expects a type (e.g `TR`, `SE` or `ZE`).

Each size type takes up 8 bits.

If you need to specify a type which exceeds 4 bytes, a single 8-bit numeric value can be provided.
Given the number `8` the amount of bytes is derived via `2 ** (8 - 1)`, thus yielding 16 bytes.

## Instructions

Each instruction consists of 16-bits.

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

You can set these header bits by adding the corresponding suffixes to the instruction name.
The suffixes are separated via a dot (`.`) character from each other and from the instruction.
They are order-insensitive and can also be duplicated (e.g `push.i32.i32` is equal to `push.i32`)

| Suffix | Description                                    |
|--------|------------------------------------------------|
| `i`    | Sets the `S` bit to `0`                        |
| `u`    | Sets the `S` bit to `1`                        |
| `i32`  | Sets the `T` bit to `0` and the `B` bit to `0` |
| `i64`  | Sets the `T` bit to `0` and the `B` bit to `1` |
| `f32`  | Sets the `T` bit to `1` and the `B` bit to `0` |
| `f64`  | Sets the `T` bit to `1` and the `B` bit to `1` |

When encoding immediate values, these headers bits have no meaning and are simply ignored.

## Instruction descriptions

Each instruction in the machine is documented below.
The `Arguments` section, if present, follows the following naming convention:

- `value` Value of the same size as the instruction.
- `reg` The name of a register prefixed with a `%` character. (8-bits)
- `type` Size specifier (e.g `BYTE` or `WORD`). (8-bits)
- `label` A block label (e.g `@main` or `@loop`) (64-bits)

If a register or argument name is displayed with brackets around it (e.g `[source]` or `[r0]`)
the value inside the register is meant.

## Reading from and writing to registers

| Name     | Arguments      | Description                                                                       |
|----------|----------------|-----------------------------------------------------------------------------------|
| `PUSHR`  | reg            | Load the value of a register onto the stack                                       |
| `LOADR`  | reg, value     | Load a given value into a register                                                |
| `POPR`   | reg            | Pop the top of the stack into a register                                          |
| `INCR`   | reg            | Increment the value inside a register by 1                                        |
| `DECR`   | reg            | Decrement the value inside a register by 1                                        |
| `LOADR`  | reg            | Load the value at the stack-address at `fp + [reg]`                               |
| `STORER` | reg, source    | Load the value inside the source register, onto the stack-address at `fp + [reg]` |
| `MOV`    | target, source | Copies the contents of the source register into the target register               |

## Arithmetic instructions

| Name   | Description                                                 |
|--------|-------------------------------------------------------------|
| `ADD`  | Push the sum of the top two values                          |
| `SUB`  | Push the difference of the top two values (`lower - upper`) |
| `MUL`  | Push the product of the top two values                      |
| `DIV`  | Push the quotient of the top two values (`lower / upper`)   |
| `REM`  | Push the remainder of the top two values (`lower % upper`)  |
| `EXP`  | Push the power of the top two values (`lower ** upper`)     |

## Comparison instructions

| Name  | Description                                                         |
|-------|---------------------------------------------------------------------|
| `CMP` | Push 0 if the top two values are equal                              |
| `LT`  | Push 0 if the second-highest value is less than the top             |
| `GT`  | Push 0 if the second-highest value is greater than the top          |
| `LTE` | Push 0 if the second-highest value is less or equal than the top    |
| `GTE` | Push 0 if the second-highest value is greater or equal than the top |

## Bitwise instructions

| Name   | Description                                                             |
|--------|-------------------------------------------------------------------------|
| `SHR`  | Shift the bits of the top value to the right n times (`lower >> upper`) |
| `SHL`  | Shift the bits of the top value to the left n times (`lower >> upper`)  |
| `AND`  | Push bitwise AND of the top two values (`lower & upper`)                |
| `XOR`  | Push bitwise OR of the top two values (`lower ^ upper`)                 |
| `NAND` | Push bitwise NAND of the top two values (`~(lower & upper)`)            |
| `OR`   | Push bitwise OR of the top two values (`lower OR upper`)                |
| `NOT`  | Push bitwise NOT of the top value                                       |

## Casting instructions

All instructions below use the `B` field of the instruction-header as the starting-type.

| Name | Arguments | Description                               |
|------|-----------|-------------------------------------------|
| `TR` | type      | Truncate a value to the size of `type`    |
| `SE` | type      | Sign-extend a value to the size of `type` |
| `ZE` | type      | Zero-extend a value to the size of `type` |

In the case that the `S` bit in the `SE` instruction is set to `1`,
the value will be truncated while keeping the original sign.

## Stack manipulation instructions

| Name     | Arguments    | Description                                           |
|----------|--------------|-------------------------------------------------------|
| `LOAD`   | type, offset | Load a given amount of bytes located at `fp + offset` |
| `LOADR`  | type, reg    | Load a given amount of bytes located at `fp + [reg]`  |
| `STORE`  | type, offset | Pop a given amount of bytes and save at `fp + offset` |
| `STORER` | type, reg    | Pop a given amount of bytes and save at `fp + [reg]`  |
| `POP`    | type         | Pop a given amount of bytes into the `gbg` register   |

> Note: When using `POP` with more than the max size of the `gbg` register,
the value will be truncated.

## Heap manipulation instructions

These instructions and addresses operate on heap memory.

| Name     | Arguments            | Description                                                              |
|----------|----------------------|--------------------------------------------------------------------------|
| `READ`   | type, address        | Read a *type* value from *address* and pushes it onto the stack          |
| `READR`  | type, reg            | Read a *type* value from `[reg]` and pushes it onto the stack            |
| `WRITE`  | type, address        | Reads a *type* value from the stack and writes it to the given *address* |
| `WRITER` | type, reg            | Reads a *type* value from the stack and writes it to `[reg]`             |
| `COPY`   | type, target, source | Reads a *type* value at *source* and writes it to the given *target*     |
| `COPYR`  | type, target, source | Reads a *type* value from `[source]` and writes it to `[target]`         |

> Note: `WRITE` and `WRITER` don't remove anything from the stack.

Out-of-bounds reads or writes may cause unexpected behaviour.

## Jump instructions

| Name     | Arguments | Description                                                                   |
|----------|-----------|-------------------------------------------------------------------------------|
| `JMP`    | label     | Unconditionally jumps to the given label                                      |
| `JMPR`   | reg       | Unconditionally jumps to the address in `[reg]`                               |
| `JZ`     | label     | Jumps to the given label if the top of the stack is zero                      |
| `JZR`    | reg       | Jumps to the address in `[reg]` if the top of the stack is zero               |
| `JNZ`    | label     | Jumps to the given label if the top of the stack is not zero                  |
| `JNZR`   | reg       | Jumps to the address in `[reg]` if the top of the stack is not zero           |
| `CALL`   | label     | Calls the given label, pushing a new stack frame                              |
| `CALLR`  | reg       | Calls the address in `[reg]`, pushing a new stack frame                       |
| `RET`    |           | Returns from the current stack frame and passes control back to the last one. |

## Miscellaneous instructions

The instructions below provide some useful functions.

| Name       | Description                                                                         |
|------------|-------------------------------------------------------------------------------------|
| `NOP`      | Does nothing                                                                        |
| `HALT`     | Halts the machine                                                                   |

## License

The MIT License (MIT)

Copyright (c) 2017 Leonard Schuetz

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
