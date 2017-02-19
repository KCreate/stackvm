# Design
###### Status: Initial draft

> The virtual machine doesn't have a name yet, but to keep it short,
we refer to it as `the machine`.

This document contains the specification for available registers, error codes,
a list of instructions together with their arguments and descriptions.

For the specification on binary encoding, check the [encoding.md](./encoding.md) file.

The machine follows the model of a stack-machine, but still supports the use of registers
and linear random-access-memory.

## Error codes

| Name                    | Value  | Description                                                       |
|-------------------------|--------|-------------------------------------------------------------------|
| `STACKOVERFLOW`         | `0x00` | Operation would overflow the stack                                |
| `STACKUNDERFLOW`        | `0x01` | Operation would underflow the stack (e.g `POP` on an empty stack) |
| `ILLEGAL_MEMORY_ACCESS` | `0x02` | Memory read or write is out-of-bounds                             |
| `INVALID_INSTRUCTION`   | `0x03` | Unknown instruction                                               |
| `INVALID_REGISTER`      | `0x04` | Unknown register                                                  |
| `INVALID_JUMP`          | `0x05` | Trying to jump to an address that's out of bounds                 |

## Registers

| Name           | Description         |
|----------------|---------------------|
| `r0` .. `r15`  | General purpose     |
| `ip`           | Instruction pointer |
| `sp`           | Stack pointer       |
| `fp`           | Frame pointer       |

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

When reading from a sub-register, they return a 32-bit integer.
If you write a value bigger than 32-bits to one of the sub-registers, the value will be truncated
to fit (higher-order bits will be truncated).

The `ip` register contains a pointer, pointing to the instruction that's next to be executed.

The `sp` register contains a pointer, pointing to the address above the current top of the stack
(e.g If the stack starts at offset `0xA0` and contains 7 bytes, the `sp` register would contain `0xA7`).

The `fp` register contains a pointer, pointing to the base of the current stack-frame.

## Memory

The machine can be initialized with a variable amount of memory. Unlike most other systems, the stack grows towards high
addresses.

## Value types

Calculations inside the machine support the following types:

- `32-bit Integer`
- `64-bit Integer`
- `32-bit Floating-point`
- `64-bit Floating-point`

Neither of these values are inherently signed or unsigned, the operations on them however are.

## Size specifiers

Size specifiers can be used to describe a given amount of bytes.

A few constants are available for commonly used sizes.

- `BYTE` - `8-bits`
- `WORD` - `16-bits`
- `DWORD` - `32-bits`
- `QWORD` - `64-bits`

You can use these types in places where an instruction expects a type (e.g `TR`, `SE` or `ZE`).

## Instructions

Instructions are written using their name and zero or more modifiers to oeprate on the instruction header.

You can set these header bits by adding the corresponding suffixes to the instruction name.
The suffixes are separated via a dot (`.`) character from each other and from the instruction.
They are order-insensitive and can also be duplicated (e.g `push.i32.i32` is equal to `push.i32`)

| Suffix | Description                                    |
|--------|------------------------------------------------|
| `i`    | Sets the `S` bit to `0`                        |
| `u`    | Sets the `S` bit to `1`                        |
| `r`    | Sets the `T` bit to `1`                        |
| `a`    | Sets the `T` bit to `0`                        |
| `i32`  | Sets the `T` bit to `0` and the `B` bit to `0` |
| `i64`  | Sets the `T` bit to `0` and the `B` bit to `1` |
| `f32`  | Sets the `T` bit to `1` and the `B` bit to `0` |
| `f64`  | Sets the `T` bit to `1` and the `B` bit to `1` |

When encoding immediate values, these headers bits have no meaning and are simply ignored.

The `B` bit only has meaning for arithmetic or comparison instructions.
If an instruction takes its size via an argument, the `B` is irrelevant unless stated otherwise.

## Instruction descriptions

Each instruction in the machine is documented below.
The `Arguments` section, if present, follows the following naming convention:

- `value` Value of the same size as the instruction.
- `reg` The name of a register prefixed with a `%` character.
- `type` Size specifier (e.g `BYTE` or `WORD`).

