module bu
(
    input wire on,
    input wire [2:0] command,
    input wire signed [7:0] num,
    output reg jump
);

always @(*) begin
    if (on) begin
        case (command)
            3'b000: jump = (num == 0);
            3'b001: jump = (num != 0);
            3'b010: jump = (num < 0);
            3'b011: jump = (num <= 0);
            3'b100: jump = (num > 0);
            3'b101: jump = (num >= 0);
            3'b110: jump = 1'b1;
            3'b111: jump = 1'b1;
            default: jump = 1'b0;
        endcase
    end else begin
        jump = 1'b0;                 // <--- ДОДАНО: якщо on == 0, jump = 0
    end
end

endmodule
