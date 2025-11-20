module datapath (input  clk, reset,
                input  [1:0]  ResultSrc, 
                input  PCSrc, ALUSrc,
                input  RegWrite,
                input  [1:0]  ImmSrc, 
                input  [2:0]  ALUControl,
                output Zero,
                output [31:0] PC,
                input  [31:0] Instr,
                output [31:0] ALUResult, WriteData, 
                input  [31:0] ReadData
);

  localparam WIDTH = 32;

/*
  //display de todos los INPUTs
  always @(*) begin
      $display("----- PIPELINE INPUTS -----");
      $display("PCSrc: %b, ALUSrc: %b, RegWrite: %b, ResultSrc: %b, ImmSrc: %b, ALUControl: %b",
               PCSrc, ALUSrc, RegWrite, ResultSrc, ImmSrc, ALUControl);
  end
*/

  // =======================
  // WIRES
  // =======================
  wire [31:0] PCNext, PCPlus4, PCTarget;
  wire [31:0] ImmExt;
  wire [31:0] SrcA, SrcB;
  wire [31:0] Result;
  
// =======================
// HAZARD DETECTION WIRES
// =======================
  wire [1:0] forwardAE;
  wire [1:0] forwardBE;
  wire lwStall;
  wire StallF;
  wire StallD;
  wire FlushE;
  wire FlushD;

// =======================
// IF/ID REGISTER WIRES
// =======================
wire [31:0] InstrD, PCD, PCPlus4D;

// =======================
// ID/EX REGISTER WIRES
// =======================
wire RegWriteE, MemWriteE, ALUSrcE;
wire [1:0] ResultSrcE;
wire [2:0] ALUControlE;
wire [31:0] RD1E, RD2E, ImmExtE, PCE, PCPlus4E;
wire [4:0] Rs1E, Rs2E, RdE;


// =======================
// EX/MEM REGISTER WIRES
// =======================
wire RegWriteM, MemWriteM;
wire [1:0] ResultSrcM;
wire [31:0] ALUResultM, WriteDataM, PCPlus4M;
wire [4:0] RdM;

// =======================
// MEM/WB REGISTER WIRES
// =======================
wire RegWriteW;
wire [1:0] ResultSrcW;
wire [31:0] ALUResultW, ReadDataW, PCPlus4W;
wire [4:0] RdW;

// =======================
// ALU RESULT WIRE
// =======================
wire [31:0] ALUResult;