If a register or argument name is displayed with brackets around it (e.g `[source]` or `[r0]`)
the value inside the register is meant.

## Reading from and writing to registers

| Name     | Arguments      | Description                                                         |
|----------|----------------|---------------------------------------------------------------------|
| `RPUSH`  | reg            | Push the value of a register onto the stack                         |
| `RPOP`   | reg            | Pop the top of the stack into a register                            |
| `RLOAD`  | value          | Push a value into a register                                        |
| `INCR`   | reg            | Increment the value inside a register by 1                          |
| `DECR`   | reg            | Decrement the value inside a register by 1                          |
| `MOV`    | target, source | Copies the contents of the source register into the target register |

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

All comparison instructions push a 32-bit integer onto the stack.

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

| Name    | Arguments  | Description                                 |
|---------|------------|---------------------------------------------|
| `TRUNC` | type, type | Truncate a value from `type1` to `type2`    |
| `SE`    | type, type | Sign-extend a value from `type1` to `type2` |
| `ZE`    | type, type | Zero-extend a value from `type1` to `type2` |

## Stack instructions

| Name     | Arguments    | Description                                  |
|----------|--------------|----------------------------------------------|
| `LOAD`   | type, offset | Load a *type* value located at `fp + offset` |
| `LOADR`  | type, reg    | Load a *type* value located at `fp + [reg]`  |
| `LOADI`  | type, value  | Load an immediate *type* value               |
| `STORE`  | type, offset | Pop a *type* value and save at `fp + offset` |
| `STORER` | type, reg    | Pop a *type* value and save at `fp + [reg]`  |
| `INC`    | type, offset | Increment a *type* value at `fp + offset`    |
| `DEC`    | type, offset | Decrement a *type* value at `fp + offset`    |

## Memory read / write

| Name     | Arguments            | Description                                                              |
|----------|----------------------|--------------------------------------------------------------------------|
| `READ`   | type, address        | Read a *type* value from *address* and push it onto the stack            |
| `READR`  | type, reg            | Read a *type* value from `[reg]` and push it onto the stack              |
| `WRITE`  | type, address        | Reads a *type* value from the stack and writes it to the given *address* |
| `WRITER` | type, reg            | Reads a *type* value from the stack and writes it to `[reg]`             |
| `COPY`   | type, target, source | Reads a *type* value at *source* and writes it to the given *target*     |
| `COPYR`  | type, target, source | Reads a *type* value from `[source]` and writes it to `[target]`         |

## Jump instructions

Jump instructions allow you to jump to other places in your program.
Jump instructions can either jump to an absolute offset (default),
or relative to the current instruction by a given amount of bytes.

You can toggle between absolute and relative mode by setting the `T` bit on the instruction.
Use the `r` and `a` suffixes on the instruction name to do so.

```
; jumping to a given address
jmp 10
jmp.a 10

; jumping 10 bytes forwards
jmp.r 10

; jumping 10 bytes backwards
jmp.r -10
```

| Name    | Arguments | Description                                                              |
|---------|-----------|--------------------------------------------------------------------------|
| `JZ`    | offset    | Relative or absolute jump to given offset if top of the stack is `0`     |
| `JZR`   | reg       | Relative or absolute jump to `[reg]` if top of the stack is `0`          |
| `JNZ`   | offset    | Relative or absolute jump to given offset if top of the stack is not `0` |
| `JNZR`  | reg       | Relative or absolute jump to `[reg]` if top of the stack is not `0`      |
| `JMP`   | offset    | Unconditional relative or absolute jump to given offset                  |
| `JMPR`  | reg       | Unconditional relative or absolute jump to `[reg]`                       |
| `CALL`  | offset    | Relative or absolute jump to given offset, pushing a stack-frame         |
| `CALLR` | reg       | Relative or absolute jump to `[reg]`, pushing a stack-frame              |
| `RET`   |           | Return from the current stack-frame                                      |

## Miscellaneous instructions

The instructions below provide some useful functions.

| Name   | Arguments | Description       |
|--------|-----------|-------------------|
| `NOP`  |           | Does nothing      |
| `PUTS` | type      |                   |
| `HALT` |           | Halts the machine |

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
