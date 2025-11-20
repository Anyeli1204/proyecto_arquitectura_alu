module MEM_WB(
    input clk, reset,
    input RegWriteM,
    input [1:0] ResultSrcM,
    input [31:0] ALUResultM, ReadDataM, PCPlus4M,
    input [4:0] RdM,

    output reg RegWriteW,
    output reg [1:0] ResultSrcW,
    output reg [31:0] ALUResultW, ReadDataW, PCPlus4W,
    output reg [4:0] RdW
);

    // falta el reset
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            RegWriteW <= 0;
            ResultSrcW <= 0;
            ALUResultW <= 0;
            ReadDataW <= 0;
            PCPlus4W <= 0;
            RdW <= 0;
        end else begin
            RegWriteW <= RegWriteM;
            ResultSrcW <= ResultSrcM;
            ALUResultW <= ALUResultM;
            ReadDataW <= ReadDataM;
            PCPlus4W <= PCPlus4M;
            RdW <= RdM;
        end
    end

endmodule