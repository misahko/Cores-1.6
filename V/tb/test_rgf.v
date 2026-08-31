`timescale 1ns/1ps

module tb_rgf;
    reg clk;
    reg rst;
    reg [7:0] command;
    reg [7:0] bus_data_in;
    reg [2:0] sel0;
    reg [2:0] sel1;
    reg       bus_data_in_e;
    reg       mov;
    reg [15:0] bus_addr_out;
    reg        bus_addr_out_e;
    reg        bus_data_out_e;

    RegistersFile rgf (
    .clk(clk),
    .rst(rst),
    .command(command),
    .bus_data_in(bus_data_in),
    .bus_data_in_e(bus_data_in_e),
    .sel0(sel0),
    .sel1(sel1),
    .mov(mov),
    .bus_addr_out_e(bus_addr_out_e),
    .bus_data_out_e(bus_data_out_e)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_rgf.vcd");
        $dumpvars(0,tb_rgf);

        clk = 0;
        rst = 1;
        command = 8'h00;
        bus_data_in = 8'h00;
        bus_data_in_e = 1'h0;
        bus_addr_out = 16'h0000;
        bus_addr_out_e = 1'b0;
        sel0 = 3'b000;
        sel1 = 3'b000;
        mov = 1'b0;
        bus_data_out_e = 1'b0;


        #15
        rst = 0;

        #10

        bus_data_in_e = 1;
        bus_data_in = 8'h02;

        #10
        $display("reg0: %b", rgf.registers[0]);

        bus_data_in_e = 0;

        #10
        bus_data_in_e = 1;
        sel0 = 3'b001;
        bus_data_in = 8'h01;

        #10

        bus_data_in_e = 0;

        #10
        sel1 = 3'b000;
        bus_addr_out_e = 1'b1;
        bus_data_out_e = 1'b1;


        #100
        $display("reg0: %b", rgf.registers[0]);
        $display("reg1: %b", rgf.registers[1]);
        $display("reg2: %b", rgf.registers[2]);
        $display("reg3: %b", rgf.registers[3]);
        $display("reg4: %b", rgf.registers[4]);
        $display("reg5: %b", rgf.registers[5]);
        $display("reg6: %b", rgf.registers[6]);
        $display("reg7: %b", rgf.registers[7]);
        $display("addr_bus: %b", rgf.bus_addr_out);
        $display("data_bus: %b", rgf.bus_data_out);
        $finish;

    end


endmodule
