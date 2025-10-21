`timescale 1ns/1ps

module tb_alu_div_16;

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

    op = 2'b11; // Operación: división

    // =======================
    // TEST 1:
    // =======================
    a = 16'b1_10001_0100111011; // ≈ -5.2315
    b = 16'b0_01000_1010011011; // ≈ 0.0129
    expected = 16'b1_10111_1001010110; // ≈ -405.5426
    expectedFlags = 5'b00001; 

    #10;
    if (y == expected)
      $display("✅ Test 1 OK: -5.2315 / 0.0129 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 1 FAIL: -5.2315 / 0.0129 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b (esperado %b)\n", ALUFlags, expectedFlags);
    else
      $display(" ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);
    
    #10;

    // =======================
    // TEST 2:
    // =======================
    a = 16'b0_11001_0001001110; // ≈ 1102.11944
    b = 16'b1_10111_1111011010; // ≈ -502.43524
    expected = 16'b1_10000_0001100011; // ≈ -2.19335
    expectedFlags = 5'b00001; 

    #10;
    if (y == expected)
      $display("✅ Test 2 OK: 1102.11944 / -502.43524 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 2 FAIL: 1102.11944 / -502.43524 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b (esperado %b)\n", ALUFlags, expectedFlags);
    else
      $display(" ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    // =======================
    // TEST 3 :
    // =======================
    a = 16'b0_01000_1101101101; // ≈ 0.0145
    b = 16'b0_01000_1001100101; // ≈ 0.01249
    expected = 16'b0_01111_0010100101; // ≈ 1.1609
    expectedFlags = 5'b00001; 

    #10;
    if (y == expected)
      $display("✅ Test 3 OK:  0.0145 / 0.01249 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 3 FAIL: 0.0145 / 0.01249 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b (esperado %b)\n", ALUFlags, expectedFlags);
    else
      $display(" ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;
    
    // =======================
    // TEST 4 :
    // =======================
    a = 16'b0_10101_1001100011; // ≈ 102.19
    b = 16'b0_01100_1100100111; // ≈ 0.223454
    expected = 16'b0_10111_1100100101; // ≈ 457.25
    expectedFlags = 5'b00001; 

    #10;
    if (y == expected)
      $display("✅ Test 4 OK:  102.19 / 0.223454 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 4 FAIL: 102.19 / 0.223454 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b (esperado %b)\n", ALUFlags, expectedFlags);
    else
      $display(" ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    // =======================
    // TEST 5 : FLAG DIV BY ZERO
    // =======================
    a = 16'b0_01111_0000000000; // ≈ 1
    b = 16'b0_00000_0000000000; // ≈ 0
    expected = 16'b0_11111_0000000000; // ≈ 457.25
    expectedFlags = 5'b01010; 

    #10;
    if (y == expected)
      $display("✅ Test 5 OK:  1 / 0 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 5 FAIL: 1 / 0 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b (esperado %b)\n", ALUFlags, expectedFlags);
    else
      $display(" ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    // =======================
    // TEST 6 : FLAG OVERFLOW + INF
    // =======================
    a = 16'b0_11111_0000000000; // +INF
    b = 16'b0_10000_0000000000; // 2.0
    expected = 16'b0_11111_0000000000; // ≈ INF
    expectedFlags = 5'b00101; 

    #10;
    if (y == expected)
      $display("✅ Test 6 OK:  INF / 2 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 6 FAIL: INF / 2 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b (esperado %b)\n", ALUFlags, expectedFlags);
    else
      $display(" ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    // =======================
    // TEST 7 : FLAG UNDERFLOW + NEG INF
    // =======================
    a = 16'b1_11111_0000000000; // -INF
    b = 16'b0_10000_0000000000; // 2.0
    expected = 16'b1_11111_0000000000; // ≈ INF
    expectedFlags = 5'b00011; 

    #10;
    if (y == expected)
      $display("✅ Test 7 OK:  -INF / 2 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 7 FAIL: -INF / 2 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b (esperado %b)\n", ALUFlags, expectedFlags);
    else
      $display(" ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    // =======================
    // TEST 8 : OVERFLOW CASO 1
    // =======================
    a = 16'b0_11110_1111101111; // 65000.0
    b = 16'b0_00101_0000011001; // 0.001
    expected = 16'b0111110000000000; // ≈ INF
    expectedFlags = 5'b00101;

    #10;
    if (y == expected)
      $display("✅ Test 8 OK:  65000 / 0.001 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 8 FAIL: 65000 / 0.001 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b (esperado %b)\n", ALUFlags, expectedFlags);
    else
      $display(" ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    // =======================
    // TEST 9 : OVERFLOW CASO 1
    // =======================
    a = 16'b0_11100_0111010000; // 11904
    b = 16'b0_00010_0110000000; // 0.0001678
    expected = 16'b0111110000000000; // ≈ INF
    expectedFlags = 5'b00101;

    #10;
    if (y == expected)
      $display("✅ Test 9 OK:  65000 / 0.001 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 9 FAIL: 65000 / 0.001 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b (esperado %b)\n", ALUFlags, expectedFlags);
    else
      $display(" ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    // =======================
    // TEST 10 : UNDERFLOW CASO 1
    // =======================
    a = 16'b0_00000_0000000010; // 1e-7
    b = 16'b0_10000_0000000000; // 2
    expected = 16'b0_00000_0000000000; // ≈ INF
    expectedFlags = 5'b00011;

    #10;
    if (y == expected)
      $display("✅ Test 10 OK:  1e-7 / 2 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 10 FAIL: 1e-7 / 2 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b (esperado %b)\n", ALUFlags, expectedFlags);
    else
      $display(" ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    // =======================
    // TEST 11 : UNDERFLOW CASO 2
    // =======================
    a = 16'b0_00110_0110111000; // 0.00279
    b = 16'b0_11110_0001111000; // 36659.2
    expected = 16'b0_00000_0000000000; // ≈ INF
    expectedFlags = 5'b00011;

    #10;
    if (y == expected)
      $display("✅ Test 11 OK:  1e-7 / 2 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 11 FAIL: 1e-7 / 2 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b (esperado %b)\n", ALUFlags, expectedFlags);
    else
      $display(" ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    // =======================
    // TEST 12 : NaN propagation
    // =======================
    a = 16'b0_11111_0110111000; // NaN
    b = 16'b0_10111_0000000000; // 2
    expected = 16'b0_111111_000000000; // ≈ INF
    expectedFlags = 5'b10000;

    #10;
    if (y == expected)
      $display("✅ Test 12 OK:  NaN / 2 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 12 FAIL: NaN / 2 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b (esperado %b)\n", ALUFlags, expectedFlags);
    else
      $display(" ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    // =======================
    // TEST 12 : NaN propagation
    // =======================
    a = 16'b0_11011_0110111000; // 5873.28
    b = 16'b0_00000_0000000000; // 0.0
    expected = 16'b0_11111_0000000000; // ≈ INF
    expectedFlags = 5'b01010;

    #10;
    if (y == expected)
      $display("✅ Test 12 OK:  5873.28 / 0 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 12 FAIL: 5873.28 / 0 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b (esperado %b)\n", ALUFlags, expectedFlags);
    else
      $display(" ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    // =======================
    // TEST 13 : 0/0
    // =======================
    a = 16'b0_00000_0000000000; // 0.0
    b = 16'b0_00000_0000000000; // 0.0
    expected = 16'b0_00000_0000000000; // ≈ NaN
    expectedFlags = 5'b10000;

    #10;
    if (y == expected)
      $display("✅ Test 13 OK:  0 / 0 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 13 FAIL: 0 / 0 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b (esperado %b)\n", ALUFlags, expectedFlags);
    else
      $display(" ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    // =======================
    // TEST 13 : 0 / Number
    // =======================
    a = 16'b0_00000_0000000000; // 0.0
    b = 16'b0_11110_0011110010; // Number
    expected = 16'b0_00000_0000000000; // ≈ 0
    expectedFlags = 5'b00000;

    #10;
    if (y == expected)
      $display("✅ Test 14 OK:  0 / Number => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 14 FAIL: 0 / Number => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b (esperado %b)\n", ALUFlags, expectedFlags);
    else
      $display(" ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    // =======================
    // TEST 13 : INF/0
    // =======================
    a = 16'b0_11111_0000000000; // INF
    b = 16'b1_00000_0000000000; // 0.0
    expected = 16'b1111110000000000; // ≈ INF
    expectedFlags = 5'b0100;

    #10;
    if (y == expected)
      $display("✅ Test 13 OK:  INF / 0 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 13 FAIL: INF / 0 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b (esperado %b)\n", ALUFlags, expectedFlags);
    else
      $display(" ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    $finish;
  end

endmodule
