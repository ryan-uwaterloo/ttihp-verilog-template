# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb.types import LogicArray
import random

async def await_half_sclk(dut):
    """Wait for the SCLK signal to go high or low."""
    start_time = cocotb.utils.get_sim_time(unit="ns")
    while True:
        await ClockCycles(dut.clk, 1)
        # Wait for half of the SCLK period (10 us)
        if (start_time + 100*100*0.5) < cocotb.utils.get_sim_time(unit="ns"):
            break
    return

def ui_in_logicarray(read_req_size, read_req_valid, ncs, bit, sclk):
    """Setup the ui_in value as a LogicArray."""
    return LogicArray(f"000{read_req_size}{read_req_valid}{ncs}{bit}{sclk}")

async def send_spi_byte(dut, data):
    """
    Send an SPI byte
    
    Parameters:
    - data: LogicArray or int, 8-bit data
    """
    # Convert data to int if it's a LogicArray
    if isinstance(data, LogicArray):
        data_int = int(data)
    else:
        data_int = data
    # Validate inputs
    if data_int < 0 or data_int > 255:
        raise ValueError("Data must be 8-bit (0-255)")
    # Start transaction - pull CS low
    sclk = 0
    ncs = 0
    bit = 0
    # Set initial state with CS low
    dut.ui_in.value = ui_in_logicarray(0, 0, ncs, bit, sclk)
    await ClockCycles(dut.clk, 1)
    # Send byte
    for i in range(8):
        bit = (data_int >> (7-i)) & 0x1
        # SCLK low, set COPI
        sclk = 0
        dut.ui_in.value = ui_in_logicarray(0, 0, ncs, bit, sclk)
        await await_half_sclk(dut)
        # SCLK high, keep COPI
        sclk = 1
        dut.ui_in.value = ui_in_logicarray(0, 0, ncs, bit, sclk)
        await await_half_sclk(dut)
    # End transaction - return CS high
    sclk = 0
    ncs = 1
    bit = 0
    dut.ui_in.value = ui_in_logicarray(0, 0, ncs, bit, sclk)
    await ClockCycles(dut.clk, 600)
    return ui_in_logicarray(0, 0, ncs, bit, sclk)

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

   # Set the clock period to 100 ns (10 MHz)
    clock = Clock(dut.clk, 100, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    ncs = 1
    bit = 0
    sclk = 0
    read_val = 0
    read_size = 0
    dut.ui_in.value = ui_in_logicarray(read_size, read_val, ncs, bit, sclk)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)

    dut._log.info("Test project behavior")

    rand_seed = 421

    await send_spi_byte(dut, 0xEC)

    assert dut.uio_out.value == 0x01, f"expected uio_out of 0x01, got {dut.uio_out.value} instead!"

    await ClockCycles(dut.clk, 1)

    dut.ui_in.value = ui_in_logicarray(0, 1, 0, 0, 0) # read request

    while int(dut.uio_out.value) & 0x10 != 0: # wait for read to be valid
        await ClockCycles(dut.clk, 1)

    assert dut.uo_out.value == 0xEC, f"expected uo_out of 0xEC, got {dut.uo_out.value} instead!"
