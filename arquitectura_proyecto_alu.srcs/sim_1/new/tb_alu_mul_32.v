`timescale 1ns/1ps

module tb_alu_mul_32;

  // Señales
  reg [31:0] a, b;
  reg [1:0]  op;
  wire [31:0] y;
  reg [31:0] expected;
  wire [4:0] ALUFlags;
  reg [4:0] expectedFlags;

  // Instancia de la ALU 32 bits
  alu #( .system(32) ) DUT (
    .a(a),
    .b(b),
    .op(op),
    .y(y),
    .ALUFlags(ALUFlags)
  );

  initial begin

    op = 2'b10; // Operación: multiplicación

    // =======================
    // TEST 1:
    // =======================

    a = 32'b0_10000110_11100001000000000000000; // 240.5
    b = 32'b0_01110000_00010001101000110101010; // 3.262019e-05
    expected = 32'b0_011110_0000000001000100011111000; // ≈0.00784
    expectedFlags = 5'b00000; 

    #10;
    if (y == expected)
      $display("✅ Test 1 OK: 240.5 * 3.262019e-05 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 1 FAIL: 240.5 * 3.262019e-05 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b\n", ALUFlags);
    else
      $display(" ❌ Flags FAIL: %b\n", ALUFlags);

    #10;

    op = 2'b10; // Operación: multiplicación

    // =======================
    // TEST 2: OVERFLOW + INEXACT
    // =======================

    a = 32'b0_11110110_00000111000110000000000; // 6.830304258125737e+35
    b = 32'b0_10110011_00010001100011110101110; // 4812518371360768.0
    expected = 32'b0_11111111_00000000000000000000000; // ≈0.00784
    expectedFlags = 5'b00101; 

    #10;
    if (y == expected)
      $display("✅ Test 1 OK: 6.8303e+35 * 4812518371360768.0 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 1 FAIL: 6.8303e+35 * 4812518371360768.0 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b\n", ALUFlags);
    else
      $display(" ❌ Flags FAIL: %b\n", ALUFlags);

    #10;

    $finish;
  end

endmodule
