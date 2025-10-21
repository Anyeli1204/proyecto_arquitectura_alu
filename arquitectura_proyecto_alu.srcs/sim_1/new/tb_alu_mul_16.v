`timescale 1ns/1ps

module tb_alu_mul_16;

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

    op = 2'b10; // Operación: multiplicación

    // =======================
    // TEST 1:
    // =======================
    a = 16'b0101101110000100; // 240.5
    b = 16'b0001000011001111; // 0.00058698
    expected = 16'b0011000010000100; // 0.1660
    expectedFlags = 5'b00000; 

    #10;
    if (y == expected)
      $display("✅ Test 1 OK: 240.5 * 0.00058698 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 1 FAIL: 240.5 * 0.00058698 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b\n", ALUFlags);
    else
      $display(" ❌ Flags FAIL: %b\n", ALUFlags);

    #10;

    // =======================
    // TEST 2:
    // =======================
    a = 16'b0100101000111010; // 12.45
    b = 16'b0110010011001000; // 1.224e+03
    expected = 16'b0111001101110001; // 15240.0
    expectedFlags = 5'b00000; 

    #10;
    if (y == expected)
      $display("✅ Test 2 OK: 12.45 * 1.224e+03 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 2 FAIL: 12.45 * 1.224e+03 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b\n", ALUFlags);
    else
      $display(" ❌ Flags FAIL: %b\n", ALUFlags);

    #10;

    // =======================
    // TEST 3: OVERFLOW + INEXACT
    // =======================
    a = 16'b0110010101000001; // 1345.123
    b = 16'b0110010001100011; // 1123.111
    expected = 16'b00111110000000000; // 15240.0
    expectedFlags = 5'b00101; 

    #10;
    if (y == expected)
      $display("✅ Test 3 OK: 12.45 * 1.224e+03 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 3 FAIL: 12.45 * 1.224e+03 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b\n", ALUFlags);
    else
      $display(" ❌ Flags FAIL: %b\n", ALUFlags);

    #10;

    // =======================
    // TEST 4: UNDERFLOW + INEXACT
    // =======================
    a = 16'b0000000001000000; // 0.00123
    b = 16'b0000000001100000; // 0.000001
    expected = 16'b0000000000000000; // 0.0 <- UnderFlow
    expectedFlags = 5'b00011; 

    #10;
    if (y == expected)
      $display("✅ Test 4 OK: 0.00123 * 0.000001 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 4 FAIL: 0.00123 * 0.000001 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: expectedFlags: %b, %b\n", expectedFlags, ALUFlags);
    else
      $display(" ❌ Flags FAIL: expectedFlags: %b, %b\n", expectedFlags, ALUFlags);

    #10;

    // =======================
    // TEST 4: NAN
    // =======================
    a = 16'b0111110001000000; // NaN
    b = 16'b0011110000000000; // 0.000001
    expected = 16'b0111111000000000; // 0.0
    expectedFlags = 5'b10000; 

    #10;
    if (y == expected)
      $display("✅ Test 4 OK: NaN * 0.000001 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 4 FAIL: NaN * 0.000001 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: expectedFlags: %b, %b\n", expectedFlags, ALUFlags);
    else
      $display(" ❌ Flags FAIL: expectedFlags: %b, %b\n", expectedFlags, ALUFlags);

    #10;
    
    // =======================
    // TEST 4: Number * 0.0
    // =======================
    a = 16'b0_11001_0001101000; // Number
    b = 16'b0_00000_0000000000; // 0.0
    expected = 16'b0_00000_0000000000; // 0.0
    expectedFlags = 5'b00000; 

    #10;
    if (y == expected)
      $display("✅ Test 5 OK: Number * 0.0 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 5 FAIL: Number * 0.0 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: expectedFlags: %b, %b\n", expectedFlags, ALUFlags);
    else
      $display(" ❌ Flags FAIL: expectedFlags: %b, %b\n", expectedFlags, ALUFlags);

    #10;

    // =======================
    // TEST 4: 0.0 * 0.0
    // =======================
    a = 16'b0_00000_0000000000; // Number
    b = 16'b0_00000_0000000000; // 0.0
    expected = 16'b0_00000_0000000000; // 0.0
    expectedFlags = 5'b00000; 

    #10;
    if (y == expected)
      $display("✅ Test 6 OK: 0.0 * 0.0 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 6 FAIL: 0.0 * 0.0 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: expectedFlags: %b, %b\n", expectedFlags, ALUFlags);
    else
      $display(" ❌ Flags FAIL: expectedFlags: %b, %b\n", expectedFlags, ALUFlags);

    #10;

    $finish;
  end

endmodule