// =======================
// IF STAGE
// =======================
  flopr #(WIDTH) pcreg(

      // Input
      .clk(clk),
      .reset(reset),
      .d(PCNext),
      
      // Hazard
      .StallF(1'b0),

      // Output
      .q(PC)
  );

  adder pcadd4(
      .a(PC),
      .b({WIDTH{1'b0}} + 4),
      .y(PCPlus4)
  );

  adder pcaddbranch(
      .a(PC),
      .b(ImmExt),
      .y(PCTarget)
  );

  mux2 #(WIDTH) pcmux(
      .d0(PCPlus4),
      .d1(PCTarget),
      .s(PCSrc),
      .y(PCNext)
  );

// =======================
// IF/ID REGISTER
// =======================
  IF_ID IFID (
      .clk(clk),
      .reset(reset),

      // Hazard
      .stallD(1'b0),
      .flushD(1'b0),

      // Input
      .InstrF(Instr),
      .PCF(PC),
      .PCPlus4F(PCPlus4),

      // Output
      .InstrD(InstrD),
      .PCD(PCD),
      .PCPlus4D(PCPlus4D)
  );




// =======================
// ID STAGE
// =======================
wire[4:0] Rs1D = InstrD[19:15];
wire[4:0] Rs2D = InstrD[24:20];
wire [4:0] RdD = InstrD[11:7];

stalling stallunit(

  // Input
  .Rs1D(Rs1D),
  .Rs2D(Rs2D),
  .RdE(RdE),
  .ResultSrcE(ResultSrcE[0]),

  // Output - Hazard
  .lwStall(lwStall),
  .StallF(StallF),
  .StallD(StallD),
  .FlushE(FlushE)

);


regfile rf(

    // Input
    .clk(clk),
    .we3(RegWriteW),
    .a1(Rs1D),
    .a2(Rs2D),
    .a3(RdW),
    .wd3(Result),

    // Output
    .rd1(SrcA),
    .rd2(WriteData)
    
);

extend ext(
    .instr(InstrD[31:7]),
    .immsrc(ImmSrc),
    .immext(ImmExt)
);

// Rs1D y Rs2D para forwarding
ID_EX IDEX (
    .clk(clk),
    .reset(reset),

    // Control Input
    .RegWriteD(RegWrite),
    .MemWriteD(MemWrite),
    .ALUSrcD(ALUSrc),
    .ResultSrcD(ResultSrc),
    .ALUControlD(ALUControl),

    // Data Input
    .RD1D(SrcA),
    .RD2D(WriteData), // write data actua como RD2D
    .ImmExtD(ImmExt),
    .PCD(PCD),
    .PCPlus4D(PCPlus4D),
    .Rs1D(Rs1D),
    .Rs2D(Rs2D),
    .RdD(RdD),

    // Hazard
    .FlushE(1'b0),

    // Control Output
    .RegWriteE(RegWriteE),
    .MemWriteE(MemWriteE),
    .ALUSrcE(ALUSrcE),
    .ResultSrcE(ResultSrcE),
    .ALUControlE(ALUControlE),

    // Data Output
    .RD1E(RD1E),
    .RD2E(RD2E),
    .ImmExtE(ImmExtE),
    .PCE(PCE),
    .PCPlus4E(PCPlus4E),
    .Rs1E(Rs1E),
    .Rs2E(Rs2E),
    .RdE(RdE)
);

// =======================
// EX STAGE
// =======================
wire [31:0] ScrA_df, ScrB_df;

dataforwaring forwaring1(.Rs1E(Rs1E), .Rs2E(Rs2E),
                         .RdM(RdM), .RdW(RdW),
                         .RegWriteM(RegWriteM), .RegWriteW(RegWriteW),
                         .forwardAE(forwardAE), .forwardBE(forwardBE));


mux_df scra_df(.forward(2'b00),
              .data_in(RD1E), .AluResultM(ALUResultM), .ResultW(Result),
              .data_out(ScrA_df)
);

mux_df scrb_df(.forward(2'b00),
              .data_in(RD2E), .AluResultM(ALUResultM), .ResultW(Result),
              .data_out(ScrB_df)
);


/*
always @(*) begin
    $display("----- PIPELINE DATA HAZARD -----");
    
    $display("[ForwardA] Rs1E=%02h  RdM=%02h  RdW=%02h  RegWriteM=%b  RegWriteW=%b  => fA=%b",
             Rs1E, RdM, RdW, RegWriteM, RegWriteW, forwardAE);
             
    $display("[ForwardB] Rs2E=%02h  RdM=%02h  RdW=%02h  RegWriteM=%b  RegWriteW=%b  => fB=%b",
             Rs2E, RdM, RdW, RegWriteM, RegWriteW, forwardBE);
end
*/

mux2 #(WIDTH) srcbmux(
    .d0(ScrB_df),
    .d1(ImmExtE),
    .s(ALUSrcE),
    .y(SrcB)
);

alu alu(
    .a(ScrA_df),
    .b(SrcB),
    .alucontrol(ALUControlE),
    .result(ALUResult),
    .zero(Zero)
);

// Control Hazard
assign FlushD = PCSrc;
assign FlushE = lwStall | PCSrc;

// =======================
// EX/MEM REGISTER
// =======================
EX_MEM EXMEM (
    .clk(clk),
    .reset(reset),

    // Control Input
    .RegWriteE(RegWriteE),
    .MemWriteE(MemWriteE),
    .ResultSrcE(ResultSrcE),

    // Data Input
    .ALUResultE(ALUResult),
    .WriteDataE(ScrB_df),
    .PCPlus4E(PCPlus4E),
    .RdE(RdE),

    // Control Output
    .RegWriteM(RegWriteM),
    .MemWriteM(MemWriteM),
    .ResultSrcM(ResultSrcM),

    // Data Output
    .ALUResultM(ALUResultM),
    .WriteDataM(WriteDataM),
    .PCPlus4M(PCPlus4M),
    .RdM(RdM)
);

// =======================
// MEM/WB REGISTER
// =======================
MEM_WB MEMWB (
    .clk(clk),
    .reset(reset),

    // Control Input
    .RegWriteM(RegWriteM),
    .ResultSrcM(ResultSrcM),

    // Data Input
    .ALUResultM(ALUResultM),
    .ReadDataM(ReadData),
    .PCPlus4M(PCPlus4M),
    .RdM(RdM),

    // Control Output
    .RegWriteW(RegWriteW),
    .ResultSrcW(ResultSrcW),

    // Data Output
    .ALUResultW(ALUResultW),
    .ReadDataW(ReadDataW),
    .PCPlus4W(PCPlus4W),
    .RdW(RdW)
);

// =======================
// WB STAGE
// =======================
mux3 #(WIDTH) resultmux (
    .d0(ALUResultW),
    .d1(ReadDataW),
    .d2(PCPlus4W),
    .s(ResultSrcW),
    .y(Result)
);



always @(*) begin
    $display("Result: %h", Result);
end



endmodule