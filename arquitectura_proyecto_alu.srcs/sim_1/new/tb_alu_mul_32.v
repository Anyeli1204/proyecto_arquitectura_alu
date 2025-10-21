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
    b = 32'b1_10110011_00010001100011110101110; // 4812518371360768.0
    expected = 32'b1_11111111_00000000000000000000000; // ≈0.00784
    expectedFlags = 5'b00101; 

    #10;
    if (y == expected)
      $display("✅ Test 2 OK: 6.8303e+35 * 4812518371360768.0 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 2 FAIL: 6.8303e+35 * 4812518371360768.0 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b\n", ALUFlags);
    else
      $display(" ❌ Flags FAIL: %b\n", ALUFlags);

    #10;

    // =======================
    // TEST 3: UNDERFLOW + INEXACT
    // =======================

    a = 32'b0_01100000_00000111000110000000000; // 4.93 × 10⁻¹⁰
    b = 32'b1_00001100_00010001100011000101110; // −2.87 × 10⁻³⁵
    expected = 32'b1_00000000_00000000000000000000000; // 0 UnderFlow
    expectedFlags = 5'b00011; 

    #10;
    if (y == expected)
      $display("✅ Test 3 OK: 4.93 * 10⁻¹⁰ * -2.87 * 10⁻³⁵ => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 3 FAIL: 4.93 * 10⁻¹⁰ * -2.87 * 10⁻³⁵ => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b\n", ALUFlags);
    else
      $display(" ❌ Flags FAIL: %b\n", ALUFlags);

    #10;

    // =======================
    // TEST 4: NaN
    // =======================

    a = 32'b0_11111111_00000111000110000000000; // NaN
    b = 32'b1_00001100_00010001100011000101110; // −2.87 × 10⁻³⁵
    expected = 32'b01111111110000000000000000000000; // Inf
    expectedFlags = 5'b10000; 

    #10;
    if (y == expected)
      $display("✅ Test 4 OK: NaN * -2.87 * 10⁻³⁵ => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 4 FAIL: NaN * -2.87 * 10⁻³⁵ => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b\n", ALUFlags);
    else
      $display(" ❌ Flags FAIL: %b\n", ALUFlags);

    #10;

    // =======================
    // TEST 5: INF * -INF
    // =======================

    a = 32'b0_11111111_00000000000000000000000; // 4.93 × 10⁻¹⁰
    b = 32'b1_11111111_00000000000000000000000; // −2.87 × 10⁻³⁵
    expected = 32'b11111111100000000000000000000000; // 0 UnderFlow
    expectedFlags = 5'b00111; 

    #10;
    if (y == expected)
      $display("✅ Test 5 OK: +INF * -INF => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 5 FAIL: +INF * -INF => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b\n", ALUFlags);
    else
      $display(" ❌ Flags FAIL: %b\n", ALUFlags);

    #10;


    $finish;
  end

endmodule
