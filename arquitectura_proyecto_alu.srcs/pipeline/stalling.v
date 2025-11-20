module stalling(
    input  [4:0] Rs1D,
    input  [4:0] Rs2D,
    input  [4:0] RdE,
    input        ResultSrcE,
    output       lwStall,
    output       StallF,
    output       StallD,
    output       FlushE
);

    assign lwStall = (ResultSrcE == 1'b1) && ((RdE == Rs1D) || (RdE == Rs2D));
    assign StallF  = lwStall;
    assign StallD  = lwStall;
    assign FlushE  = lwStall;

endmodule
