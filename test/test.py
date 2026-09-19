# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
import random

async def send_byte(dut, byte):
    for i in range(8):
        dut.ui_in.value = 0x03 | (((byte & (1<<(7-i))) >> (7-i)) << 5)
        await ClockCycles(dut.clk, 1)
    dut.ui_in.value = 0x0
    await ClockCycles(dut.clk, 1)

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    dut._log.info("Test project behavior")

    rand_seed = 421

    await send_byte(dut, 0xEC)

    assert dut.uio_out.value == 0x02, f"expected uio_out of 0x02, got {dut.uio_out.value} instead!"

    await ClockCycles(dut.clk, 1)

    dut.ui_in.value = 0x08

    await ClockCycles(dut.clk, 2)

    assert dut.uo_out.value == 0xEC, f"expected uo_out of 0xEC, got {dut.uo_out.value} instead!"
