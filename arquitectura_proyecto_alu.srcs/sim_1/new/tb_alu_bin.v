`timescale 1ns/1ps

module tb_alu_bin;

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
    // TEST 1: División normal inexacta
    // =======================
    a = 16'b0_10001_0100111011; // ≈ 5.2315
    b = 16'b0_01000_1010011011; // ≈ 0.0129
    expected = 16'b0_10111_1001010110; // ≈ 405.5426
    expectedFlags = 5'b00001; 

    #10;
    if (y == expected)
      $display("✅ Test 1 OK: 5.2315 / 0.0129 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 1 FAIL: 5.2315 / 0.0129 => %b (esperado %b)", y, expected);
    #1;
    if (ALUFlags == expectedFlags)
      $display(" ✅ Flags OK: %b (esperado %b)\n", ALUFlags, expectedFlags);
    else
      $display(" ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

   
    $finish;
  end

endmodule
