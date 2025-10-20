`timescale 1ns/1ps

module tb_alu_sub_32;

  // Señales
  reg [31:0] a, b;
  reg [1:0] op;
  wire [31:0] y;
  reg [31:0] expected;
  wire [4:0]  ALUFlags;
  reg [4:0] expectedFlags;

  // Instancia de la ALU 16 bits
  alu #( .system(32) ) DUT (
    .a(a),
    .b(b),
    .op(op),
    .y(y),
    .ALUFlags(ALUFlags)
  );

  initial begin

    op = 2'b01; // Operación: multiplicación

    // =======================
    // TEST 1 :
    // =======================

    a = 32'b01000001011000100000000000000000; // 14.125
    b = 32'b01000001010000111101011100001010; // 12.24
    expected = 32'b00111111111100010100011110110000; // 1.8828
    expectedFlags = 5'b00000;
    #10;
    if (y == expected)
      $display("✅ Test 1 OK: 14.125 + 12.24 = 1.8828 => %b (esperado %b)", y, expected);
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

    a = 32'b01000001000101001111111100111011; // ≈ 9.3123123
    b = 32'b00110111001001111100010110101100; // ≈ 1e-05
    expected = 32'b01000001000101001111111100110001; // 9.3125
    expectedFlags = 5'b00001;
    #10;
    if (y == expected)
      $display("✅ Test 2 OK: 9.3123123 - 1e-05 = 9.3125 => %b (esperado %b)", y, expected);
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

    a = 32'b10111101111111001101011011101010; // ≈ -0.123456789
    b = 32'b10111111011111001101011011101010; // ≈ -0.987654321
    expected = 32'b00111111010111010011110000001101; // 0.8642578125
    expectedFlags = 5'b00001;
    #10;
    if (y == expected)
      $display("✅ Test 3 OK: -0.123456789 - (-0.987654321) = -1.111328125 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 3 FAIL: -0.123456789 + -0.987654321 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display("   ✅ Flags OK: %b\n", ALUFlags);
    else
      $display("   ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    // =======================
    // TEST 4 : INEXACT
    // =======================

    a = 32'b0_01111111_00000101001111110111110; // ≈ 1.0205
    b = 32'b0_10001001_00010001000000000000000; // ≈ 1.092e+03
    expected = 32'b1_10001001_00010000101111101011000; // -1090.9795
    expectedFlags = 5'b00001;
    #10;
    if (y == expected)
      $display("✅ Test 4 OK: 1.0205 - 1.092e+03 = -1091.0 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 4 FAIL: 1.0205 - 1.092e+03 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display("   ✅ Flags OK: %b\n", ALUFlags);
    else
      $display("   ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    // =======================
    // TEST 5 : INEXACT
    // =======================

    a = 32'b11000011011001100001100110011010; // ≈ -230.1
    b = 32'b00111010101000011011111000101011; // ≈ 0.001234
    expected = 32'b11000011011001100001100111101011; // -230.10124
    expectedFlags = 5'b00001;
    #10;
    if (y == expected)
      $display("✅ Test 5 OK: -230.1 - 0.001234 = -230.125 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 5 FAIL: -230.1 - 0.001234 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display("   ✅ Flags OK: %b\n", ALUFlags);
    else
      $display("   ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    // =======================
    // TEST 6 : INEXACT
    // =======================

    a = 32'b00111111100100001000001100010010; // ≈ 1.129
    b = 32'b00111111011111111100011001010100; // ≈ 0.99912
    expected = 32'b00111110000001001111111101000000; // 0.12988
    expectedFlags = 5'b00000;
    #10;
    if (y == expected)
      $display("✅ Test 6 OK: 1.129 - 0.999 = 0.12988 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 6 FAIL: 1.129 - 0.999 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display("   ✅ Flags OK: %b\n", ALUFlags);
    else
      $display("   ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

        // =======================
    // TEST 7 : +INF + 1.0
    // =======================
    a = 32'h7F800000; // +Inf
    b = 32'h3F800000; // +1.0
    expected = 32'h7F800000; // +Inf
    expectedFlags = 5'b00101;
    #10;
    if (y == expected)
      $display("✅ Test 7 OK: +Inf - 1.0 = +Inf => %b", y);
    else
      $display("❌ Test 7 FAIL: +Inf - 1.0 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display("   ✅ Flags OK: %b\n", ALUFlags);
    else
      $display("   ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    // =======================
    // TEST 8 : -INF + 5.5
    // =======================
    a = 32'hFF800000; // -Inf
    b = 32'h40B00000; // 5.5
    expected = 32'hFF800000; // -Inf
    expectedFlags = 5'b00011;
    #10;
    if (y == expected)
      $display("✅ Test 8 OK: -Inf - 5.5 = -Inf => %b", y);
    else
      $display("❌ Test 8 FAIL: -Inf - 5.5 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display("   ✅ Flags OK: %b\n", ALUFlags);
    else
      $display("   ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    // =======================
    // TEST 9 : +INF + -INF = NaN
    // =======================
    a = 32'h7F800000; // +Inf
    b = 32'hFF800000; // -Inf
    expected = 32'b0_11111111_00000000000000000000000; // QNaN
    expectedFlags = 5'b00111; // Invalid operation
    #10;
    if (y == expected)
      $display("✅ Test 9 OK: +Inf - -Inf = NaN => %b", y);
    else
      $display("❌ Test 9 FAIL: +Inf - -Inf => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display("   ✅ Flags OK: %b\n", ALUFlags);
    else
      $display("   ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    // =======================
    // TEST 10 : NaN + 5.0 = NaN
    // =======================
    a = 32'h7FC00000; // QNaN
    b = 32'h40A00000; // 5.0
    expected = 32'h7FC00000; // QNaN (propagado)
    expectedFlags = 5'b10000;
    #10;
    if (y == expected)
      $display("✅ Test 10 OK: NaN - 5.0 = NaN => %b", y);
    else
      $display("❌ Test 10 FAIL: NaN - 5.0 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display("   ✅ Flags OK: %b\n", ALUFlags);
    else
      $display("   ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;
     

    $finish;

  end

endmodule
