`timescale 1ns/1ps

module sram_with_ready #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 16,
    parameter LATENCY    = 3   // Кількість тактів затримки (>= 1)
)(
    input  wire                  clk,
    input  wire                  rst,

    input  wire                  cs,      // Chip Select (1: запит до пам'яті)
    input  wire                  we,      // 0: читання, 1: запис
    input  wire [ADDR_WIDTH-1:0] addr,    // Шина адреси

    inout  wire [DATA_WIDTH-1:0] data,    // Двонаправлена шина з 3-ма станами (High-Z)

    output wire                  ready    // 1: готово / немає запиту, 0: зайнято
);

    // Масив пам'яті
    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    reg [2:0]            wait_cnt;
    reg                  busy;
    reg [ADDR_WIDTH-1:0] latched_addr;

    // Пам'ять зайнята, якщо триває цикл очікування LATENCY
    wire is_busy = (cs && !busy && (LATENCY > 1)) || (busy && (wait_cnt < LATENCY - 1));

    // Сигнал готовності (активний високий рівень 1)
    assign ready = !is_busy;

    // Поточна адреса (фіксована під час очікування або пряма)
    wire [ADDR_WIDTH-1:0] current_addr = (busy || (LATENCY > 1)) ? latched_addr : addr;

    // Керування тристайним станом шини data:
    // Дані виставляються ТІЛЬКИ коли є CS, іде ЧИТАННЯ (we=0) і пам'ять ГОТОВА (ready=1).
    // В усіх інших випадках шина перебуває в High-Z ('z).
    assign data = (cs && !we && ready) ? mem[current_addr] : {DATA_WIDTH{1'bz}};

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wait_cnt     <= 3'd0;
            busy         <= 1'b0;
            latched_addr <= {ADDR_WIDTH{1'b0}};
        end
        else begin
            if (cs && !busy) begin
                latched_addr <= addr; // Фіксуємо адресу на початку звернення

                if (LATENCY > 1) begin
                    busy     <= 1'b1;
                    wait_cnt <= 3'd1;
                end
                else if (we) begin
                    mem[addr] <= data; // Прямий запис, якщо LATENCY == 1
                end
            end
            else if (busy) begin
                if (wait_cnt < LATENCY - 1) begin
                    wait_cnt <= wait_cnt + 1'b1;
                end
                else begin
                    // Останній такт затримки
                    busy     <= 1'b0;
                    wait_cnt <= 3'd0;

                    if (we) begin
                        mem[latched_addr] <= data; // Запис даних з шини
                    end
                end
            end
        end
    end

endmodule
