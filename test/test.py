import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_ro_puf(dut):
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0xAB
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 10)

    result = int(dut.uo_out.value)
    assert result != 0, f"Output should not be zero, got {hex(result)}"
    dut._log.info(f"LFSR output: {hex(result)} - PASS")
