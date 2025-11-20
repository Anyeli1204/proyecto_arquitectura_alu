module dataforwaring(
    input  [4:0] Rs1E, Rs2E,
    input  [4:0] RdM, RdW,
    input        RegWriteM, RegWriteW,
    output reg [1:0] forwardAE,
    output reg [1:0] forwardBE
);
    always @(*) begin
        forwardAE = 2'b00;
        forwardBE = 2'b00;

        if (RegWriteM && (RdM != 0) && (RdM == Rs1E))
            forwardAE = 2'b10;
        else if (RegWriteW && (RdW != 0) && (RdW == Rs1E))
            forwardAE = 2'b01;

        if (RegWriteM && (RdM != 0) && (RdM == Rs2E))
            forwardBE = 2'b10;
        else if (RegWriteW && (RdW != 0) && (RdW == Rs2E))
            forwardBE = 2'b01;
    end
endmodule
