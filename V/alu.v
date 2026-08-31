module alu (
    input wire on,
    input wire cin,
    input wire [4:0] command,
    input wire [7:0] a,
    input wire [7:0] b,

    output reg [7:0] out,
    output reg cout
);

reg [8:0] res;

always @(*) begin
    res = 9'b0;
    if (on) begin
        case (command)
            5'b00000: res = a & b;
            5'b00001: res = ~(a & b);
            5'b00010: res = ~(a | b);
            5'b00011: res = a | b;
            5'b00100: res = a ^ b;
            5'b00101: res = ~(a ^ b);
            5'b00110: res = a + b;
            5'b00111: res = a - b;
            5'b01000: res = a + b + cin;
            5'b01001: res = a - b - cin;
            5'b01010: res = {1'b0, a << b[2:0]};
            5'b01011: res = {1'b0, a >> b[2:0]};
            5'b01100: res = {1'b0, (a << b[2:0]) | (a >> (8 - b[2:0]))};
            5'b01101: res = {1'b0, (a >> b[2:0]) | (a << (8 - b[2:0]))};
            5'b01110: res = {1'b0, (a < b) ? a : b};
            5'b01111: res = {1'b0, (a > b) ? a : b};
            5'b10000: res = ~a;
            5'b10001: res = -a;
            5'b10010: res = a + 1;
            5'b10011: res = a - 1;
            default: res = 9'b0;
        endcase
        out = res[7:0];
        cout = res[8];
    end
    else begin
        out = 8'hzz;
        cout = 1'b0;
    end

end
endmodule
