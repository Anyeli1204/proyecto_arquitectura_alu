module IF_ID(
    input clk, reset, stallD, flushD,
    input [31:0] InstrF, PCF, PCPlus4F,
    output reg [31:0] InstrD, PCD, PCPlus4D
);

always @(posedge clk) begin
    if (reset || flushD) begin
        InstrD <= 32'b0;
        PCD <= 0;
        PCPlus4D <= 0;
    end else if (!stallD) begin
        InstrD <= InstrF;
        PCD <= PCF;
        PCPlus4D <= PCPlus4F;
    end
end

endmodule