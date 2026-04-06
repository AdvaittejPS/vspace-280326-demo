## How it works

NeurAcc is a 4-element weight-stationary MAC (Multiply-Accumulate) accelerator designed for neural network inference. It implements a small systolic array of 4 MAC units, each holding a 4-bit weight and a 10-bit accumulator.

**Architecture**

- 4 × `mac_unit` instances chained in `mac_array`, all sharing the same 8-bit data input
- Each unit computes `accum += data_in × weight` on every compute pulse
- Weights are loaded serially through a daisy-chain shift register (MSB-first, 16 bits total)
- Accumulators are read out serially (MSB-first, 40 bits total: 4 × 10-bit)

**FSM (in `project.v`)**

The top-level FSM has three states:

| State | Description |
|-------|-------------|
| `IDLE` | Default state. Accepts `compute` and `clear_accum` pulses. |
| `LOAD_W` | Shifts in 16 serial weight bits over 16 clock cycles. |
| `READOUT` | Shifts out 40 accumulator bits over 40 clock cycles. |

**Signal interface**

| Pin | Direction | Function |
|-----|-----------|----------|
| `ui_in[0]` | Input | `serial_in` — weight bit during LOAD_W |
| `ui_in[1]` | Input | `load_weights` — pulse to enter LOAD_W |
| `ui_in[2]` | Input | `compute` — pulse to accumulate one input vector |
| `ui_in[3]` | Input | `read_out` — pulse to enter READOUT |
| `ui_in[4]` | Input | `clear_accum` — pulse to zero all accumulators |
| `uio_in[7:0]` | Input | `data_in` — 8-bit input applied to all 4 MAC units |
| `uo_out[0]` | Output | `serial_out` — result bit stream during READOUT |
| `uo_out[1]` | Output | `ready` — high when FSM is in IDLE |

## How to test

**Step 1 — Reset**

Pull `rst_n` low for at least 2 clock cycles, then release. All weights and accumulators clear to zero. `uo_out[1]` (ready) goes high.

**Step 2 — Load weights**

Pack 4 weights (4-bit each) MSB-first into a 16-bit serial stream. For weights `[w0, w1, w2, w3]`, the stream is `{w3[3:0], w2[3:0], w1[3:0], w0[3:0]}` sent MSB-first.

1. Assert `ui_in[1]` (load_weights) for one clock cycle — FSM enters LOAD_W.
2. Over the next 16 cycles, drive each bit onto `ui_in[0]` (serial_in) with `load_weights` deasserted.
3. FSM returns to IDLE automatically after 16 bits.

**Step 3 — Compute**

For each input vector value:
1. Place the 8-bit value on `uio_in[7:0]`.
2. Assert `ui_in[2]` (compute) for one clock cycle.
3. Each MAC unit accumulates: `accum[i] += data_in × weight[i]`.

Repeat for as many input samples as needed (accumulator saturates at 10 bits = 1023).

**Step 4 — Read results**

1. Assert `ui_in[3]` (read_out) for one clock cycle — FSM enters READOUT.
2. Sample `uo_out[0]` on each falling edge for 40 cycles.
3. The bit stream is `{accum0[9:0], accum1[9:0], accum2[9:0], accum3[9:0]}` MSB-first.

**Step 5 — Clear (optional)**

Assert `ui_in[4]` (clear_accum) for one clock cycle while in IDLE to zero all accumulators without reloading weights.

**Example**

Weights `[1, 2, 3, 4]`, inputs `[10, 20, 30]`:

```
accum0 = 10×1 + 20×1 + 30×1 = 60
accum1 = 10×2 + 20×2 + 30×2 = 120
accum2 = 10×3 + 20×3 + 30×3 = 180
accum3 = 10×4 + 20×4 + 30×4 = 240
```

## External hardware

No external hardware required. All I/O uses the standard Tiny Tapeout pin headers.

Optional: a logic analyser on `uo_out[0]` to capture the 40-bit serial readout, or a microcontroller (e.g. RP2040 on the TT demo board) to drive the weight/compute/readout protocol and display results.
