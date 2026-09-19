`default_nettype none
// this design has 4 shift registers that are transitioned between, no storage FIFO structures.
module shiftreg_4x1B (
    input wire clk,
    input wire rst_n,
    input wire clkq_posedge,
    input wire data_in,
    input wire en_in, // enable_shifting
    input wire [1:0] req,
    output reg [15:0] data_out,
    output reg data_out_valid,
    output reg [3:0] full_shregs
);

    reg [8:0] array [3:0];
    reg [3:0] in_selectOH; //OH encoded
    reg [1:0] in_select;
    reg [1:0] out_select; //UInt encoded

    reg [1:0] out_sel_plus_1;
    reg [1:0] out_sel_plus_2;
    reg [15:0] out_sel_data;
    reg valid_1_wide;
    reg valid_2_wide;

    always @(*) begin
        // full shregs
        for (integer i = 0; i < 4 ; i = i + 1) begin
            full_shregs[i] = array[i][8];
        end

        // OH to UInt for in_selectOH
        // case (in_selectOH)
        //     4'b0001: in_select = 2'h0;
        //     4'b0010: in_select = 2'h1;
        //     4'b0100: in_select = 2'h2;
        //     4'b1000: in_select = 2'h3; 
        //     default: in_select = 2'h0;
        // endcase 
        in_selectOH = 4'h01 << in_select;

        // out_select intermediates
        out_sel_plus_1 = out_select + 1;
        out_sel_plus_2 = out_select + 2;
        // out_data intermediaries
        out_sel_data = req == 2'b01 ? {{8{1'b0}}, array[out_select][7:0]} : {array[out_sel_plus_1][7:0], array[out_select][7:0]};
        valid_1_wide = req == 2'b01 && full_shregs[out_select];
        valid_2_wide = req == 2'b10 && (full_shregs[out_select] & full_shregs[out_sel_plus_1]);
    end

    always @(posedge clk) begin
        if(!rst_n)begin
            in_select <= 2'h0;
            out_select <= 2'h0;
            data_out <= 16'h0;
            data_out_valid <= 1'b0; //todo the shift register is backwards lol
        end else begin
            if (array[in_select][7] && clkq_posedge && en_in && !(|(full_shregs & in_selectOH))) begin // on last shift for a shreg
                in_select <= in_select + 1;
            end
            if (valid_1_wide) begin // if the shreg we're pointing to is full and we're reading only 1
                data_out_valid <= 1'b1;
                out_select <= out_sel_plus_1;
            end else if (valid_2_wide) begin // the next 2 shregs are both full as we read both at once
                data_out_valid <= 1'b1;
                out_select <= out_sel_plus_2;
            end else begin
                data_out_valid <= 1'b0;
                out_select <= out_select;
            end
            data_out <= out_sel_data;
        end

        for (integer i = 0; i < 4 ; i = i + 1) begin
            if (!rst_n) begin
                array[i] <= 9'd1;
            end else begin
                if (in_selectOH[i] && clkq_posedge && en_in && !full_shregs[i]) begin
                    array[i] <= {array[i][7:0], data_in};
                end
                if (valid_1_wide && i[1:0] == out_select) begin
                    array[i] <= 9'd1;
                end else if (valid_2_wide && ((i[1:0] == out_select) | (i[1:0] == out_sel_plus_1))) begin
                    array[i] <= 9'd1;
                end
            end
        end    
    end
    

endmodule