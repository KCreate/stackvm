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
| `REGULAR_EXIT`          | `0x00` | The machine exited normally                                       |
| `STACKOVERFLOW`         | `0x01` | Operation would overflow the stack                                |
| `STACKUNDERFLOW`        | `0x02` | Operation would underflow the stack (e.g `POP` on an empty stack) |
| `ILLEGAL_MEMORY_ACCESS` | `0x03` | Memory read or write is out-of-bounds                             |
| `INVALID_INSTRUCTION`   | `0x04` | Unknown instruction                                               |
| `INVALID_REGISTER`      | `0x05` | Unknown register                                                  |
| `INVALID_JUMP`          | `0x06` | Trying to jump to an address that's out of bounds                 |
| `OUT_OF_MEMORY`         | `0x07` | Not enough memory to load a program                               |

## Registers

| Name           | Description         |
|----------------|---------------------|
| `r0` .. `r15`  | General purpose     |
| `ip`           | Instruction pointer |
| `sp`           | Stack pointer       |
| `fp`           | Frame pointer       |
| `cr`           | Carry register      |
| `ext`          | Exit code           |

- `ip` holds a pointer to the current instruction
- `sp` holds a pointer to the first byte above the stack
- `fp` holds a pointer to the base of the current stack-frame
- `cr` holds the result of a comparison, or the argument to the `SYSCALL` instruction
- `ext` holds the exit code of the machine.

Each register can hold a 64-bit value. Each register can also be access in `DWORD`, `WORD` and `BYTE` mode.
Do so by appending either `d`, `w` or `b` to the end of the register name. You can also choose which side
to access by adding `$` to the beginning of the register. Below is a visual representation
of how a register can be accessed:

```
 r0:   00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
 r0d:  00000000 00000000 00000000 00000000
 r0w:  00000000 00000000
 r0b:  00000000
$r0d:                                      00000000 00000000 00000000 00000000
$r0w:                                      00000000 00000000
$r0b:                                      00000000
```

If you try to write a value bigger than the capacity of a register(e.g `mov %r0b, %r0w`), the value is trimmed.

```assembly
; Before
;
; r0w: 00000011 11000000
; r0b: 00000000

mov %r0b, %r0w

; After
;
; r0b: 00000011
```

## Memory

The machine can be initialized with a variable amount of memory. The stack grows towards high
addresses.

## Size specifiers

Size specifiers can be used to describe a given amount of bytes.

A few constants are available for commonly used sizes.

- `BYTE` - `8-bits`
- `WORD` - `16-bits`
- `DWORD` - `32-bits`
- `QWORD` - `64-bits`

You can use these types in places where an instruction expects a type (e.g `TR`, `SE` or `ZE`).

## Instructions

Instructions are names assigned to a specific opcode. Opcodes range from `0` to `255`.
For more information, [see encoding.md](encoding.md).

## Instruction descriptions

Each instruction in the machine is documented below.
The `Arguments` section, if present, follows the following naming convention:

- `value` Immediate value.
- `reg` Register descriptor.
- `type` Size specifier (e.g `BYTE` or `WORD`).

If a register is surrounded with brackets it's to be interpreted as a pointer.

## Reading from and writing to registers

| Name     | Arguments         | Description                                                                    |
|----------|-------------------|--------------------------------------------------------------------------------|
| `RPUSH`  | reg               | Push `reg` onto the stack                                                      |
| `RPOP`   | reg, type         | Pop a `type` value from the stack into `reg`                                   |
| `MOV`    | target, source    | Copies `source` into `target`                                                  |
| `LOADI`  | reg, type, value  | Read a `type` value directly from the instruction stream and store it in `reg` |

## Integer arithmetic instructions

| Name   | Arguments       | Description                                            |
|--------|-----------------|--------------------------------------------------------|
| `IADD` | rst, reg1, reg2 | Add `reg2` to `reg1` and store in `rst`                |
| `ISUB` | rst, reg1, reg2 | Subtract `reg2` from `reg1` and store in `rst`         |
| `IMUL` | rst, reg1, reg2 | Multiply `reg1` by `reg2` and store in `rst`           |
| `IDIV` | rst, reg1, reg2 | Divide `reg1` by `reg2` and store in `rst`             |
| `IREM` | rst, reg1, reg2 | Put the remainder of (`reg1` % `reg2`) into `rst`      |
| `IEXP` | rst, reg1, reg2 | Raise `reg1` to the power of `reg2` and store in `rst` |

## Floating-point arithmetic instructions

Registers passed to these instructions can only be in full or `DWORD` mode.
If a full mode register is passed, the type is assumbed to be `float`, if the register
is in DWORD mode, `double` is assumed. When trying to store in a register that has
insufficient size, the machine will crash

| Name   | Arguments       | Description                                            |
|--------|-----------------|--------------------------------------------------------|
| `FADD` | rst, reg1, reg2 | Add `reg2` to `reg1` and store in `rst`                |
| `FSUB` | rst, reg1, reg2 | Subtract `reg2` from `reg1` and store in `rst`         |
| `FMUL` | rst, reg1, reg2 | Multiply `reg1` by `reg2` and store in `rst`           |
| `FDIV` | rst, reg1, reg2 | Divide `reg1` by `reg2` and store in `rst`             |
| `FREM` | rst, reg1, reg2 | Put the remainder of (`reg1` % `reg2`) into `rst`      |
| `FEXP` | rst, reg1, reg2 | Raise `reg1` to the power of `reg2` and store in `rst` |

