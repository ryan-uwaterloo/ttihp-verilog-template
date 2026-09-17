`default_nettype none
module clkdiv2 #(
    parameter integer ACCW = 8
) (
    input  wire clk,
    input  wire rst_n,
    input  wire [ACCW-1:0] num,
    input  wire [ACCW-1:0] denom,
    output reg  q
);

    reg [ACCW-1:0] acc;

    always @(posedge clk) begin
        if (~rst_n) begin
            acc <= 0;
            q   <= 0;
        end
        else if (acc + num >= denom) begin
            acc <= acc + num - denom;
            q   <= ~q;
        end
        else begin
            acc <= acc + num;
        end
    end

endmodule