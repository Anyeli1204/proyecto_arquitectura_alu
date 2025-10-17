`timescale 1ns/1ps

module tb_alu_mul_flags_bin;
  // DUT I/O
  reg  [15:0] a, b;
  reg  [1:0]  op;
  wire [15:0] y;
  wire [3:0]  ALUFlags; // {N,Z,C,V}

  // Instancia de tu ALU
  alu DUT (
    .a(a), .b(b),
    .op(op),
    .y(y),
    .ALUFlags(ALUFlags)
  );

  // ----------------- Constantes half (binario) -----------------
  // s eeeee ffffffffff
  localparam [15:0] HP_ONE    = 16'b0_01111_0000000000; //  1.0
  localparam [15:0] HP_ONEP5  = 16'b0_01111_1000000000; //  1.5
  localparam [15:0] HP_TWO    = 16'b0_10000_0000000000; //  2.0
  localparam [15:0] HP_THREE  = 16'b0_10000_1000000000; //  3.0
  localparam [15:0] HP_NTWO   = 16'b1_10000_0000000000; // -2.0
  localparam [15:0] HP_NTHREE = 16'b1_10000_1000000000; // -3.0

  // Máximo finito (no Inf/NaN)
  localparam [15:0] HP_MAXF   = 16'b0_11110_1111111111; // +65504
  localparam [15:0] HP_NMAXF  = 16'b1_11110_1111111111; // -65504

  integer fails;

  // --------------- Tarea de chequeo ----------------
  // flags_mask: bit=1 ? se verifica ese flag. Orden {N,Z,C,V}
  task run_vec;
    input [127:0] name;
    input [15:0] A, B;
    input        check_y;
    input [15:0] y_exp;
    input [3:0]  flags_mask;
    input [3:0]  flags_exp;
  begin
    a  = A;
    b  = B;
    op = 2'b10;     // MUL
    #2;             // propagación combinacional

    $display("%s", name);
    $display("  a=%b  b=%b  ->  y=%b  ALUFlags(NZCV)=%b", A, B, y, ALUFlags);

    if (check_y && (y !== y_exp)) begin
      $display("  [FAIL] y: got=%b exp=%b", y, y_exp);
      fails = fails + 1;
    end

    if (flags_mask[3] && (ALUFlags[3] !== flags_exp[3])) begin
      $display("  [FAIL] N: got=%b exp=%b", ALUFlags[3], flags_exp[3]);
      fails = fails + 1;
    end
    if (flags_mask[2] && (ALUFlags[2] !== flags_exp[2])) begin
      $display("  [FAIL] Z: got=%b exp=%b", ALUFlags[2], flags_exp[2]);
      fails = fails + 1;
    end
    if (flags_mask[1] && (ALUFlags[1] !== flags_exp[1])) begin
      $display("  [FAIL] C: got=%b exp=%b", ALUFlags[1], flags_exp[1]);
      fails = fails + 1;
    end
    if (flags_mask[0] && (ALUFlags[0] !== flags_exp[0])) begin
      $display("  [FAIL] V: got=%b exp=%b", ALUFlags[0], flags_exp[0]);
      fails = fails + 1;
    end

    $display("");
  end
  endtask

  initial begin
    fails = 0;
    $display("===============================================================");
    $display("     TEST: ALU MUL (binario) -> y y NZCV (C=inexact, V=overflow|invalid)");
    $display("===============================================================\n");

    // 0) 1.0 * 1.0 = 1.0  ? N=0,Z=0,C=0,V=0
    run_vec("Caso 0: 1.0 * 1.0",
            HP_ONE, HP_ONE,
            1'b1, 16'b0_01111_0000000000,
            4'b1111, 4'b0000);

    // 1) 1.5 * 2.0 = 3.0  ? N=0,Z=0,C=0,V=0
    run_vec("Caso 1: 1.5 * 2.0",
            HP_ONEP5, HP_TWO,
            1'b1, 16'b0_10000_1000000000,
            4'b1111, 4'b0000);

    // 2) (-2.0) * 1.5 = -3.0 ? N=1,Z=0,C=0,V=0
    run_vec("Caso 2: (-2.0) * 1.5",
            HP_NTWO, HP_ONEP5,
            1'b1, 16'b1_10000_1000000000,
            4'b1111, 4'b1000);

    // 3) Overflow positivo: max_finite * 2.0 ? V=1, N=0 (no chequeamos y ni C)
    run_vec("Caso 3: +Overflow  (max_finite * 2.0)",
            HP_MAXF, HP_TWO,
            1'b0, 16'b0,           // no chequeamos y
            4'b1001, 4'b0001);     // N y V: N=0, V=1

    // 4) Overflow negativo: (-max_finite) * 2.0 ? V=1, N=1
    run_vec("Caso 4: -Overflow  ((-max_finite) * 2.0)",
            HP_NMAXF, HP_TWO,
            1'b0, 16'b0,           // no chequeamos y
            4'b1001, 4'b1001);     // N=1, V=1

    $display("---- SUMMARY: %0d FAIL(s) ----", fails);
    if (fails != 0) $stop; else $finish;
  end
endmodule
