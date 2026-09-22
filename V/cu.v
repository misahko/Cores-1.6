module controlUnit
(
    input wire jump,
    input wire clk,
    input wire rst,
    input wire memReady,
    input wire irq,
    input wire [2:0] vec,

    output wire [2:0] sel0,
    output wire [2:0] sel1,
    output wire rgfMov,
    output wire loadCommand,
    output wire bus_data_out_e,
    output wire bus_data_in_e,
    output wire bus_addr_out_e,
    output wire storeC,
    output wire loadC,

    output wire aluOn,
    output wire storeAluAcu,
    output wire storeAluRes,
    output wire loadAluRes,
    output wire [4:0] aluCommand,

    output wire buOn,
    output wire [2:0] buCommand,

    output wire [15:0] addr,
    inout wire [7:0] data,

    output wire memReq,
    output wire rw,

    output wire clearInt,

    output wire ime
);

reg [2:0] T;
reg [15:0] PC, SP;
reg [7:0] IR [2:0];
reg IME;
reg inIntr;
reg [1:0] intT;

wire [7:0] vecHighAddr  = {4'b0, vec, 1'b0};   // vec*2
wire [7:0] vecLowAddr = vecHighAddr + 8'd1;

wire saveCommand, saveSecondWord, saveThirdWord, endT, incPC,
 loadSP, loadLowPC, loadHighPC, storeLowPC, storeHighPC, decSP,
 incSP, loadIR1, loadIR2, loadIRAddr, idMemReq, idRW, setIme, delIme;

wire setIntr, endIntr, setLowVec, setHighVec, intIncSP, intDecSP,
    intStoreHighPC, intStoreLowPC, intEndT, intLoadSP, intLoadHighPC,
    intLoadLowPC, intMemReq, intRW;

wire incSPCU, decSPCU, storeHighPCCU, storeLowPCCU, endTCU, loadLowPCCU, loadHighPCCU;

assign incSPCU = incSP | intIncSP;
assign decSPCU = decSP | intDecSP;
assign storeHighPCCU = storeHighPC | intStoreHighPC;
assign storeLowPCCU = storeLowPC | intStoreLowPC;
assign endTCU = intEndT | endT;

assign rw = idRW | intRW;
assign memReq = intMemReq | idMemReq;

assign ime = IME;

assign clearInt = endIntr;

