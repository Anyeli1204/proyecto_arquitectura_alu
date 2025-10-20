`timescale 1ns/1ps

module tb_alu_div_32;

  // Señales
  reg [31:0] a, b;
  reg [1:0] op;
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

    op = 2'b11; // Operación: división

    // =======================
    // TEST 1:
    // =======================
    a = 32'b1_10000101_01001110110001001010001; // ≈ -83.6920
    b = 32'b0_01110100_10100110111010010111100; // ≈ 0.000806
    expected = 32'b1_10001111_10010101010010011100110; // ≈ -103836.228
    expectedFlags = 5'b00001; 

    #10;
    if (y == expected)
      $display("✅ Test 1 OK: -83.6920 / 0.000806 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 1 FAIL: -83.6920 / 0.000806 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b (esperado %b)\n", ALUFlags, expectedFlags);
    else
      $display(" ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    // =======================
    // TEST 2:
    // =======================
    a = 32'b0_10001000_00010011100001001001111; // ≈ 551.03607
    b = 32'b1_10000111_11110110100001110010101; // ≈ -502.52798
    expected = 32'b1_01111111_00011000101101100001001; // ≈ −1.09652
    expectedFlags = 5'b00001; 

    #10;
    if (y == expected)
      $display("✅ Test 2 OK: 551.03607 / -502.43524 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 2 FAIL: 551.03607 / -502.43524 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b (esperado %b)\n", ALUFlags, expectedFlags);
    else
      $display(" ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    // =======================
    // TEST 3 :
    // =======================
    a = 32'b0_01110100_11011011011001000110110; // ≈ 0.0009067
    b = 32'b0_01110100_10011001011001100110011; // ≈ 0.000780
    expected = 32'b0_01111111_00101001010000111110110; // ≈ 1.16119267
    expectedFlags = 5'b00001; 

    #10;
    if (y == expected)
      $display("✅ Test 3 OK:  0.0009067 / 0.000780 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 3 FAIL: 0.0009067 / 0.000780 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b (esperado %b)\n", ALUFlags, expectedFlags);
    else
      $display(" ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;
    
    // =======================
    // TEST 4 :
    // =======================
    a = 32'b0_10000101_10011000110101001111110; // ≈ 102.20799255371094
    b = 32'b0_01110011_11001001110100001101001; // ≈ 0.0004366
    expected = 32'b0_10010000_11001001001110000000011; // ≈ 234096.0499
    expectedFlags = 5'b00001; 

    #10;
    if (y == expected)
      $display("✅ Test 4 OK:  102.20799 / 0.0004366 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 4 FAIL: 102.20799 / 0.0004366 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b (esperado %b)\n", ALUFlags, expectedFlags);
    else
      $display(" ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    // =======================
    // TEST 5 : FLAG DIV BY ZERO
    // =======================
    a = 32'b0_01111111_00000000000000000000000; // 1.0
    b = 32'b0_00000000_00000000000000000000000; // 0.0
    expected = 32'b0_11111111_00000000000000000000000; // +INF
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
    a = 32'b0_11111111_00000000000000000000000; // +INF
    b = 32'b0_10000000_00000000000000000000000; // 2.0
    expected = 32'b0_11111111_00000000000000000000000; // +INF
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
    a = 32'b1_11111111_00000000000000000000000; // -INF
    b = 32'b0_10000000_00000000000000000000000; // 2.0
    expected = 32'b1_11111111_00000000000000000000000; // -INF
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
    a = 32'b0_11110110_11111011110100000000000; // ≈ 65000.0
    b = 32'b0_01110100_00000110010001011010001; // ≈ 0.001
    expected = 32'b0_11111111_00000000000000000000000; // +INF
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
    // TEST 9 : OVERFLOW CASO 2
    // =======================
    a = 32'b0_11111110_01110100000000000000000; // 11904
    b = 32'b0_01100001_01100000000000000000000; // 0.0001678
    expected = 32'b0_11111111_00000000000000000000000; // +INF
    expectedFlags = 5'b00101;

    #10;
    if (y == expected)
      $display("✅ Test 9 OK:  11904 / 0.0001678 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 9 FAIL: 11904 / 0.0001678 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b (esperado %b)\n", ALUFlags, expectedFlags);
    else
      $display(" ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    // =======================
    // TEST 10 : UNDERFLOW CASO 1
    // =======================
    a = 32'b0_00000000_00000000000000000000010; // 1e-7
    b = 32'b0_10000000_00000000000000000000000; // 2.0
    expected = 32'b0_11111111_00000000000000000000010; // +INF (underflow)
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
    // TEST 11 :
    // =======================
    a = 32'b0_01110001_01101110000101000111101; // 0.000087
    b = 32'b0_10011110_00011110001001001100110; // 2400347648
    expected = 32'b0_01010010_01000111100000111111000; // ≈ 3.6361 * 1e-14
    expectedFlags = 5'b00001;

    #10;
    if (y == expected)
      $display("✅ Test 11 OK:  0.00279 / 36659.2 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 11 FAIL: 0.00279 / 36659.2 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b (esperado %b)\n", ALUFlags, expectedFlags);
    else
      $display(" ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    // =======================
    // TEST 12 : NaN propagation
    // =======================
    a = 32'b0_11111111_01101110000000000000000; // NaN
    b = 32'b0_10000000_00000000000000000000000; // 2.0
    expected = 32'b0_11111111_10000000000000000000000; // NaN (propagated)
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

    $finish;
  end

endmodule
