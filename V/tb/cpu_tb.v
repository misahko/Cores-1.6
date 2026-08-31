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
        ram.mem[16'h0010] = 8'b00001011;  ram.mem[16'h0011] = 8'h00;
        // 0x02: MOVI R1, #0x30          -> pointer high byte; {R1,R0}=0x3000
        ram.mem[16'h0012] = 8'b00101011;  ram.mem[16'h0013] = 8'h30;
        // 0x04: MOVI R5, #0xAA          -> test value
        ram.mem[16'h0014] = 8'b10101011;  ram.mem[16'h0015] = 8'hAA;
        // 0x06: MOV  RC, R5             -> C = R5 (0xAA)   [see assumption 1]
        ram.mem[16'h0016] = 8'b10101100;
        // 0x07: STORE ARG0=R0, ARG1=R1  -> RAM[0x3000] = C (0xAA)
        ram.mem[16'h0017] = 8'b00010011;  ram.mem[16'h0018] = 8'b00100000;
        // 0x09: LOAD  ARG0=R0, ARG1=R1  -> C = RAM[0x3000], expect 0xAA
        ram.mem[16'h0019] = 8'b00001111;  ram.mem[16'h001A] = 8'b00100000;
        // 0x0B: PUSH R5   (0xC5 -- safe, doesn't collide w/ SYS 0xC0-0xC4)
        ram.mem[16'h001B] = 8'b10100011;
        // 0x0C: POP  R6   -> R6 should come back 0xAA
        ram.mem[16'h001C] = 8'b11000111;

        #4000;

        $display("---- final state ----");
        $display("R0=%h R1=%h R2=%h C(R3)=%h D(R4)=%h R5=%h R6=%h R7=%h",
            cpu.rgf.registers[0], cpu.rgf.registers[1], cpu.rgf.registers[2],
            cpu.rgf.registers[3], cpu.rgf.registers[4], cpu.rgf.registers[5],
            cpu.rgf.registers[6], cpu.rgf.registers[7]);
        $display("PC=%h", cpu.cu.PC);
        $display("RAM[0x3000]=%h (expect 55)", ram.mem[16'h3000]);
        $display("RAM[0x3001]=%h (expect aa)", ram.mem[16'h3001]);
        $display("expect: C=55, R5=aa, R6=aa(after POP), R7=aa(after LOADA), PC near 0021 (HALT addr)");

        #50 $finish;

    end
endmodule
