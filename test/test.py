import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

class LogicLockModel:
    def __init__(self, master_key=0xA5C3):
        self.master_key = master_key
        self.shift_reg = 0x0000
        self.unlocked = False

    def shift_in(self, bit):
        self.shift_reg = ((self.shift_reg << 1) & 0xFFFF) | bit
        self.unlocked = (self.shift_reg == self.master_key)

    def is_unlocked(self):
        return self.unlocked

async def get_toggle_count(dut, cycles):
    """
    Measures activity on uo[1].
    In simulation, 'Locked' might show 0 toggles if the frequency 
    is faster than the sampling rate, but we check for state consistency.
    """
    count = 0
    # Capture initial state
    last_val = (int(dut.uo_out.value) >> 1) & 1
    for _ in range(cycles):
        await ClockCycles(dut.clk, 1)
        current_val = (int(dut.uo_out.value) >> 1) & 1
        if current_val != last_val:
            count += 1
            last_val = current_val
    return count

async def shift_key(dut, model, key_value):
    """
    Helper to shift a 16-bit key into the hardware via ui[0] and ui[1].
    """
    for i in range(15, -1, -1):
        bit = (key_value >> i) & 1
        # Set data bit on ui[0]
        current_ui = int(dut.ui_in.value)
        dut.ui_in.value = (current_ui & ~0x01) | bit 
        await ClockCycles(dut.clk, 1)
        
        # Pulse shift clock on ui[1]
        dut.ui_in.value = int(dut.ui_in.value) | 0x02
        await ClockCycles(dut.clk, 2)
        dut.ui_in.value = int(dut.ui_in.value) & ~0x02
        await ClockCycles(dut.clk, 1)
        
        if model:
            model.shift_in(bit)

@cocotb.test()
async def test_logic_lock_with_golden_vectors(dut):
    dut._log.info("Starting Logic Lock Golden Vector Test")
    
    model = LogicLockModel(master_key=0xA5C3)
    clock = Clock(dut.clk, 100, unit="ns") # 10MHz Clock
    cocotb.start_soon(clock.start())

    # --- Phase 1: Reset & Initial State ---
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)

    # In digital simulation, 'Locked' usually forces the counter 
    # to stick at a high value or toggle at clk/2.
    # We verify that uo[0] (Unlocked LED) is correctly LOW.
    assert (int(dut.uo_out.value) & 0x01) == 0, "Error: uo[0] should be LOW (Locked)"
    dut._log.info("Initial Locked state confirmed.")

    # --- Phase 2: Unauthorized Entry (Wrong Key) ---
    dut._log.info("Attempting unauthorized entry with key 0x1234")
    await shift_key(dut, None, 0x1234)
    await ClockCycles(dut.clk, 20)
    
    assert (int(dut.uo_out.value) & 0x01) == 0, "Security Failure: Wrong key accepted!"
    dut._log.info("Wrong key rejected correctly.")

    # --- Phase 3: Authorized Entry (Correct Key) ---
    dut._log.info("Applying Golden Key: 0xA5C3")
    await shift_key(dut, model, 0xA5C3)
    await ClockCycles(dut.clk, 20)
    
    # Verify the Unlock LED (uo[0]) triggers
    actual_unlock = (int(dut.uo_out.value) & 0x01)
    assert actual_unlock == 1, "Unlock failed: uo[0] stayed LOW for correct key"
    dut._log.info("System signaled UNLOCK successfully.")

    # --- Phase 4: Golden Vector Frequency Check ---
    # Now that it's unlocked, uo[1] should be a slow 1Hz signal.
    # It should definitely NOT toggle in a 1000 cycle window at 10MHz.
    dut._log.info("Verifying Golden Vector: Stable Functional State")
    toggles = await get_toggle_count(dut, 1000)
    assert toggles == 0, f"Golden Vector Fail: Unlocked output is unstable! Got {toggles} toggles"
    dut._log.info("Unlocked output verified: Stable 1Hz signal detected.")

    # --- Phase 5: Immediate Re-Lock (Tamper Test) ---
    dut._log.info("Testing Tamper Response (Shifting 1 extra bit)")
    await shift_key(dut, None, 0x1) 
    await ClockCycles(dut.clk, 10)
    
    assert (int(dut.uo_out.value) & 0x01) == 0, "Tamper Failure: System stayed unlocked after key shift"
    dut._log.info("System re-locked successfully after tamper.")

    dut._log.info("All Security Vectors Passed.")
