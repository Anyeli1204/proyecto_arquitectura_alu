module ID_EX(
    input clk, reset,
    input RegWriteD, MemWriteD, ALUSrcD,
    input [1:0] ResultSrcD,
    input [2:0] ALUControlD,
    input [31:0] RD1D, RD2D, ImmExtD, PCD, PCPlus4D,
    input [4:0] Rs1D, Rs2D, RdD,
    input [31:0] InstrD,
    
    input FlushE,

    output reg RegWriteE, MemWriteE, ALUSrcE,
    output reg [1:0] ResultSrcE,
    output reg [2:0] ALUControlE,
    output reg [31:0] RD1E, RD2E, ImmExtE, PCE, PCPlus4E,
    output reg [4:0] Rs1E, Rs2E, RdE,
    output reg [31:0] InstrE
);

always @(posedge clk) begin
    if (reset || FlushE) begin
        RegWriteE <= 0;
        MemWriteE <= 0;
        ALUSrcE <= 0;
        ResultSrcE <= 0;
        ALUControlE <= 0;
        RD1E <= 0;
        RD2E <= 0;
        ImmExtE <= 0;
        PCE <= 0;
        PCPlus4E <= 0;
        Rs1E <= 0;
        Rs2E <= 0;
        RdE <= 0;
    end else begin
        RegWriteE <= RegWriteD;
        MemWriteE <= MemWriteD;
        ALUSrcE <= ALUSrcD;
        ResultSrcE <= ResultSrcD;
        ALUControlE <= ALUControlD;
        RD1E <= RD1D;
        RD2E <= RD2D;
        ImmExtE <= ImmExtD;
        PCE <= PCD;
        PCPlus4E <= PCPlus4D;
        Rs1E <= Rs1D;
        Rs2E <= Rs2D;
        RdE <= RdD;
        InstrE <= InstrD;
    end
end

endmodule
