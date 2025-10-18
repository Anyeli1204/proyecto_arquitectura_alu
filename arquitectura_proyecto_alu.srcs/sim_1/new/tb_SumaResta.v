`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.10.2025 10:53:17
// Design Name: 
// Module Name: tb_SumaResta
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns/1ps

module tb_Suma16Bits_flags_bin;
  reg  [15:0] A, B;
  wire [15:0] F;
  wire overflow, underflow, inv_op, inexact;

  // DUT
  Suma16Bits dut (
    .S(A), .R(B), .F(F),
    .overflow(overflow), .underflow(underflow),
    .inv_op(inv_op), .inexact(inexact)
  );

  // -------- Half-precision en binario --------
  // s eeeee ffffffffff
  localparam [15:0] HP_Z     = 16'b0_00000_0000000000; // +0
  localparam [15:0] HP_ONE   = 16'b0_01111_0000000000; //  1.0
  localparam [15:0] HP_ONEP5 = 16'b0_01111_1000000000; //  1.5
  localparam [15:0] HP_TWO   = 16'b0_10000_0000000000; //  2.0
  localparam [15:0] HP_MAXF  = 16'b0_11110_1111111111; //  max finito
  localparam [15:0] HP_INF   = 16'b0_11111_0000000000; //  +Inf
  // 0.500488..., LSB=1 para forzar inexact al alinear
  localparam [15:0] HP_HALF_LSB1 = 16'b0_01110_0000000001;

  integer fails;

  // ====== Tasks 100% Verilog-2001 (sin 'string') ======
  task show;
    input [8*64-1:0] name;  // hasta 64 chars
    begin
      $display("%0s", name);
      $display("  A=%b  B=%b  ->  F=%b  | ovf=%b unf=%b inv=%b inex=%b",
               A, B, F, overflow, underflow, inv_op, inexact);
    end
  endtask

  task check_y;
    input [15:0] exp;
    begin
      if (F !== exp) begin
        $display("  [FAIL] F got=%b exp=%b", F, exp);
        fails = fails + 1;
      end
    end
  endtask

  task check_flags;
    input ovf, input unf, input inv, input inex;
    begin
      if (overflow  !== ovf)  begin $display("  [FAIL] ovf got=%b exp=%b", overflow,  ovf);  fails=fails+1; end
      if (underflow !== unf)  begin $display("  [FAIL] unf got=%b exp=%b", underflow, unf);  fails=fails+1; end
      if (inv_op    !== inv)  begin $display("  [FAIL] inv got=%b exp=%b", inv_op,    inv);  fails=fails+1; end
      if (inexact   !== inex) begin $display("  [FAIL] inex got=%b exp=%b", inexact,   inex); fails=fails+1; end
    end
  endtask

  initial begin
    fails = 0;
    $display("===============================================================");
    $display("  TEST: Suma16Bits -> resultado y flags (overflow/underflow/inv/inexact)");
    $display("===============================================================\n");

    // 1) 1.0 + 1.0 = 2.0
    A=HP_ONE; B=HP_ONE; #2;
    show("Caso 1: 1.0 + 1.0");
    check_y(16'b0_10000_0000000000);     // 2.0
    check_flags(1'b0, 1'b0, 1'b0, 1'b0);

    // 2) 1.5 + 1.5 = 3.0 (carry -> normalize), sin overflow
    A=HP_ONEP5; B=HP_ONEP5; #2;
    show("Caso 2: 1.5 + 1.5");
    check_y(16'b0_10000_1000000000);     // 3.0
    check_flags(1'b0, 1'b0, 1'b0, 1'b0);

    // 3) 1.0 + 0.500488... -> inexact=1 por alineamiento
    A=HP_ONE; B=HP_HALF_LSB1; #2;
    show("Caso 3: 1.0 + 0.500488... (alineamiento con pérdida)");
    // F puede variar por redondeo: solo flags
    check_flags(1'b0, 1'b0, 1'b0, 1'b1);

    // 4) "SUB": 1.0 + (-1.0) = 0.0
    A=HP_ONE; B={1'b1, HP_ONE[14:0]}; #2; // -1.0
    show("Caso 4: 1.0 + (-1.0)  (SUB)");
    check_y(HP_Z);
    check_flags(1'b0, 1'b0, 1'b0, 1'b0);

    // 5) Overflow (max_finite + max_finite)
    A=HP_MAXF; B=HP_MAXF; #2;
    show("Caso 5: max_finite + max_finite  (overflow)");
    // Resultado puede saturar a patrón Inf/NaN; solo flags
    check_flags(1'b1, 1'b0, 1'b0, 1'b0);

    // 6) Entradas inválidas según helper: +Inf + +Inf => inv_op=1 (y overflow=1 por tu mapeo)
    A=HP_INF; B=HP_INF; #2;
    show("Caso 6: +Inf + +Inf  (inv_op=1, overflow=1 por mapeo)");
    check_flags(1'b1, 1'b0, 1'b1, 1'b0);

    $display("\n---- SUMMARY: %0d FAIL(s) ----", fails);
    if (fails != 0) $stop; else $finish;
  end
endmodule

