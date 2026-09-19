/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

//   wire clkq_posedge;
//   wire en_shreg;
//   wire [1:0] shreg_req;
//   wire shreg_data_in;
//   wire [15:0] shreg_out;
//   wire shreg_out_valid;
//   wire [3:0] shreg_status;
  
//   assign clkq_posedge = !ui_in[2] && ui_in[1];
//   assign en_shreg = ui_in[0]; // gate this later to be enable shifting of shreg
//   assign shreg_req = ui_in[4:3];
//   assign shreg_data_in = ui_in[5];
//   assign uo_out = shreg_out[15:8] ^ shreg_out [7:0];
//   assign uio_out[0] = shreg_out_valid;
//   assign uio_out[4:1] = shreg_status;
//   assign uio_out[7:5] = '0;

//   shiftreg_4x1B in_tx (.clk(clk), .rst_n(rst_n), .clkq_posedge(clkq_posedge), 
//       .data_in(shreg_data_in), .en_in(en_shreg), .req(shreg_req), 
//       .data_out(shreg_out), .data_out_valid(shreg_out_valid), .full_shregs(shreg_status));

//   assign uio_oe  = 8'hff;

//   // List all unused inputs to prevent warnings
//   wire _unused = &{ena, ui_in[7:6], uio_in, 1'b0};

    wire [7:0] deser_data;
    wire deser_valid;

    deserializer deserializer_inst (
        .clk(clk),
        .sclk(ui_in[0]),
        .copi(ui_in[1]),
        .n_cs(ui_in[2]),
        .rst_n(rst_n),
        .data(deser_data),
        .valid(deser_valid)
    );

    wire [3:0] buffer_entries;
    wire buffer_read_valid;
    wire [15:0] buffer_data;

    core_data_buffer core_data_buffer (
        .clk(clk),
        .rst_n(rst_n),
        .write_valid(deser_valid),
        .write_data(deser_data),
        .read_req(ui_in[4:3]),
        .full_entries(buffer_entries),
        .read_data_valid(buffer_read_valid),
        .read_data(buffer_data)
    );

    assign uio_out = {{3{1'b0}}, buffer_read_valid, buffer_entries};
    assign uo_out = buffer_data[15:8] ^ buffer_data[7:0];
    assign uio_oe = 8'hFF;

    wire _unused = &{ena, ui_in[7:5], uio_in, 1'b0};

endmodule
