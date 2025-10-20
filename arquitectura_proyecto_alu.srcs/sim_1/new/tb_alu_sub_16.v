`timescale 1ns/1ps

module tb_alu_sub_16;

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

    op = 2'b01; // Operación: multiplicación

    // =======================
    // TEST 1 :
    // =======================

    a = 16'b0100101100010000; // 14.125
    b = 16'b0100101000011111; // 12.24
    expected = 16'b0011111110001000; // 1.8828
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

    a = 16'b0100100010101000; // ≈ 9.3123123
    b = 16'b0000000010101000; // ≈ 1e-05
    expected = 16'b0100100010101000; // 9.3125
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

    a = 16'b1010111111100111; // ≈ -0.123456789
    b = 16'b1011101111100111; // ≈ -0.987654321
    expected = 16'b0011101011101010; // 0.8642578125
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

    a = 16'b0011110000010101; // ≈ 1.0205
    b = 16'b0110010001000100; // ≈ 1.092e+03
    expected = 16'b1110010001000011; // -1091.0
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

    a = 16'b1101101100110001; // ≈ -230.1
    b = 16'b0001010100001110; // ≈ 0.001234
    expected = 16'b1101101100110001; // -230.125
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

    a = 16'b0011110010000100; // ≈ 1.129
    b = 16'b0011101111111110; // ≈ 0.999
    expected = 16'b0011000000101000; // 0.12988
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


    $finish;

  end

endmodule
