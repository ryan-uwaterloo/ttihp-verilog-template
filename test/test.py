# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


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

    dut._log.info("Test clock divider")

    tests = [(2,1),
             (3,2),
             (8,2),
             (67,5),
             (101,100),
             ]

    for test in tests:
        dut.ui_in.value = test[0]
        dut.uio_in.value = test[1]
        # Wait for one clock cycle to apply values
        await ClockCycles(dut.clk, 1)
        cur = 0
        prev = 0
        edges = 0

        # sample generated clock
        for _ in range (10000):
            await ClockCycles(dut.clk, 1)
            cur = dut.uo_out.value
            if cur != prev:
                edges += 1
            prev = cur

        expected = test[1]/(2*(test[0] + test[1]))
        div_ratio = edges/(10000 * 2) # 2 edges in a clock period

        assert (expected * 0.99 < div_ratio < expected * 1.01), f"In test {test} expected a ratio of {expected}, got {div_ratio} instead"

    dut._log.info("Clock divider test completed successfully")