wire takeIntr = (T == 3'b000) && irq && IME && !inIntr;

instructionDecoder id
(
.command(IR[0]),
.secondWord(IR[1]),
.T(T),
.takeIntr(takeIntr),
.inIntr(inIntr),
.saveCommand(saveCommand),
.saveSecondWord(saveSecondWord),
.saveThirdWord(saveThirdWord),
.endT(endT),
.incPC(incPC),

.rgfMov(rgfMov),
.sel0(sel0),
.sel1(sel1),
.bus_data_out_e(bus_data_out_e),
.bus_data_in_e(bus_data_in_e),
.bus_addr_out_e(bus_addr_out_e),
.storeC(storeC),
.loadC(loadC),

.aluOn(aluOn),
.storeAluAcu(storeAluAcu),
.storeAluRes(storeAluRes),
.loadAluRes(loadAluRes),
.aluCommand(aluCommand),

.buOn(buOn),
.buCommand(buCommand),

.memReq(idMemReq),
.rw(idRW),

.loadSP(loadSP),
.incSP(incSP),
.decSP(decSP),

.storeHighPC(storeHighPC),
.storeLowPC(storeLowPC),
.loadHighPC(loadHighPC),
.loadLowPC(loadLowPC),

.loadIR1(loadIR1),
.loadIR2(loadIR2),
.loadIRAddr(loadIRAddr),

.setIme(setIme),
.delIme(delIme)
);

interruptDecoder interruptDecoder
(
.intT(intT),
.takeIntr(takeIntr),

.incSP(intIncSP),
.decSP(intDecSP),

.storeHighPC(intStoreHighPC),
.storeLowPC(intStoreLowPC),

.setIntr(setIntr),
.endIntr(endIntr),

.endT(intEndT),

.loadSP(intLoadSP),

.loadHighPC(intLoadHighPC),
.loadLowPC(intLoadLowPC),

.setLowVec(setLowVec),
.setHighVec(setHighVec),

.rw(intRW),
.memReq(intMemReq)
);

assign addr = setHighVec ? {8'h00, vecHighAddr} : setLowVec ? {8'h00, vecLowAddr} : (intLoadSP | loadSP) ? SP : (saveCommand | saveSecondWord | saveThirdWord) ? PC : loadIRAddr ? {IR[1], IR[2]} :16'hzzzz;

assign data = (loadLowPC | intLoadLowPC) ? PC[7:0] : (loadHighPC | intLoadHighPC) ? PC[15:8] : loadIR1 ? IR[1] : loadIR2 ? IR[2] : 8'hzz;

always @(posedge clk) begin
    if(rst) begin
        intT <= 2'b00;
        T <= 3'b000;
        PC <= 16'h0010;
        SP <= 16'hffff;
        IR[0] <= 8'h00;
        IR[1] <= 8'h00;
        IR[2] <= 8'h00;
        IME <= 1'b1;
        inIntr <= 1'b0;
    end
    else begin
        if (!memReady & memReq) begin
            T <= T;   // Заморожуємо такт T
            PC <= PC; // Заморожуємо лічильник команд
            intT <= intT;
        end
        else begin
            if (endTCU | inIntr) begin
                T <= 3'b000;
            end
            else begin
                T <= T + 1;
            end

            if (incPC) begin
                PC <= PC + 1;
            end

            if (inIntr) begin
                intT <= intT + 1;
            end
            else begin
                intT <= 2'b00;
            end

            if (incSPCU) begin
                SP <= SP + 1;
            end

            if (decSPCU) begin
                SP <= SP - 1;
            end

            if (storeHighPCCU) begin
                PC[15:8] <= data;
            end

            if (storeLowPCCU) begin
                PC[7:0] <= data;
            end

            if (saveCommand) begin
                IR[0] <= data;
            end else if (saveSecondWord) begin
                IR[1] <= data;
            end else if (saveThirdWord) begin
                IR[2] <= data;
            end

            if (jump) begin
                PC <= {IR[1], IR[2]};
            end

            if (setIntr) begin
                inIntr <= 1'b1;

                IME <= 1'b0;
            end

            if (endIntr) begin
                inIntr <= 1'b0;
                IME <= 1'b1;
            end

            if (setIme) begin
                IME <= 1'b1;
            end

            if (delIme) begin
                IME <= 1'b0;
            end
        end
    end

end

endmodule

module interruptDecoder
(
    input wire takeIntr,
    input wire [1:0] intT, //

    output reg setIntr, //
    output reg endIntr,//
    output reg endT, //

    output reg loadSP, //

    output reg decSP, //
    output reg incSP, //

    output reg loadLowPC, //
    output reg loadHighPC, //

    output reg memReq, //
    output reg rw, //

    output reg setLowVec, //
    output reg setHighVec, //

    output reg storeHighPC, //
    output reg storeLowPC //
);

always @(*) begin
    loadSP = 1'b0;
    decSP = 1'b0;
    incSP = 1'b0;
    loadLowPC = 1'b0;
    loadHighPC = 1'b0;
    memReq = 1'b0;
    rw = 1'b0;
    setIntr = 1'b0;
    endIntr = 1'b0;
    setLowVec = 1'b0;
    setHighVec = 1'b0;
    storeHighPC = 1'b0;
    storeLowPC = 1'b0;
    endT = 1'b0;

    case (intT)
        3'b000: begin
            if (takeIntr) begin
                setIntr = 1'b1;

                loadSP = 1'b1;
                decSP = 1'b1;

                loadLowPC = 1'b1;

                memReq = 1'b1;
                rw = 1'b1;
            end
        end

        3'b001: begin
            loadSP = 1'b1;
            decSP = 1'b1;
            loadHighPC = 1'b1;

            memReq = 1'b1;
            rw = 1'b1;
        end

        3'b010: begin
            setLowVec = 1'b1;
            storeLowPC = 1'b1;

            memReq = 1'b1;
        end

        3'b011: begin
            setHighVec = 1'b1;
            storeHighPC = 1'b1;

            endIntr = 1'b1;
            endT = 1'b1;

            memReq = 1'b1;
        end
    endcase
end

endmodule

module instructionDecoder
(
    input wire [7:0] command,
    input wire [7:0] secondWord,
    input wire [2:0] T,

    input wire takeIntr,
    input wire inIntr,

    output reg saveCommand,
    output reg saveSecondWord,
    output reg saveThirdWord,
    output reg endT,
    output reg incPC,

    output reg rgfMov,
    output reg [2:0] sel0,
    output reg [2:0] sel1,
    output reg bus_data_out_e,
    output reg bus_data_in_e,
    output reg bus_addr_out_e,
    output reg storeC,
    output reg loadC,

    output reg aluOn,
    output reg storeAluAcu,
    output reg storeAluRes,
    output reg loadAluRes,
    output reg [4:0] aluCommand,

    output reg buOn,
    output reg [2:0] buCommand,

    output reg memReq,
    output reg rw,

    output reg loadSP,
    output reg loadLowPC,
    output reg loadHighPC,
    output reg storeLowPC,
    output reg storeHighPC,
    output reg decSP,
    output reg incSP,

    output reg loadIR1,
    output reg loadIR2,
    output reg loadIRAddr,

    output reg setIme,
    output reg delIme
);

always @(*) begin
        saveCommand = 1'b0;
        saveSecondWord = 1'b0;
        saveThirdWord = 1'b0;
        incPC = 1'b0;
        endT = 1'b0;

        rgfMov = 1'b0;
        sel0 = 3'b000;
        sel1 = 3'b000;
        bus_data_out_e = 1'b0;
        bus_data_in_e = 1'b0;
        bus_addr_out_e = 1'b0;
        storeC = 1'b0;
        loadC = 1'b0;

        aluOn = 1'b0;
        storeAluAcu = 1'b0;
        storeAluRes = 1'b0;
        loadAluRes = 1'b0;
        aluCommand = 5'b00000;

        buOn = 1'b0;
        buCommand = 3'b000;

        memReq = 1'b0;
        rw = 1'b0;

        loadSP = 1'b0;

        loadLowPC = 1'b0;
        loadHighPC = 1'b0;
        storeLowPC = 1'b0;
        storeHighPC = 1'b0;

        incSP = 1'b0;
        decSP = 1'b0;

        loadIR1 = 1'b0;
        loadIRAddr = 1'b0;
        loadIR2 = 1'b0;

        setIme = 1'b0;
        delIme = 1'b0;
        if (!inIntr) begin
            case (T)
                3'b000: begin
                    if (!takeIntr) begin
                        saveCommand = 1'b1;
                        memReq = 1'b1;
                        incPC = 1'b1;
                    end
                end

                3'b001: begin

                    if (command == 8'b00000110) begin
                        setIme <= 1'b1;
                        endT <= 1'b1;
                    end

                    if (command == 8'b00001110) begin
                        delIme <= 1'b1;
                        endT <= 1'b1;
                    end

                    if (command[1:0] == 2'b00) begin //MOV
                        rgfMov = 1'b1;
                        sel0 = command[4:2];
                        sel1 = command[7:5];
                        endT = 1'b1;
                    end

                    if (command[1:0] == 2'b01) begin //ALU: save second word
                        saveSecondWord = 1'b1;
                        memReq = 1'b1;
                        incPC = 1'b1;
                    end

                    if (command[2:0] == 3'b010  && command[6:3] != 4'b0111) begin //BU: save second word
                        saveSecondWord = 1'b1;
                        memReq = 1'b1;
                        incPC = 1'b1;
                    end

                    if (command[4:0] == 5'b01011) begin //MOVI: save second word
                        saveSecondWord = 1'b1;
                        memReq = 1'b1;
                        incPC = 1'b1;
                    end

                    if (command[4:0] == 5'b01111) begin //LOAD: save second word
                        saveSecondWord = 1'b1;
                        memReq = 1'b1;
                        incPC = 1'b1;
                    end

                    if (command[4:0] == 5'b10011) begin //STORE: save second word
                        saveSecondWord = 1'b1;
                        memReq = 1'b1;
                        incPC = 1'b1;
                    end

                    if (command[4:0] == 5'b10111) begin //LOADA: save second word
                        saveSecondWord = 1'b1;
                        memReq = 1'b1;
                        incPC = 1'b1;
                    end

                    if (command[4:0] == 5'b11011) begin //STOREA: save second word
                        saveSecondWord = 1'b1;
                        memReq = 1'b1;
                        incPC = 1'b1;
                    end

                    if (command[4:0] == 5'b11111) begin //STOI: save second word
                        saveSecondWord = 1'b1;
                        memReq = 1'b1;
                        incPC = 1'b1;
                    end

                    if ((command[2:0] == 3'b010 && command[6:3] == 4'b0111) || (command == 8'b00010110)) begin //BU RET | RETI: save high PC 1part
                        incSP = 1'b1;
                    end

                    if (command[4:0] == 5'b00011) begin //PUSH
                        bus_data_out_e = 1'b1;
                        sel0 = command[7:5];

                        loadSP = 1'b1;
                        memReq = 1'b1;
                        rw = 1'b1;

                        decSP = 1'b1;
                        endT = 1'b1;
                    end

                    if (command[4:0] == 5'b00111) begin //POP
                        incSP = 1'b1;
                    end
                end

                3'b010: begin
                    if (command[1:0] == 2'b01 && command[6] == 1'b0) begin //ALU: save first arg at acum
                        bus_data_out_e = 1'b1;
                        sel0 = secondWord[2:0];

                        storeAluAcu = 1'b1;
                    end

                    if (command[1:0] == 2'b01 && command[6] == 1'b1) begin //ALU: save result at acum
                        bus_data_out_e = 1'b1;
                        sel0 = secondWord[2:0];

                        aluOn = 1'b1;
                        aluCommand = command[6:2];
                        storeAluRes = 1'b1;
                    end

                    if (command[2:0] == 3'b010 && command[6:3] != 4'b0111) begin //BU: save third word
                        saveThirdWord = 1'b1;
                        memReq = 1'b1;
                        incPC = 1'b1;
                    end

                    if ((command[2:0] == 3'b010 && command[6:3] == 4'b0111) || (command == 8'b00010110)) begin //BU RET | RETI: save high PC 2part

                        storeHighPC = 1'b1;
                        loadSP = 1'b1;
                        memReq = 1'b1;

                        incSP = 1'b1;
                    end

                    if (command[4:0] == 5'b00111) begin //POP

                        bus_data_in_e = 1'b1;
                        sel0 = command[7:5];

                        loadSP = 1'b1;
                        memReq = 1'b1;
                        endT = 1'b1;
                    end

                    if (command[4:0] == 5'b01011) begin //MOVI: load data and save
                        loadIR1 = 1'b1;

                        bus_data_in_e = 1'b1;
                        sel0 = command[7:5];

                        endT = 1'b1;
                    end

                    if (command[4:0] == 5'b01111) begin //LOAD: read RAM and save
                        sel0 = command[7:5];
                        sel1 = secondWord[7:5];
                        bus_addr_out_e = 1'b1;
                        storeC = 1'b1;

                        memReq = 1'b1;

                        endT = 1'b1;
                    end

                    if (command[4:0] == 5'b10011) begin //STORE: read RAM
                        sel0 = command[7:5];
                        sel1 = secondWord[7:5];
                        bus_addr_out_e = 1'b1;
                        loadC = 1'b1;

                        memReq = 1'b1;
                        rw = 1'b1;

                        endT = 1'b1;
                    end

                    if (command[4:0] == 5'b10111) begin //LOADA: save third word
                        saveThirdWord = 1'b1;
                        memReq = 1'b1;
                        incPC = 1'b1;
                    end

                    if (command[4:0] == 5'b11011) begin //STOREA: save third word
                        saveThirdWord = 1'b1;
                        memReq = 1'b1;
                        incPC = 1'b1;
                    end

                    if (command[4:0] == 5'b11111) begin //STOI: save third word
                        saveThirdWord = 1'b1;
                        memReq = 1'b1;
                        incPC = 1'b1;
                    end
                end

                3'b011: begin
                    if (command[1:0] == 2'b01 && command[6] == 1'b0) begin //ALU: save result at acum
                        bus_data_out_e = 1'b1;
                        sel0 = secondWord[5:3];

                        aluOn = 1'b1;
                        aluCommand = command[6:2];
                        storeAluRes = 1'b1;
                    end

                    if (command[1:0] == 2'b01 && command[6] == 1'b1) begin //ALU: save result at rgf
                        bus_data_in_e = 1'b1;
                        sel0 = 3'b011;

                        loadAluRes = 1'b1;

                        endT = 1'b1;
                    end

                    if (command[2:0] == 3'b010 && command[6] == 1'b0 && command[6:3] != 4'b0110 && command[6:3] != 4'b0111) begin //BU: load D to alu reg
                        bus_data_out_e = 1'b1;
                        sel0 = 3'b100;

                        storeAluAcu = 1'b1;
                    end

                    if (command[2:0] == 3'b010 && command[6:3] == 4'b0110) begin //BU CALL: save low PC
                        loadLowPC = 1'b1;

                        loadSP = 1'b1;
                        memReq = 1'b1;
                        rw = 1'b1;

                        decSP = 1'b1;
                    end

                    if ((command[2:0] == 3'b010 && command[6:3] == 4'b0111) || (command == 8'b00010110)) begin //BU RET | RETI: save low PC

                        storeLowPC = 1'b1;
                        loadSP = 1'b1;
                        memReq = 1'b1;

                        if (command == 8'b00010110) begin
                            setIme <= 1'b1;
                        end

                        endT = 1'b1;
                    end


                    if (command[2:0] == 3'b010 && command[6] == 1'b1) begin //BU: jump for only C
                        bus_data_out_e = 1'b1;
                        sel0 = 3'b011;

                        buOn = 1'b1;
                        buCommand = command[5:3];

                        endT = 1'b1;
                    end

                    if (command[4:0] == 5'b10111) begin //LOADA: save data
                        loadIRAddr = 1'b1;
                        memReq = 1'b1;

                        bus_data_in_e = 1'b1;
                        sel0 = command[7:5];

                        endT = 1'b1;
                    end

                    if (command[4:0] == 5'b11011) begin //STOREA: store data
                        loadIRAddr = 1'b1;
                        memReq = 1'b1;
                        rw = 1'b1;

                        bus_data_out_e = 1'b1;
                        sel0 = command[7:5];

                        endT = 1'b1;
                    end

                    if (command[4:0] == 5'b11111) begin //STOI: store data at ram
                        bus_addr_out_e = 1'b1;
                        sel0 = command[7:5];
                        sel1 = secondWord[7:5];

                        rw = 1'b1;
                        memReq = 1'b1;

                        loadIR2 = 1'b1;

                        endT = 1'b1;
                    end
                end

                3'b100: begin
                    if (command[1:0] == 2'b01 && command[6] == 1'b0) begin //ALU: save result at rgf
                        bus_data_in_e = 1'b1;
                        sel0 = 3'b011;

                        loadAluRes = 1'b1;

                        endT = 1'b1;
                    end

                    if (command[2:0] == 3'b010 && command[6] == 1'b0 && command[6:3] != 4'b0110) begin //BU: save res to acum
                        bus_data_out_e = 1'b1;
                        sel0 = 3'b011;

                        aluOn = 1'b1;
                        aluCommand = 5'b00111;
                        storeAluRes = 1'b1;
                    end

                    if (command[2:0] == 3'b010 && command[6:3] == 4'b0110) begin //BU CALL:  save high PC

                        loadHighPC = 1'b1;

                        loadSP = 1'b1;
                        memReq = 1'b1;
                        rw = 1'b1;

                        decSP = 1'b1;
                    end
                end

                3'b101: begin
                    if (command[2:0] == 3'b010 && command[6] == 1'b0) begin //BU: jump
                        loadAluRes = 1'b1;

                        buOn = 1'b1;
                        buCommand = command[5:3];

                        endT = 1'b1;
                    end

                    if (command[2:0] == 3'b010 && command[6:3] == 4'b0110) begin //BU CALL:  jump
                        buOn = 1'b1;
                        buCommand = command[5:3];

                        endT = 1'b1;
                    end
                end


            endcase
        end
    end

endmodule
