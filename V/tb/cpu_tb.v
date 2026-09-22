`timescale 1ns/1ps

module cpu_tb;
    reg clk;
    reg rst;
    wire [7:0] data;
    wire [15:0] addr;
    wire memReq;
    wire memReady;
    wire rw;

    reg [2:0] vec;
    reg irq;

    reg [7:0] tb_data;
    reg wr_tb_data;

    assign data = wr_tb_data ? tb_data : 8'hzz;

    cpu cpu(
        .clk(clk),
        .rst(rst),
        .data(data),
        .addr(addr),
        .rw(rw),
        .memReq(memReq),
        .memReady(memReady),
        .vec(vec),
        .irq(irq)
    );

  sram_with_ready ram (
            .clk(clk),
            .rst(rst),
            .addr(addr),
            .data(data),
            .cs(memReq),
            .we(rw),
            .ready(memReady)
        );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_cpu.vcd");
        $dumpvars(0, cpu_tb);

        rst = 1'b1;
        clk = 1'b0;
        tb_data = 8'h00;
        wr_tb_data = 1'b0;
        irq = 1'b0;
        vec = 3'b000;

        @(negedge clk);
        @(negedge clk);
        rst = 1'b0;

        // ---------------------------------------------------------------
        // BUS group: MOVI / LOAD / STORE round trip through RAM[0x3000]
        // ---------------------------------------------------------------
        // 0x00: MOVI R0, #0x00          -> pointer low byte

       ram.mem[16'h0000] = 8'h00; ram.mem[16'h0001] = 8'h28;


        ram.mem[16'h0010] = 8'b00001011;  ram.mem[16'h0011] = 8'h07; //MOVI
        ram.mem[16'h0012] = 8'b00000011; //PUSH
        ram.mem[16'h0013] = 8'b00100111; //POP
        ram.mem[16'h0014] = 8'b00001100; //MOV
        ram.mem[16'h0015] = 8'b00010011;  ram.mem[16'h0016] = 8'b00100000; //STORE
        ram.mem[16'h0017] = 8'b00001111;  ram.mem[16'h0018] = 8'b00100000; //LOAD
        ram.mem[16'h0019] = 8'b01010111;  ram.mem[16'h001a] = 8'h07; ram.mem[16'h001b] = 8'h07; //LOADA
        ram.mem[16'h001c] = 8'b01011011;  ram.mem[16'h001d] = 8'h08; ram.mem[16'h001e] = 8'h07; //STOREA
        ram.mem[16'h001f] = 8'b00011111;  ram.mem[16'h0020] = 8'b00100000; ram.mem[16'h0021] = 8'hff;
        ram.mem[16'h0022] = 8'b01110010;  ram.mem[16'h0023] = 16'h00; ram.mem[16'h0024] = 16'h2b;


        ram.mem[16'h0028] = 8'b11101011; ram.mem[16'h0029] = 8'hfa; //MOVI
        ram.mem[16'h002a] = 8'b00010110;

        ram.mem[16'h2800] = 8'b11101011; ram.mem[16'h2801] = 8'haf; //MOVI
        ram.mem[16'h2802] = 8'b00010110;




        #29
        irq = 1;
        #5
        irq = 0;

        #4000;

        $display("---- final state ----");
        $display("R0=%h R1=%h R2=%h C(R3)=%h D(R4)=%h R5=%h R6=%h R7=%h",
            cpu.rgf.registers[0], cpu.rgf.registers[1], cpu.rgf.registers[2],
            cpu.rgf.registers[3], cpu.rgf.registers[4], cpu.rgf.registers[5],
            cpu.rgf.registers[6], cpu.rgf.registers[7]);
        $display("PC=%h", cpu.cu.PC);
        $display("RAM[0x3000]=%h (expect 55)", ram.mem[16'h0707]);
        $display("RAM[0x3001]=%h (expect aa)", ram.mem[16'h0807]);
        $display("expect: C=55, R5=aa, R6=aa(after POP), R7=aa(after LOADA), PC near 0021 (HALT addr)");

        #50 $finish;

    end
endmodule
