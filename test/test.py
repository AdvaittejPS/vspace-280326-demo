import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge
from cocotb.types import Logic


def read_bit(signal, index=0):
    try:
        return (int(signal.value) >> index) & 1
    except ValueError:
        val = signal.value
        bit = val[len(val) - 1 - index]
        return 0 if bit in (Logic("X"), Logic("Z"), Logic("U")) else int(bit)


async def load_weights(dut, weights):
    # Pack w[3]..w[0] MSB-first so u0 gets w[0] after 16 shifts through chain
    packed = 0
    for w in reversed(weights):
        packed = (packed << 4) | (w & 0xF)

    # Trigger FSM entry to LOAD_W — drive from falling edge for GL timing margin
    await FallingEdge(dut.clk)
    dut.ui_in.value = 0b00000010      # load_weights=1, serial_in=0
    await RisingEdge(dut.clk)         # FSM: IDLE→LOAD_W, bit_cnt=0

    # Send 16 bits MSB-first, one per cycle
    for i in range(15, -1, -1):
        bit = (packed >> i) & 1
        await FallingEdge(dut.clk)
        dut.ui_in.value = bit         # serial_in=bit, load_weights=0
        await RisingEdge(dut.clk)     # shifts this bit (bit_cnt 0..15)

    await FallingEdge(dut.clk)
    dut.ui_in.value = 0
    await ClockCycles(dut.clk, 2)


async def compute_input(dut, data):
    await FallingEdge(dut.clk)
    dut.uio_in.value = data
    dut.ui_in.value = 0b00000100      # compute=1
    await RisingEdge(dut.clk)         # MAC accumulates once
    await FallingEdge(dut.clk)
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await RisingEdge(dut.clk)


async def read_accumulators(dut):
    await FallingEdge(dut.clk)
    dut.ui_in.value = 0b00001000      # read_out=1
    await RisingEdge(dut.clk)         # FSM: IDLE→READOUT, bit_cnt=0, serial_out=accum_bus[39]

    bits = 0
    for _ in range(40):
        await FallingEdge(dut.clk)    # sample serial_out, then bit_cnt increments on next rise
        bits = (bits << 1) | read_bit(dut.uo_out, index=0)

    await FallingEdge(dut.clk)
    dut.ui_in.value = 0

    a0 = (bits >> 30) & 0x3FF
    a1 = (bits >> 20) & 0x3FF
    a2 = (bits >> 10) & 0x3FF
    a3 = (bits >>  0) & 0x3FF
    return a0, a1, a2, a3


async def reset_dut(dut):
    dut.ena.value    = 1
    dut.ui_in.value  = 0
    dut.uio_in.value = 0
    dut.rst_n.value  = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value  = 1
    await ClockCycles(dut.clk, 5)


@cocotb.test()
async def test_basic_mac(dut):
    """weights=[1,2,3,4], inputs=[10,20,30] -> accums=[60,120,180,240]"""
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)
    await load_weights(dut, [1, 2, 3, 4])
    for x in [10, 20, 30]:
        await compute_input(dut, x)
    await ClockCycles(dut.clk, 3)
    a0, a1, a2, a3 = await read_accumulators(dut)
    dut._log.info(f"accum0={a0} accum1={a1} accum2={a2} accum3={a3}")
    assert a0 == 60,  f"accum0: got {a0}, expected 60"
    assert a1 == 120, f"accum1: got {a1}, expected 120"
    assert a2 == 180, f"accum2: got {a2}, expected 180"
    assert a3 == 240, f"accum3: got {a3}, expected 240"


@cocotb.test()
async def test_zero_inputs(dut):
    """weights=[5,10,15,20], inputs=[0,0,0] -> accums=[0,0,0,0]"""
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)
    await load_weights(dut, [5, 10, 15, 20])
    for x in [0, 0, 0]:
        await compute_input(dut, x)
    await ClockCycles(dut.clk, 3)
    a0, a1, a2, a3 = await read_accumulators(dut)
    assert a0 == 0 and a1 == 0 and a2 == 0 and a3 == 0, \
        f"Expected all zeros, got {a0},{a1},{a2},{a3}"


@cocotb.test()
async def test_clear(dut):
    """Accumulate, then clear, then accumulate again."""
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)
    await load_weights(dut, [1, 1, 1, 1])
    await compute_input(dut, 50)
    await ClockCycles(dut.clk, 2)

    await FallingEdge(dut.clk)
    dut.ui_in.value = 0b00010000      # clear_accum=1
    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    dut.ui_in.value = 0
    await ClockCycles(dut.clk, 2)

    await compute_input(dut, 7)
    await ClockCycles(dut.clk, 3)
    a0, a1, a2, a3 = await read_accumulators(dut)
    assert a0 == 7 and a1 == 7 and a2 == 7 and a3 == 7, \
        f"After clear+compute(7): got {a0},{a1},{a2},{a3}, expected all 7"