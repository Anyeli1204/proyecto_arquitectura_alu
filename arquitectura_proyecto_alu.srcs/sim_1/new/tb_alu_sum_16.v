`timescale 1ns/1ps

module tb_alu_sum_16;

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

    op = 2'b00; // Operación: multiplicación

    a = 32'b0_01111011_10011001100110011001101; // 0.1
    b = 32'b0_01111101_10011001100110011001101; // 0.2
    expected = 32'b0_01111110_00110011001100110011010; // 0.30000001
    expectedFlags = 5'b00001; // inexact
    #10;
    if (y == expected)
      $display("✅ Test 10 OK: 0.1 + 0.2 ≈ 0.30000001 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 10 FAIL: 0.1 + 0.2 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display("   ✅ Flags OK: %b\n", ALUFlags);
    else
      $display("   ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;

    $finish;
  end

endmodule
