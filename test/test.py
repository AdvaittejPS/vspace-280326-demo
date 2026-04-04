import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge, Timer

async def reset_dut(dut):
    dut.ena.value   = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)


async def load_weights(dut, weights):
    """
    Shift 4x 4-bit weights into the MAC array via serial interface.
    weights[0] → u0, weights[1] → u1, weights[2] → u2, weights[3] → u3.
    The shift chain feeds u0 last, so send in reverse order MSB-first.
    """
    packed = 0
    for w in reversed(weights):
        packed = (packed << 4) | (w & 0xF)

    # Assert load_weights=1 so FSM enters LOAD_W on the next posedge
    dut.ui_in.value = 0b00000010
    await RisingEdge(dut.clk)   # FSM: IDLE → LOAD_W, bit_cnt=0

    # Shift 16 bits. Set serial_in before each posedge so DUT samples it.
    for i in range(15, -1, -1):
        dut.ui_in.value = (packed >> i) & 1   # serial_in bit, load_weights=0
        await RisingEdge(dut.clk)             # FSM shifts this bit in

    dut.ui_in.value = 0
    await ClockCycles(dut.clk, 2)


async def compute_input(dut, data):
    """Present data_in with compute=1 for one clock cycle."""
    dut.uio_in.value = data
    dut.ui_in.value  = 0b00000100   # compute=1
    await RisingEdge(dut.clk)       # MAC accumulates on this edge
    dut.uio_in.value = 0
    dut.ui_in.value  = 0


async def read_accumulators(dut):
    """Pulse read_out, then sample 40 serial bits at falling edges."""
    dut.ui_in.value = 0b00001000    # read_out=1
    await RisingEdge(dut.clk)       # FSM: IDLE → READOUT, bit_cnt=0, serial_out=bus[39]
    dut.ui_in.value = 0

    bits = 0
    for _ in range(40):
        await FallingEdge(dut.clk)  # sample stable output after posedge
        bits = (bits << 1) | int(dut.uo_out.value & 1)

    a0 = (bits >> 30) & 0x3FF
    a1 = (bits >> 20) & 0x3FF
    a2 = (bits >> 10) & 0x3FF
    a3 = (bits >>  0) & 0x3FF
    return a0, a1, a2, a3


@cocotb.test()
async def test_basic_mac(dut):
    """weights=[1,2,3,4], inputs=[10,20,30] → accums=[60,120,180,240]"""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
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
    """weights=[5,10,15,20], inputs=[0,0,0] → accums=[0,0,0,0]"""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
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
    """Accumulate, clear, then accumulate again — accums should reflect only post-clear values."""
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_dut(dut)

    await load_weights(dut, [1, 1, 1, 1])
    await compute_input(dut, 50)
    await ClockCycles(dut.clk, 2)

    # Clear
    dut.ui_in.value = 0b00010000    # clear_accum=1
    await RisingEdge(dut.clk)
    dut.ui_in.value = 0
    await ClockCycles(dut.clk, 2)

    await compute_input(dut, 7)
    await ClockCycles(dut.clk, 3)

    a0, a1, a2, a3 = await read_accumulators(dut)
    assert a0 == 7 and a1 == 7 and a2 == 7 and a3 == 7, \
        f"After clear+compute(7): got {a0},{a1},{a2},{a3}, expected all 7"
