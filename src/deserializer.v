`default_nettype none
// this module takes in an SPI signal and outputs bytes when ready
module deserializer #(
    parameter  CDC_LEN = 2
) (
    input wire clk,
    input wire sclk,
    input wire copi,
    input wire n_cs,
    input wire rst_n,
    output wire [7:0] data,
    output reg valid
);

//CDC
reg [CDC_LEN:0] sclk_cdc;
reg [CDC_LEN-1:0] copi_cdc;
reg [CDC_LEN-1:0] n_cs_cdc;

always @(posedge clk) begin
    sclk_cdc[0] <= sclk;
    copi_cdc[0] <= copi;
    n_cs_cdc[0] <= n_cs;
    for (integer i = 1; i < CDC_LEN; i = i + 1) begin
        sclk_cdc[i] <= sclk_cdc[i-1];
        copi_cdc[i] <= copi_cdc[i-1];
        n_cs_cdc[i] <= n_cs_cdc[i-1];
    end
    sclk_cdc[CDC_LEN] <= sclk_cdc[CDC_LEN-1];
end

wire posedge_sclk;
assign posedge_sclk = ~sclk_cdc[CDC_LEN] & sclk_cdc[CDC_LEN-1];

reg [7:0] data_shreg;
assign data = data_shreg [7:0];
// reg [2:0] txn_count; //3 bits to count to 8, one byte

always @(posedge clk) begin
    if (!rst_n) begin
        data_shreg <= 8'd1;
        valid <= 0;
    end else if (posedge_sclk && !n_cs_cdc[CDC_LEN-1]) begin
        valid <= data_shreg[7]; // when we shift out indicator, result is a valid byte
        data_shreg <= {data_shreg[7:0], copi_cdc[CDC_LEN-1]};
    end else if (n_cs_cdc[CDC_LEN-1] | valid) begin // if N_CS goes high, reset
        valid <= 0;
        data_shreg <= 8'd1;
    end
end

endmodule