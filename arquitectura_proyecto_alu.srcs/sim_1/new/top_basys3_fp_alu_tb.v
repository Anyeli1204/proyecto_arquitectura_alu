`timescale 1ns/1ps

module top_basys3_fp_alu_tb();

  // Señales de entrada y salida del módulo principal
  reg         CLK100MHZ = 0;
  reg  [15:0] SW = 16'h0000;
  reg         BTNC = 0, BTNU = 0, BTND = 0, BTNL = 0, BTNR = 0;
  wire [15:0] LED;
  wire [3:0]  AN;
  wire        CA, CB, CC, CD, CE, CF, CG, DP;

  // Instancia del DUT (Device Under Test)
  top_basys3_fp_alu UUT (
    .CLK100MHZ(CLK100MHZ),
    .SW(SW),
    .BTNC(BTNC), .BTNU(BTNU), .BTND(BTND), .BTNL(BTNL), .BTNR(BTNR),
    .LED(LED), .AN(AN), .CA(CA), .CB(CB), .CC(CC), .CD(CD), .CE(CE), .CF(CF), .CG(CG), .DP(DP)
  );

  // Reloj 100 MHz
  always #5 CLK100MHZ = ~CLK100MHZ;

  // Constantes half y single
  localparam [15:0] HP_ONE   = 16'h3C00;
  localparam [15:0] HP_TWO   = 16'h4000;
  localparam [15:0] HP_THREE = 16'h4200;
  localparam [15:0] HP_THREEP5 = 16'h4300;
  localparam [15:0] HP_QTR   = 16'h3400;
  localparam [31:0] SP_ONE   = 32'h3F800000;
  localparam [31:0] SP_TWO   = 32'h40000000;
  localparam [31:0] SP_THREE = 32'h40400000;
  localparam [31:0] SP_TWOP5 = 32'h40200000;
  localparam [31:0] SP_SEVENP5 = 32'h40F00000;
  localparam [31:0] SP_POS0  = 32'h00000000;
  localparam [31:0] SP_PINF  = 32'h7F800000;

  // Variables auxiliares
  reg [15:0] hex16_lo, hex16_hi;
  integer i;

  initial begin
    
        // ======================================================
    // TEST 5: HALF NaN propagation
    // ======================================================
    $display("\nTEST 5: HALF NaN propagation");
    BTND=1; @(posedge CLK100MHZ); BTND=0; repeat(10) @(posedge CLK100MHZ);
    SW[11] = 0; // modo HALF

    // A = NaN (0_11111_0110111000)
    SW[8]  = 0;
    SW[15:0] = 16'b0111110110111000;
    BTNL=1; @(posedge CLK100MHZ); BTNL=0;
    BTNR=1; @(posedge CLK100MHZ); BTNR=0;

    // B = 2.0 (0_10000_0000000000)
    SW[8]  = 1;
    SW[15:0] = 16'b0100000000000000;
    BTNL=1; @(posedge CLK100MHZ); BTNL=0;
    BTNR=1; @(posedge CLK100MHZ); BTNR=0;

    // Operación = DIV
    SW[10:9] = 2'b11;
    BTNC=1; @(posedge CLK100MHZ); BTNC=0;
    repeat(50) @(posedge CLK100MHZ);

    // Verificar resultado esperado (NaN -> 0x7E00)
    if (LED == 16'h7E00)
      $display("✅ OK: NaN / 2 = 0x7E00 (NaN propagado)");
    else
      $display("❌ FAIL: NaN / 2 = %h (esperado 0x7E00)", LED);

    // Verificar banderas: invalid operation (bit 4) = 1
    if (UUT.ALUFlags == 5'b10000)
      $display("✅ Flags OK: %b (esperado 10000)\n", UUT.ALUFlags);
    else
      $display("❌ Flags FAIL: %b (esperado 10000)\n", UUT.ALUFlags);

    // ======================================================
    // TEST 6: HALF Division by Zero
    // ======================================================
    $display("\nTEST 6: HALF Division by Zero");
    BTND=1; @(posedge CLK100MHZ); BTND=0; repeat(10) @(posedge CLK100MHZ);
    SW[11] = 0; // modo HALF
    // A = 1.0
    SW[8] = 0;
    SW[15:0] = 16'b0011110000000000;
    BTNL=1; @(posedge CLK100MHZ); BTNL=0;
    BTNR=1; @(posedge CLK100MHZ); BTNR=0;
    // B = 0.0
    SW[8] = 1;
    SW[15:0] = 16'b0000000000000000;
    BTNL=1; @(posedge CLK100MHZ); BTNL=0;
    BTNR=1; @(posedge CLK100MHZ); BTNR=0;
    SW[10:9] = 2'b11;
    BTNC=1; @(posedge CLK100MHZ); BTNC=0;
    repeat(50) @(posedge CLK100MHZ);

    if (LED == 16'h7C00)
      $display("✅ OK: 1/0 = +INF (0x7C00)");
    else
      $display("❌ FAIL: 1/0 = %h (esperado 0x7C00)", LED);

    // Flags: divide by zero (bit 3)
    if (UUT.ALUFlags == 5'b01000)
      $display("✅ Flags OK: %b (esperado 01000)\n", UUT.ALUFlags);
    else
      $display("❌ Flags FAIL: %b (esperado 01000)\n", UUT.ALUFlags);

    // ======================================================
    // TEST 7: HALF Overflow
    // ======================================================
    $display("\nTEST 7: HALF Overflow (máx * 2)");
    BTND=1; @(posedge CLK100MHZ); BTND=0; repeat(10) @(posedge CLK100MHZ);
    SW[11] = 0;
    // A = máx número finito (0_11110_1111111111)
    SW[8] = 0;
    SW[15:0] = 16'b0111101111111111;
    BTNL=1; @(posedge CLK100MHZ); BTNL=0;
    BTNR=1; @(posedge CLK100MHZ); BTNR=0;
    // B = 2.0
    SW[8] = 1;
    SW[15:0] = 16'b0100000000000000;
    BTNL=1; @(posedge CLK100MHZ); BTNL=0;
    BTNR=1; @(posedge CLK100MHZ); BTNR=0;
    SW[10:9] = 2'b10; // MUL
    BTNC=1; @(posedge CLK100MHZ); BTNC=0;
    repeat(50) @(posedge CLK100MHZ);

    if (LED == 16'h7C00)
      $display("✅ OK: Overflow => +INF (0x7C00)");
    else
      $display("❌ FAIL: Overflow => %h (esperado 0x7C00)", LED);

    if (UUT.ALUFlags == 5'b00100)
      $display("✅ Flags OK: %b (esperado 00100)\n", UUT.ALUFlags);
    else
      $display("❌ Flags FAIL: %b (esperado 00100)\n", UUT.ALUFlags);

    // ======================================================
    // TEST 8: HALF Underflow (mín / 2)
    // ======================================================
    $display("\nTEST 8: HALF Underflow (mín / 2)");
    BTND=1; @(posedge CLK100MHZ); BTND=0; repeat(10) @(posedge CLK100MHZ);
    SW[11] = 0;
    // A = subnormal mínimo (0_00000_0000000001)
    SW[8] = 0;
    SW[15:0] = 16'b0000000000000001;
    BTNL=1; @(posedge CLK100MHZ); BTNL=0;
    BTNR=1; @(posedge CLK100MHZ); BTNR=0;
    // B = 2.0
    SW[8] = 1;
    SW[15:0] = 16'b0100000000000000;
    BTNL=1; @(posedge CLK100MHZ); BTNL=0;
    BTNR=1; @(posedge CLK100MHZ); BTNR=0;
    SW[10:9] = 2'b11; // DIV
    BTNC=1; @(posedge CLK100MHZ); BTNC=0;
    repeat(50) @(posedge CLK100MHZ);

    if (LED == 16'h0000)
      $display("✅ OK: Underflow => 0x0000");
    else
      $display("❌ FAIL: Underflow => %h (esperado 0x0000)", LED);

    if (UUT.ALUFlags == 5'b00010)
      $display("✅ Flags OK: %b (esperado 00010)\n", UUT.ALUFlags);
    else
      $display("❌ Flags FAIL: %b (esperado 00010)\n", UUT.ALUFlags);

    // ======================================================
    // TEST 9: HALF Inexact result
    // ======================================================
    $display("\nTEST 9: HALF Inexact (1 / 3)");
    BTND=1; @(posedge CLK100MHZ); BTND=0; repeat(10) @(posedge CLK100MHZ);
    SW[11] = 0;
    // A = 1.0
    SW[8] = 0; SW[15:0] = 16'b0011110000000000;
    BTNL=1; @(posedge CLK100MHZ); BTNL=0; BTNR=1; @(posedge CLK100MHZ); BTNR=0;
    // B = 3.0
    SW[8] = 1; SW[15:0] = 16'b0100001000000000;
    BTNL=1; @(posedge CLK100MHZ); BTNL=0; BTNR=1; @(posedge CLK100MHZ); BTNR=0;
    SW[10:9] = 2'b11;
    BTNC=1; @(posedge CLK100MHZ); BTNC=0;
    repeat(50) @(posedge CLK100MHZ);

    if (LED == 16'h3555)
      $display("✅ OK: 1/3 ≈ 0x3555");
    else
      $display("❌ FAIL: 1/3 = %h (esperado 0x3555)", LED);

    if (UUT.ALUFlags == 5'b00001)
      $display("✅ Flags OK: %b (esperado 00001)\n", UUT.ALUFlags);
    else
      $display("❌ Flags FAIL: %b (esperado 00001)\n", UUT.ALUFlags);


    $finish;
  end

endmodule
