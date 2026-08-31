module registersFile (
    input wire       mov,
    input wire       clk,
    input wire       rst,

    input wire       bus_data_in_e,
    input wire       bus_data_out_e,
    input wire       bus_addr_out_e,

    input wire [2:0] sel0,
    input wire [2:0] sel1,

    input wire storeC,
    input wire loadC,

    inout wire [7:0] bus_data,
    output wire [15:0] bus_addr
);

reg [7:0] registers [7:0];

integer i;

assign bus_data = bus_data_out_e ? registers[sel0] : loadC ? registers[3] : 8'hzz;
assign bus_addr = bus_addr_out_e ? {registers[sel1], registers[sel0]} : 16'hzzzz;


always @(posedge clk) begin
    if (rst) begin
        for (i = 0; i < 8; i = i + 1) begin
            registers[i] <= 8'h00;
        end
    end
    else begin
        if (mov) begin
            registers[sel0] <= registers[sel1];
        end

        if (bus_data_in_e) begin
            registers[sel0] <= bus_data;
        end

        if (storeC) begin
            registers[3] <= bus_data;
        end
    end
end

endmodule
