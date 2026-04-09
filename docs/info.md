# 4-PLC Configurable Logic Fabric

## What is this?

This project implements a tiny configurable logic fabric made up of 4 programmable logic cells (PLCs), designed for Tiny Tapeout.

Each PLC is a small 2-input lookup table (LUT) that can implement **any Boolean function of two inputs**. By connecting multiple PLCs together, more complex logic functions can be created.

The design is intentionally simple and optimized for **very low area (~70–100 standard cells)**.

---

## Key Features

- 4 configurable logic blocks (PLCs)
- Each PLC is a 2-input LUT (4-bit truth table)
- Supports chaining to build more complex logic
- No internal memory → configuration is direct and simple
- Extremely compact and efficient
- Fully combinational (no clock-dependent logic)

---

## Architecture

The 4 PLCs are connected in a small chain:
PLC0 → p0 (uses ui_in[1:0])
PLC1 → p1 (uses ui_in[3:2])
PLC2 → p2 (uses p0 and p1)
PLC3 → p3 (uses p1 and p2)


### How to interpret this:

- **PLC0 and PLC1** compute basic logic from inputs  
- **PLC2 and PLC3** combine earlier results to build more complex functions  

This structure allows both:
- Parallel logic (PLC0, PLC1)
- Chained logic (PLC2, PLC3)

---

## How it works

Each PLC uses a 4-bit LUT to define its behavior:

| Inputs (b,a) | Output |
|-------------|--------|
| 00 | LUT[0] |
| 01 | LUT[1] |
| 10 | LUT[2] |
| 11 | LUT[3] |

By changing the LUT values, you can implement different logic functions.

---

## Example Configurations

| Function | LUT Value |
|----------|----------|
| AND | `1000` |
| OR  | `1110` |
| XOR | `0110` |

---

## Inputs

### `ui_in` (Logic Inputs)

| Bits | Description |
|------|------------|
| [1:0] | Inputs to PLC0 |
| [3:2] | Inputs to PLC1 |

---

### `uio_in` (Configuration)

| Bits | Description |
|------|------------|
| [3:0] | LUT for PLC0 and PLC2 |
| [7:4] | LUT for PLC1 and PLC3 |

---

## Outputs

| Bits | Description |
|------|------------|
| uo[0] | Output of PLC0 |
| uo[1] | Output of PLC1 |
| uo[2] | Output of PLC2 |
| uo[3] | Output of PLC3 |

---

## Why this project?

This project demonstrates how **FPGA-style configurable logic** can be implemented in an extremely small ASIC design.

It highlights:
- LUT-based logic design  
- Hardware reuse through chaining  
- Efficient design under strict area constraints  

All within a minimal and easy-to-understand architecture.