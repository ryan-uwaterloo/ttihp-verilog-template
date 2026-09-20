`default_nettype none
module LFSR16B4T #(
    parameter tap1 = 0,
    parameter tap2 = 2,
    parameter tap3 = 7,
    parameter tap4 = 12
) (
    input wire clk,
    input wire rst_n,
    input wire ena,
    output reg [15:0] lfsr_state
);
    
    reg [15:0] next_lfsr_state;

    always @(*) begin
        if (tap1 == 0 || tap2 == 0 || tap3 == 0 || tap4 == 0) begin
            next_lfsr_state[0] = lfsr_state[15];
        end else begin
            next_lfsr_state[0] = 1'b0;
        end
        for (integer i = 1; i<16 ; i = i + 1) begin
            if ((i == tap1) || (i == tap2) || (i == tap3) || (i == tap4)) begin
                next_lfsr_state[i] = lfsr_state[i-1] ^ lfsr_state[15];
            end else begin
                next_lfsr_state[i] = lfsr_state[i-1];
            end
        end
    end

    always @(posedge clk ) begin
        if (!rst_n) begin
            lfsr_state <= 16'hBEEF; // funny init
        end else if (ena) begin
            lfsr_state <= next_lfsr_state;
        end
    end

endmodule