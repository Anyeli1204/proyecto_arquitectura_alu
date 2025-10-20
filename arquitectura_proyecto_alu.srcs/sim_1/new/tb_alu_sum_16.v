`timescale 1ns/1ps

module tb_alu_sum_16;

  // Señales
  reg [15:0] a, b;
  reg [1:0] op;
  wire [15:0] y;
  reg [15:0] expected;
  wire [4:0]  ALUFlags;
  reg [4:0] expectedFlags;

  // Instancia de la ALU 16 bits
  alu #( .system(16) ) DUT (
    .a(a),
    .b(b),
    .op(op),
    .y(y),
    .ALUFlags(ALUFlags)
  );

  initial begin

    op = 2'b00; // Operación: multiplicación

    // =======================
    // TEST 1 :
    // =======================

    a = 16'b0100101100010000; // 14.125
    b = 16'b0100101000011111; // 12.24
    expected = 16'b0100111010011000; // 26.375
    expectedFlags = 5'b00000;
    #10;
    if (y == expected)
      $display("✅ Test 1 OK: 14.125 + 12.24 = 26.375 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 1 FAIL: 14.125 + 12.24 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display("   ✅ Flags OK: %b\n", ALUFlags);
    else
      $display("   ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    // =======================
    // TEST 2 : INEXACT
    // =======================

    a = 16'b0100100010101000; // ≈ 9.3123123
    b = 16'b0000000010101000; // ≈ 1e-05
    expected = 16'b0100100010101000; // 9.3125
    expectedFlags = 5'b00001;
    #10;
    if (y == expected)
      $display("✅ Test 2 OK: 9.3123123 + 1e-05 = 9.3125 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 2 FAIL: 9.3123123 + 1e-05 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display("   ✅ Flags OK: %b\n", ALUFlags);
    else
      $display("   ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    // =======================
    // TEST 3 : INEXACT
    // =======================

    a = 16'b1010111111100111; // ≈ -0.123456789
    b = 16'b1011101111100111; // ≈ -0.987654321
    expected = 16'b1011110001110010; // -1.111328125
    expectedFlags = 5'b00001;
    #10;
    if (y == expected)
      $display("✅ Test 3 OK: -0.123456789 + -0.987654321 = -1.111328125 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 3 FAIL: -0.123456789 + -0.987654321 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display("   ✅ Flags OK: %b\n", ALUFlags);
    else
      $display("   ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

        // =======================
    // TEST 4 : +INF + 1.0
    // =======================
    a = 16'h7C00; // +Inf
    b = 16'h3C00; // +1.0
    expected = 16'h7C00; // +Inf
    expectedFlags = 5'b00101;
    #10;
    if (y == expected)
      $display("✅ Test 4 OK: +Inf + 1.0 = +Inf => %b", y);
    else
      $display("❌ Test 4 FAIL: +Inf + 1.0 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display("   ✅ Flags OK: %b\n", ALUFlags);
    else
      $display("   ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    // =======================
    // TEST 5 : -INF + 5.5
    // =======================
    a = 16'hFC00; // -Inf
    b = 16'h4B00; // 5.5
    expected = 16'hFC00; // -Inf
    expectedFlags = 5'b00011;
    #10;
    if (y == expected)
      $display("✅ Test 5 OK: -Inf + 5.5 = -Inf => %b", y);
    else
      $display("❌ Test 5 FAIL: -Inf + 5.5 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display("   ✅ Flags OK: %b\n", ALUFlags);
    else
      $display("   ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    // =======================
    // TEST 6 : +INF + -INF = NaN
    // =======================
    a = 16'h7C00; // +Inf
    b = 16'hFC00; // -Inf
    expected = 16'h7E00; // QNaN
    expectedFlags = 5'b00000; // Invalid operation
    #10;
    if (y == expected)
      $display("✅ Test 6 OK: +Inf + -Inf = NaN => %b", y);
    else
      $display("❌ Test 6 FAIL: +Inf + -Inf => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display("   ✅ Flags OK: %b\n", ALUFlags);
    else
      $display("   ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    // =======================
    // TEST 7 : NaN + 5.0 = NaN
    // =======================
    a = 16'h7E00; // QNaN
    b = 16'h4800; // 5.0
    expected = 16'h7E00; // QNaN (propagado)
    expectedFlags = 5'b10000;
    #10;
    if (y == expected)
      $display("✅ Test 7 OK: NaN + 5.0 = NaN => %b", y);
    else
      $display("❌ Test 7 FAIL: NaN + 5.0 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display("   ✅ Flags OK: %b\n", ALUFlags);
    else
      $display("   ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    $finish;
  end

endmodule
