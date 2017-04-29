# Binary encoding
###### Status: Initial draft

> The virtual machine doesn't have a name yet, but to keep it short,
we refer to it as `the machine`.

This document contains the specification of the binary encoding of instructions,
immediate values, constants, registers, jump addresses, block ordering and
global constants.

## Content ordering

```
+----------+
| Header   |
+----------+
| Segments |
+----------+
```

## Header

| Name              | Offset | Size                   | Description                         |
|-------------------|--------|------------------------|-------------------------------------|
| magic             | `0x00` | `4`                    | ascii encoded string `NICE`         |
| entry_addr        | `0x04` | `4`                    | Initial value of the `ip` register  |
| load_table_size   | `0x08` | `4`                    | Number of entries in the load table |
| load_table        | `0x0c` | `load_table_size * 12` | Load table                          |

## Load table

The load table in the programs header section includes `1` or more entries.
Each entry is structured as follows:

| Name   | Offset | Size | Description                       |
|--------|--------|------|-----------------------------------|
| Offset | `0x0`  | `4`  | Start offset of section           |
| Size   | `0x4`  | `4`  | Size of section                   |
| Load   | `0x8`  | `4`  | Target offset in machine's memory |

Given the following load table:

| ID  | Offset       | Size         | Load         |
|-----|--------------|--------------|--------------|
| `0` | `0x00000000` | `0x000002aa` | `0x00337a00` |
| `1` | `0x000002aa` | `0x00337a00` | `0x00000000` |
| `2` | `0x00337caa` | `0x00000050` | `0x00000050` |
| `3` | `0x00337cfa` | `0x00000100` | `0x00700000` |

The executable would consist of four segments.

```
+-----------+ <- 0x00000000
| Segment 0 |
+-----------+ <- 0x000002aa
| Segment 1 |
+-----------+ <- 0x00337caa
| Segment 2 |
+-----------+ <- 0x00337cfa
| Segment 3 |
+-----------+ <- 0x00337dfa
```

This is how they would ultimately be laid out in memory:

```
+-------------+ <- 0x00000000
| Segment 1   |
|             |
+-------------+ <- 0x00000050
| Segment 2   | <----------------- Because the load address of Segment 2 is set to 0x00000050,
+-------------+ <- 0x000000a0      it overlaps Segment 1 which was loaded here before.
| Segment 1   |
|             |
|             |
|             |
|             |
|             |
|             |
+-------------+ <- 0x00337a00
| Segment 0   |
|             |
|             |
+-------------+ <- 0x00337caa
|             |
|             |
|             |
|             |
|             |
|             |
|     ...     |
| Empty space |
|     ...     |
|             |
|             |
|             |
|             |
|             |
|             |
+-------------+ <- 0x00700000
| Segment 3   |
+-------------+ <- 0x00700100
```

## Registers

Registers are represented as 8 bit values. The first two bits make up the mode, the rest
is the register code.

```
   +- Register code
   |
   v
00 000000
^
|
+- Mode
```

Register modes define which part of the register is being accessed.

```
00: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
01: 00000000 00000000 00000000 00000000
10: 00000000 00000000
11: 00000000
```

## Instructions

Instructions are represented as 8 bit values.

```
+- Opcode
|
v
00000000
```

## Size specifiers

Size specifiers are encoded as unsigned `dword` values and are used to denote
a given amount of bytes in an instruction argument.

## Addresses

Addresses are encoded as unsigned `dword` values.

## Offsets

Relative offsets are encoded as signed `dword` values.

