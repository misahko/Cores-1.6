`timescale 1ns/1ps

module bu_tb;
    reg on;
    reg [2:0] command;
    reg [7:0] num;

    bu b(.on(on), .command(command), .num(num));

    initial begin
        $dumpfile("tb_bu.vcd");
        $dumpvars(0,bu_tb);
        on = 1'b1;
        command = 3'b000;
        num = 8'h00;

        #10
        $display("jump 0 == 0: %b", b.jump);
        num = 8'h01;

        #10
        $display("jump 1 == 0: %b", b.jump);
        command = 3'b001;

        #10
        $display("jump 1 != 0: %b", b.jump);
        num = 8'h00;

        #10
        $display("jump 0 != 0: %b", b.jump);
        command = 3'b010;

        #10
        $display("jump 0 < 0: %b", b.jump);
        num = 8'hff;

        #10
        $display("jump -128 < 0: %b", b.jump);
        num = 8'h01;

        #10
        $display("jump 1 < 0: %b", b.jump);

        $finish;



    end
endmodule
