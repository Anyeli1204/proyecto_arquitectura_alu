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
      $display("✅ Test 1 OK: 12.45 * 1.224e+03 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 1 FAIL: 12.45 * 1.224e+03 => %b (esperado %b)", y, expected);
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
      $display("✅ Test 1 OK: 12.45 * 1.224e+03 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 1 FAIL: 12.45 * 1.224e+03 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b\n", ALUFlags);
    else
      $display(" ❌ Flags FAIL: %b\n", ALUFlags);

    #10;



    $finish;
  end

endmodule