## Comparison instructions

| Name  | Arguments | Description                                                               |
|-------|-----------|----------------------------------------------------------------------------|
| `CMP` | reg1, reg | Set `cr` to `0` if `reg1` is equal to `reg2`, otherwise `1`                |
| `LT`  | reg1, reg | Set `cr` to `0` if `reg1` is less than `reg2`, otherwise `1`               |
| `GT`  | reg1, reg | Set `cr` to `0` if `reg1` is greater than `reg2`, otherwise `1`            |
| `ULT` | reg1, reg | Set `cr` to `0` if `reg1` is less than `reg2` (unsigned), otherwise `1`    |
| `UGT` | reg1, reg | Set `cr` to `0` if `reg1` is greater than `reg2` (unsigned), otherwise `1` |

## Bitwise instructions

| Name  | Arguments       | Description                                        |
|-------|-----------------|----------------------------------------------------|
| `SHR` | rst, reg1, reg2 | Right-shift `reg1` `reg2` times and store in `rst` |
| `SHL` | rst, reg1, reg2 | Left-shift `reg1` `reg2` times and store in `rst`  |
| `AND` | rst, reg1, reg2 | Store bitwise AND of `reg1` and `reg2` into `rst`  |
| `XOR` | rst, reg1, reg2 | Store bitwise XOR of `reg1` and `reg2` into `rst`  |
| `NAND`| rst, reg1, reg2 | Store bitwise NAND of `reg1` and `reg2` into `rst` |
| `OR`  | rst, reg1, reg2 | Store bitwise OR of `reg1` and `reg2` into `rst`   |
| `NOT` | rst, reg1       | Store bitwise NOT of `reg1` into `rst`             |

## Stack instructions

| Name     | Arguments         | Description                                                       |
|----------|-------------------|-------------------------------------------------------------------|
| `LOAD`   | type, offset, reg | Read a `type` value from `fp + offset` and store it in `reg`      |
| `LOADR`  | type, offset, reg | Read a `type` value from `fp + [offset]` and store it in `reg`    |
| `PUSHS`  | type, offset      | Read a `type` value from `fp + offset` and push it onto the stack |
| `LOADS`  | type, reg         | Read a `type` value from `fp + [reg]` and push it onto the stack  |
| `STORE`  | offset, reg       | Store the contents of `reg` at `fp + offset`                      |

## Memory read / write

| Name      | Arguments            | Description                                                     |
|-----------|----------------------|-----------------------------------------------------------------|
| `READ`    | type, address, reg   | Read a `type` value from `[address]` and store it in `reg`      |
| `READC`   | type, address, reg   | Read a `type` value from `address` and store it in `reg`        |
| `READS`   | type, address, reg   | Read a `type` value from `[address]` and push it onto the stack |
| `READCS`  | type, address, reg   | Read a `type` value from `address` and push it onto the stack   |
| `WRITE`   | reg, address         | Write the contents of `reg` to `[address]`                      |
| `WRITEC`  | reg, address         | Write the contents of `reg` to `address`                        |
| `WRITES`  | type, address        | Pop a `type` value from the stack and write it to `[address]`   |
| `WRITECS` | type, address        | Pop a `type` value from the stack and write it to `address`     |
| `COPY`    | type, target, source | Copy a `type` value from `[source]` to `[target]`               |
| `COPYC`   | type, target, source | Copy a `type` value from `source` to `target`                   |

## Jump instructions

| Name    | Arguments   | Description                               |
|---------|-------------|-------------------------------------------|
| `JZ`    | reg, offset | Jump to `offset` if `reg` is `0`          |
| `JZR`   | reg, offset | Jump to `[offset]` if `reg` is `0`        |
| `JMP`   | offset      | Jump to `offset`                          |
| `JMPR`  | offset      | Jump to `[offset]`                        |
| `CALL`  | offset      | Push a stack frame and jump to `offset`   |
| `CALLR` | offset      | Push a stack frame and jump to `[offset]` |
| `RET`   | offset      | Return from the current stack frame       |

## Miscellaneous instructions

| Name      | Description  |
|-----------|--------------|
| `NOP`     | Does nothing |
| `SYSCALL` | VM syscall   |

## Syscalls

Syscalls are subroutines implemented directly inside the machine that provide some useful functionality,
such as doing IO or calling external functions. To make a syscall, push any arguments onto the stack,
store the syscall id in the `cr` register and run the syscall instruction.

The table below contains all available syscalls.

| Name       | Opcode | Arguments | Description                                                                      |
|------------|--------|-----------|----------------------------------------------------------------------------------|
| `malloc`   | `0x00` | type      | Returns a pointer to `type` bytes of memory. Sets `cr` to 1 on error             |
| `exit`     | `0x01` |           | Halt the machine                                                                 |
| `debugger` | `0x02` |           | Breakpoint for debuggers. Behaves like `NOP` in case nothing picks up the signal |
| `grow`     | `0x03` |           | Doubles the machines memory. Sets `cr` to 1 on error.                            |

Return values of syscalls are pushed onto the stack. Different syscalls may produce different return values.

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
