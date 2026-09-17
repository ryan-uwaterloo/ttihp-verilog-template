`default_nettype none
// Fractional Clock Divider
// fq/fclk = c/2(b+c)
// important: 
//     b AND c must both be > 0
//     b >= c for correct behavior
//     b + c <= 127
// 8-bit gds : 118 cells
module clkdiv #(
    parameter integer ACCW = 8
    ) (
    input  wire clk,
    input  wire rst_n,
    input  wire [ACCW-1:0] b,
    input  wire [ACCW-1:0] c,
    output reg q
    );

    reg signed [ACCW-1:0] acc;
    reg signed [ACCW-1:0] addme;
    reg toggle;

    always @(*) begin
        if (acc < 0) begin
            addme  = b;
            toggle = 1;
        end else begin
            addme  = -c;
            toggle = 0;
        end
    end

    always @(posedge clk) begin
        if (~rst_n) begin
            acc <= 0;
            q  <= 0;
        end else begin
            acc <= acc + addme;
            if (toggle) 
                q <= ~q;
        end
    end
endmodule