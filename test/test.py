import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_ro_puf(dut):
    dut._log.info("Starting RO-PUF Test")

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    # Start PUF measurement
    dut.ui_in.value = 1
    await ClockCycles(dut.clk, 1)
    dut.ui_in.value = 0

    # Wait for measurement (255 cycles + margin)
    await ClockCycles(dut.clk, 300)

    result = int(dut.uo_out.value)
    dut._log.info(f"PUF response: {hex(result)}")

    assert result in [0xAA, 0x55], f"Unexpected PUF output: {hex(result)}"
    dut._log.info("RO-PUF test passed!")
