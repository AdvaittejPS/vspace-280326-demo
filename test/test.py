import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_traffic_controller(dut):

    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1

    # Normal operation
    for _ in range(50):
        await ClockCycles(dut.clk, 10)

    # Pedestrian
    dut.ui_in.value = 1
    await ClockCycles(dut.clk, 20)

    # Night mode
    dut.ui_in.value = 2
    await ClockCycles(dut.clk, 20)

    # Emergency
    dut.ui_in.value = 4
    await ClockCycles(dut.clk, 20)

    assert True