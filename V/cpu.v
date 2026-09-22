module cpu
(
    input wire clk,
    input wire rst,
    input wire memReady,
    input wire irq,
    input wire [2:0] vec,

    inout wire [7:0] data,

    output wire [15:0] addr,
    output wire rw,
    output wire memReq
);

wire rgfMov, bus_data_in_e, bus_data_out_e, bus_addr_out_e, storeC, loadC;
wire [15:0] bus_addr;
wire [2:0] sel0, sel1;

reg [7:0] aluAcu, aluRes;
reg cf;

reg irqLatch;
reg [2:0] vecLatch;
wire clearInt;

wire aluOn;
wire storeAluAcu;
wire storeAluRes;
wire loadAluRes;
wire cout;
wire [4:0] aluCommand;

wire buOn;
wire [2:0] buCommand;
wire jump;

wire ime;

wire [7:0] alu_out;

always @(posedge irq) begin
    if (ime) begin
        irqLatch = irq;
        vecLatch = vec;
    end
end

assign data = loadAluRes ? aluRes : 8'hzz;

always @(posedge clk) begin
    if (rst) begin
        aluAcu <= 8'h00;
        aluRes <= 8'h00;

        irqLatch <= 0;
        vecLatch <= 3'b000;
    end else begin
        // Запис першого операнда (Акумулятора) з шини даних
        if (storeAluAcu) begin
            aluAcu <= data;
            cf <= cout;
        end

        // Запис результату обчислень АЛУ в регістр aluRes
        if (storeAluRes) begin
            aluRes <= alu_out;
        end

        if (clearInt) begin
            irqLatch <= 0;
            vecLatch <= 3'b000;
        end
    end
end

controlUnit cu
(
.data(data),
.clk(clk),
.rst(rst),

.irq(irqLatch),
.vec(vecLatch),

.sel0(sel0),
.sel1(sel1),
.rgfMov(rgfMov),
.bus_data_out_e(bus_data_out_e),
.bus_data_in_e(bus_data_in_e),
.bus_addr_out_e(bus_addr_out_e),
.loadC(loadC),
.storeC(storeC),

.addr(addr),

.aluOn(aluOn),
.storeAluAcu(storeAluAcu),
.storeAluRes(storeAluRes),
.loadAluRes(loadAluRes),
.aluCommand(aluCommand),

.jump(jump),
.buOn(buOn),
.buCommand(buCommand),

.memReady(memReady),
.memReq(memReq),
.rw(rw),

.clearInt(clearInt),
.ime(ime)
);

registersFile rgf
(
.mov(rgfMov),
.clk(clk),
.rst(rst),
.bus_data(data),
.bus_addr(addr),
.bus_data_in_e(bus_data_in_e),
.bus_data_out_e(bus_data_out_e),
.bus_addr_out_e(bus_addr_out_e),
.storeC(storeC),
.loadC(loadC),

.sel0(sel0),
.sel1(sel1)
);

alu alu
(
.on(aluOn),
.cin(cf),
.cout(cout),
.command(aluCommand),
.a(data),
.b(aluAcu),
.out(alu_out)
);

bu bu
(
.on(buOn),
.command(buCommand),
.num(data),
.jump(jump)
);

endmodule
