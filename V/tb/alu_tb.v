`timescale 1ns/1ps

module alu_tb;
    reg on;
    reg [7:0] a;
    reg [7:0] b;
    reg [4:0] command;

    alu al(
        .on(on),
        .a(a),
        .b(b),
        .command(command)
    );
    initial begin
        $dumpfile("tb_alu.vcd");
        $dumpvars(0,alu_tb);

        on = 1'b1;
        a = 8'h01;
        b = 8'h03;
        command = 5'b00000;

        #10
        $display("and: %b", al.out);
        command = 5'b00001;

        #10
        $display("nand: %b", al.out);
        command = 5'b00010;

        #10
        $display("nor: %b", al.out);
        command = 5'b00011;

        #10
        $display("or: %b", al.out);
        command = 5'b00100;

        #10
        $display("xor: %b", al.out);
        command = 5'b00101;

        #10
        $display("xnor: %b", al.out);
        command = 5'b00110;

        #10
        $display("add: %b", al.out);
        command = 5'b00111;

        #10
        $display("sub: %b", al.out);
        command = 5'b01000;

        #10
        $display("adc: %b", al.out);
        command = 5'b01001;

        #10
        $display("sbb: %b", al.out);
        command = 5'b01010;

        #10
        $display("not: %b", al.out);
        command = 5'b01011;

        #10
        $display("ned: %b", al.out);
        command = 5'b01100;

        #10
        $display("inc: %b", al.out);
        command = 5'b01101;

        #10
        $display("dec: %b", al.out);
        command = 5'b01110;

        #10
        $display("nu: %b", al.out);
        command = 5'b01111;

        #10
        $display("zr: %b", al.out);
        command = 5'b10000;

        #10
        $display("shfl: %b", al.out);
        command = 5'b10001;

        #10
        $display("shfr: %b", al.out);
        command = 5'b10010;

        #10
        $display("rol: %b", al.out);
        command = 5'b10011;

        #10
        $display("ror: %b", al.out);
        command = 5'b10100;

        #10
        $display("min: %b", al.out);
        command = 5'b10101;

        #10
        $display("max: %b", al.out);

        $finish;

    end

endmodule
