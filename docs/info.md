# CORDIC Trigonometric Engine

## Project Overview

This repository contains the register-transfer level (RTL) implementation of a 16-iteration CORDIC (Coordinate Rotation Digital Computer) Trigonometric Engine. Designed for the VIT OPEN SILICON Microelectronic Bootcamp, this synthesisable Verilog core evaluates the sine and cosine of an input angle using highly optimized, multiplier-free arithmetic.

The primary engineering challenge of this project was to design a fully functioning hardware accelerator that strictly adheres to a physical footprint limit of under 1,000 Gate Equivalents (GE) for submission to the SkyWater 130nm open-source PDK via the Tiny Tapeout framework.

### Submitted by: ATHARVA VERMA

## 1. Mathematical Algorithm: CORDIC

The CORDIC algorithm is an iterative mathematical technique utilized to calculate complex trigonometric functions using only basic binary operations: addition, subtraction, bit-shifting, and static table lookups. By eliminating the need for physically large hardware multipliers, the algorithm is exceptionally well-suited for area-constrained ASIC design.

### The Rotation Mode
To compute the sine and cosine of an input angle, the engine operates in "Rotation Mode." A vector, initially resting on the X-axis, is iteratively rotated by successively smaller, predetermined angles. 

For each iteration $i$ (ranging from $0$ to $15$), the vector coordinates are updated using the following equations:

* $X_{i+1} = X_i - d_i \cdot (Y_i \gg i)$
* $Y_{i+1} = Y_i + d_i \cdot (X_i \gg i)$
* $Z_{i+1} = Z_i - d_i \cdot \arctan(2^{-i})$

**Variable Definitions:**
* $X$ and $Y$ represent the current coordinates of the rotating vector.
* $Z$ represents the residual angle remaining to be rotated.
* $d_i$ dictates the direction of rotation. If the residual angle $Z_i \ge 0$, then $d_i = +1$. If $Z_i < 0$, then $d_i = -1$.
* The $\gg$ operator represents a bitwise arithmetic right shift, physically implementing the division by $2^i$.

### Intrinsic Gain and Pre-scaling
A fundamental property of the CORDIC rotation equations is that they artificially increase the magnitude of the vector at each step. After 16 iterations, the magnitude grows by a cumulative factor $K \approx 1.64676$.

To obtain mathematically accurate sine and cosine values, the output must be scaled by $1/K \approx 0.60725$. To avoid instantiating a multiplier at the output stage, this engine utilizes a pre-scaling optimization on the initial vector:
* Initial $Y_0 = 0$
* Initial $Z_0 = \text{Target Angle } \theta$
* Initial $X_0 = 0.60725$ 

In the 16-bit Q1.15 fixed-point format used by this datapath, $0.60725$ is represented by the hexadecimal value `16'h4DBA`. By seeding the $X$ accumulator with this pre-scaled value, the intrinsic algorithmic gain naturally scales the final vector back to a unit circle magnitude, yielding precise sine and cosine outputs natively.

## 2. Design Architecture

To satisfy the sub-1,000 GE physical gate limitation, high-throughput unrolled pipelining was discarded. Instead, this engine employs a highly optimized **Folded Datapath Architecture**.

### Architectural Strategies
1.  **Iterative Re-use (Folding):** A single unified combinational core consisting of adders, subtractors, and variable barrel shifters is instantiated in silicon. A central Finite State Machine (FSM) commands the datapath to cycle its outputs back into its own inputs exactly 16 times per computation.
2.  **Synthesisable LUT:** The pre-computed arctangent constants for $\arctan(2^{-i})$ are hardcoded using a basic synthesisable `case` statement. This guides the physical synthesizer to map the constants to standard logic cells, avoiding the massive area penalty of deploying SRAM macros.
3.  **Multiplexed I/O:** The internal calculations utilize a 16-bit wide datapath to minimize the accumulation of truncation errors. Because the Tiny Tapeout physical padframe provides limited bidirectional I/O pins, the 16-bit inputs are loaded sequentially over two clock cycles, and the final 8-bit outputs are multiplexed.

### Architecture Diagram

<img width="1007" height="554" alt="image" src="https://github.com/user-attachments/assets/7618f9c9-34d1-4861-a2a8-1cacf0dbfb5d" />




## 3. Verilog Module Breakdown

The project follows a strict modular hierarchy, isolating hardware interface constraints from the mathematical control flow.

### `tt_um_cordic_engine.v` (Physical Wrapper)
This top-level module acts as the boundary between the internal logic and the physical silicon padframe. It safely routes the dedicated 8-bit input (`ui_in`) and bidirectional (`uio_in`) pins. It explicitly sinks unused inputs to ground to prevent Verilator linting errors and physical Design Rule Check (DRC) violations. It also houses the asynchronous output multiplexer, allowing the external `out_sel` pin to toggle the output bus between the computed Sine and Cosine values.

### `cordic_engine.v` (Main Integration Controller)
This module connects the datapath to the control unit. It includes a dedicated 2-state input machine to buffer the Most Significant Byte (MSB) of the target angle on the first clock cycle and concatenate it with the Least Significant Byte (LSB) on the second. It maintains the synchronous registers for the $X$, $Y$, and $Z$ vectors and contains the combinational Look-Up Table (LUT) for the arctangent constants.

### `cordic_fsm.v` (Control Unit)
A strictly initialized Moore-style Finite State Machine responsible for timing the folded datapath. It transitions through `IDLE`, `COMPUTE`, and `DONE` states. To prevent the propagation of unknown `'X'` states during physical gate-level simulation (GLS), every register within this FSM is explicitly tied to a hard `0` during a negative-edge reset block. It drives the 16-cycle iteration counter and generates the enable signals that allow the datapath registers to latch new values.

### `cordic_core_stage.v` (Combinational Datapath)
This module executes the mathematical transformations for a single CORDIC iteration. It inspects the sign bit (MSB) of the incoming $Z$ vector to determine the rotational direction. It applies the dynamic arithmetic right shifts to $X$ and $Y$ based on the current iteration index provided by the FSM, and executes the final addition or subtraction to generate the next state vectors.

### Validation Environment (`tb.py` & `tb.v`)
The testbench utilizes Python (`cocotb`) against a passive Verilog shell. The environment is heavily hardened for Gate-Level Simulation (GLS) using Verilator:
* **Power Pins:** The Verilog shell exposes conditional `VPWR` and `VGND` macros required to power the physical standard cell models.
* **Deterministic Timing:** The Python script avoids infinite polling loops on bidirectional pads, which commonly cause simulator lock-ups. Instead, it utilizes deterministic clock-cycle waits and samples valid pins exclusively on the falling edge of the clock, guaranteeing physical silicon signals have completely stabilized before assertions are verified.
