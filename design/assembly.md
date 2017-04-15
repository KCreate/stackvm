# Design
###### Status: Initial draft

> The virtual machine doesn't have a name yet, but to keep it short,
we refer to it as `the machine`.

This document describes the syntactic aspects of the assembly-like language
the built-in assembler understands. For a semantic description,
see the file [semantic.md](./semantic.md)

For the specification on binary encoding, check the [encoding.md](./encoding.md) file.

## Assembler directives

Assembler directives are prefixed with a `.` char. They tell the assembler to
register a new constant, operate on the program header, etc.

Available assembler directives

- `def`
- `db`
- `org`
- `include`
- `label`

| Name      | Arguments          | Description                               |
|-----------|--------------------|-------------------------------------------|
| `def`     | label, value       | Defines a new assembler constant          |
| `db`      | label, size, value | Defines a new assembler constant          |
| `org`     | address            | Add a new entry to the load table         |
| `include` | filename           | Include the contents of `filename`        |
| `label`   | label              | Add a new entry to the label offset table |

### `def`

```assembly
.def counter r0
loadi counter, 25
```

The `def` directive registers a new alias. Aliases get resolved during assembly
and have no performance penalty. Aliases can be defined anywhere in the program.

You can't register aliases that have the same name as another directive, instruction
or register.

### `db`

```assembly
.db myconstant qword 2500

.org 0x600
.db buffer 255 0      ; loads a 255 byte buffer at address 0x600

readcs 255, buffer    ; pushes 255 bytes from the buffer onto the stack
```

The `db` directive registers a new constant which gets encoded directly into the
instruction stream. Constants are identified by a label, a size specifier and a value.

### `org`

```assembly
.org 0x0
mov r0, r1                ; gets loaded at address 0x0

.org 0x500
.db myconstant 255 0      ; reserves 255 bytes at address 0x500

.org 0x20
mov r0, r1                ; gets loaded at address 0x20
```

The `org` directive adds a new entry to the headers load table.

### `include`

```assembly
; main.asm

.include "constants.asm"

push dword, VRAM_ADDR     ; pushes dword 0x500 onto the stack
```

```assembly
; constants.asm

.def VRAM_ADDR 0x500 ; not the real address of VRAM..
```

Includes the contents of a given file into this file. This process just dumps
the contents of the requested file into the main file.

### `label`

```assembly
.label main     ; main is now a label to offset 0x0

.org 0x500
.label foo      ; foo is now a label to offset 0x500

.org 0x300
.label test     ; test is now a label to offset 0x300

.org 0x200
nop
nop
nop
nop
.label bar      ; bar is now a label to offset 0x204
```

The `label` directive adds a new entry to the assemblers label offset table.
The label offset table maintains the mapping between an identifier and it's offset
in the executables instruction stream. It is aware of relocations done by the `org`
directive.

## Labels

```assembly
; legal labels
.label foo
.label _bar
.label $bar
.label %baz
.label bar25
.label @"hello world"
.label @"MyClass#instance_method(foo : int, baz : short) : int"

; illegal labels
.label "foo"        ; this gets treated as a string literal
.label @bar         ; @ always needs to be followed by a string literal, then it's valid
.label 5baz         ; a label can't start with a number
```

A label starts with either `_`, `a-z`, `A-Z`, `$`, `%` and is then following by any
alphanumeric character, `$` or `%`.

An identifier that starts with a `@` character, needs to be followed by a string literal
which can then contain any character.

## Literals

```assembly
"hello world"           ; string literal
25                      ; decimal number
25.5                    ; floating-point number
0b0010                  ; binary number
0x0101                  ; hexadecimal number
```

Most literals don't have an assocated size, but are rather dependent upon a size specifier
that's also passed to an instruction or constant definition.

## Instructions

```assembly
mov r0, r1      ; copies r1 into r0
loadi r5b, 99   ; loads 99 into the lower byte of r5
```

Instructions consist of a mnemonic and are followed by zero or more arguments.
Each argument has to be separated by a comma. Instructions must always be terminated
with a newline. Instruction mnemonics are case-insensitive.

## Registers

```assembly
r0      ; targets r0 in dword mode
r0q     ; targets r0 in qword mode
r0d     ; targets r0 in dword mode (same as r0)
r0w     ; targets r0 in word mode
r0b     ; targets r0 in byte mode
```

Registers are denoted by their name, followed by an optional mode specifier.
Mode specifiers can be `q`, `d`, `w` or `b`.
