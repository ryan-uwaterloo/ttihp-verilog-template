`default_nettype none

module core_data_buffer #(
    parameter DEPTH = 4
) (
    input wire clk,
    input wire rst_n,
    input wire write_valid,
    input wire [7:0] write_data,
    input wire [1:0] read_req, // read_req[0] == valid, [1] == size (0 = 8b, 1 = 16b)

    output reg [3:0] full_entries, // choose a more explicit full notification :)
    output reg read_data_valid,
    output reg [15:0] read_data
);

    reg [7:0] fifo [3:0];
    reg [3:0] in_selectOH; //OH encoded
    reg [1:0] in_select;
    reg [1:0] out_select; //UInt encoded

    reg [1:0] out_sel_plus_1;
    reg [1:0] out_sel_plus_2;
    reg [15:0] out_sel_data;
    reg valid_1_wide;
    reg valid_2_wide;

    always @(*) begin
        // UInto to OH
        in_selectOH = 4'h01 << in_select;

        // out_select intermediates
        out_sel_plus_1 = out_select + 1;
        out_sel_plus_2 = out_select + 2;
        // out_data intermediaries
        out_sel_data = ~read_req[1] ? {{8{1'b0}}, fifo[out_select]} : {fifo[out_sel_plus_1], fifo[out_select]};
        valid_1_wide = read_req == 2'b01 && full_entries[out_select];
        valid_2_wide = read_req == 2'b11 && (full_entries[out_select] & full_entries[out_sel_plus_1]);
    end

    always @(posedge clk) begin
        if(!rst_n)begin
            in_select <= 2'h0;
            out_select <= 2'h0;
            read_data <= 16'h0;
            read_data_valid <= 1'b0;
            full_entries <= '0;
        end else begin
            if (write_valid && !full_entries[in_select]) begin
                in_select <= in_select + 1;
                fifo[in_select] <= write_data;
                full_entries[in_select] <= 1'b1;
            end
            if (valid_1_wide) begin // if the shreg we're pointing to is full and we're reading only 1
                read_data_valid <= 1'b1;
                out_select <= out_sel_plus_1;
                full_entries[out_select] <= 1'b0;
            end else if (valid_2_wide) begin // the next 2 shregs are both full as we read both at once
                read_data_valid <= 1'b1;
                out_select <= out_sel_plus_2;
                full_entries[out_select] <= 1'b0;
                full_entries[out_sel_plus_1] <= 1'b0;
            end else begin
                read_data_valid <= 1'b0;
                out_select <= out_select;
            end
            read_data <= out_sel_data;
        end
   
    end

endmodule