import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge

# ---------------------------------------------------------------------------
# LED threshold helper — mirrors project.v comparators exactly
# ---------------------------------------------------------------------------
def leds_for(level):
    thresholds = [1, 11, 21, 32, 42, 52]
    result = 0
    for i, t in enumerate(thresholds):
        if level >= t:
            result |= (1 << i)
    return result

def read_leds(dut):
    return int(dut.uo_out.value) & 0x3F

# ---------------------------------------------------------------------------
# set_input: just drive ui_in, do NOT clock
# tick: advance one clock cycle (rising then falling edge)
# After tick(), uo_out reflects whatever ui_in was BEFORE the rising edge.
# ---------------------------------------------------------------------------
def set_input(dut, level, bypass=False):
    dut.ui_in.value = ((1 if bypass else 0) << 6) | (int(level) & 0x3F)

async def tick(dut):
    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)

# ---------------------------------------------------------------------------
# Test
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_sound_to_light(dut):
    dut._log.info("Starting Sound-to-Light Test")

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # -----------------------------------------------------------------------
    # Phase 1: Reset
    # -----------------------------------------------------------------------
    dut._log.info("--- Phase 1: Reset ---")
    dut.ena.value    = 1
    dut.ui_in.value  = 0
    dut.uio_in.value = 0
    dut.rst_n.value  = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    assert read_leds(dut) == 0, \
        f"FAIL Reset: expected 000000, got {read_leds(dut):06b}"
    dut._log.info("PASS Reset LEDs=000000")

    # -----------------------------------------------------------------------
    # Phase 2: Rising ramp (step=1, no spikes triggered)
    #
    # Pipeline: set input THEN tick. After tick, uo_out = leds_for(level).
    # Pre-fill shift register with 0s so ramp starts cleanly.
    # -----------------------------------------------------------------------
    dut._log.info("--- Phase 2: Rising ramp ---")

    # Pre-fill: drive 0 and tick 4 times
    set_input(dut, 0)
    for _ in range(4):
        await tick(dut)

    for level in range(0, 64):
        set_input(dut, level, bypass=False)
        await tick(dut)
        # After tick: reg_level=level, sample_r1=prev_level
        # delta = 1 < 16 => no spike => display = reg_level = level
        expected = leds_for(level)
        actual   = read_leds(dut)
        assert actual == expected, \
            f"FAIL ramp up level={level}: expected={expected:06b} got={actual:06b}"
        dut._log.info(f"PASS level={level:2d} LEDs={actual:06b}")

    # -----------------------------------------------------------------------
    # Phase 3: Spike filtered
    # Settle shift register at 20, then inject jump to 60.
    # After settling: reg_level=20, sample_r1=20
    # On spike tick: reg_level=60, sample_r1=20, delta=40>16 => spike
    #   => display = sample_r1 = 20
    # -----------------------------------------------------------------------
    dut._log.info("--- Phase 3: Spike injection (filtered) ---")

    set_input(dut, 20)
    for _ in range(4):
        await tick(dut)

    assert read_leds(dut) == leds_for(20), \
        f"FAIL settle at 20: expected={leds_for(20):06b} got={read_leds(dut):06b}"
    dut._log.info(f"Settled at 20, LEDs={read_leds(dut):06b}")
    # Inject spike
    set_input(dut, 60, bypass=False)
    await tick(dut)
    # reg_level=60, sample_r1=20, is_spike=True => display=20
    expected = leds_for(20)
    actual   = read_leds(dut)
    assert actual == expected, \
        f"FAIL spike not filtered: expected={expected:06b} got={actual:06b}"
    dut._log.info(f"PASS: Spike filtered, LEDs={actual:06b} (clamped to 20)")

    # -----------------------------------------------------------------------
    # Phase 4: Bypass mode — spike passes through
    # -----------------------------------------------------------------------
    dut._log.info("--- Phase 4: Bypass mode ---")

    set_input(dut, 20, bypass=True)
    for _ in range(4):
        await tick(dut)

    set_input(dut, 60, bypass=True)
    await tick(dut)
    # bypass=True => display = reg_level = 60
    expected = leds_for(60)
    actual   = read_leds(dut)
    assert actual == expected, \
        f"FAIL bypass: expected={expected:06b} got={actual:06b}"
    dut._log.info(f"PASS: Bypass spike visible, LEDs={actual:06b}")

    # -----------------------------------------------------------------------
    # Phase 5: Falling ramp (step=-1, no spikes triggered)
    # -----------------------------------------------------------------------
    dut._log.info("--- Phase 5: Falling ramp ---")

    set_input(dut, 63)
    for _ in range(4):
        await tick(dut)

    for level in range(63, -1, -1):
        set_input(dut, level, bypass=False)
        await tick(dut)
        expected = leds_for(level)
        actual   = read_leds(dut)
        assert actual == expected, \
            f"FAIL ramp down level={level}: expected={expected:06b} got={actual:06b}"
        dut._log.info(f"PASS level={level:2d} LEDs={actual:06b}")

    # -----------------------------------------------------------------------
    # Phase 6: Full scale — all 6 LEDs ON
    # -----------------------------------------------------------------------
    dut._log.info("--- Phase 6: Full scale ---")
    set_input(dut, 63)
    for _ in range(4):
        await tick(dut)
    assert read_leds(dut) == 0b111111, \
        f"FAIL full scale: expected=111111 got={read_leds(dut):06b}"
    dut._log.info("PASS: All 6 LEDs ON at level 63")

    # -----------------------------------------------------------------------
    # Phase 7: Zero level — all LEDs OFF
    # -----------------------------------------------------------------------
    dut._log.info("--- Phase 7: Zero level ---")
    set_input(dut, 0)
    for _ in range(4):
        await tick(dut)
    assert read_leds(dut) == 0, \
        f"FAIL zero: expected=000000 got={read_leds(dut):06b}"
    dut._log.info("PASS: All 6 LEDs OFF at level 0")

    dut._log.info("===========================================")
    dut._log.info("ALL TESTS PASSED — Sound-to-Light Visualizer")
    dut._log.info("===========================================")
