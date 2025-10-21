`timescale 1ns/1ps

module tb_alu_sum_16;

  // Señales
  reg [15:0] a, b;
  reg [1:0] op;
  wire [15:0] y;
  wire [4:0]  ALUFlags;

  reg [15:0] expected;
  reg [4:0]  expectedFlags;

  // Instancia de la ALU con valid_out
  alu #( .system(16) ) DUT (
    .a(a),
    .b(b),
    .op(op),
    .y(y),
    .ALUFlags(ALUFlags)
  );

  initial begin
    $dumpfile("wave.vcd");   // Nombre del archivo de salida
    $dumpvars(0, tb_alu_sum_16); // Guardar todas las señales del testbench
  end

  initial begin

    op = 2'b00; // Operación: suma

    // =======================
    // TEST 1 :
    // =======================
    a = 16'b0100101100010000; // 14.125
    b = 16'b0100101000011111; // 12.24
    expected = 16'b0100111010011000; // 26.375
    expectedFlags = 5'b00000;

    #1;

    if (y == expected)
      $display("✅ Test 1 OK: 14.125 + 12.24 = 26.375 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 1 FAIL: 14.125 + 12.24 => %b (esperado %b)", y, expected);

    if (ALUFlags == expectedFlags)
      $display("   ✅ Flags OK: %b\n", ALUFlags);
    else
      $display("   ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    // =======================
    // TEST 2 :
    // =======================
    a = 16'b0100101000011111; // 12.24
    b = 16'b0100101100010000; // 14.125
    expected = 16'b0100111010011000; // 26.375
    expectedFlags = 5'b00000;

    #1;

    if (y == expected)
      $display("✅ Test 2 OK: 12.24 + 14.125 = 26.375 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 2 FAIL: 12.24 + 14.125 => %b (esperado %b)", y, expected);

    if (ALUFlags == expectedFlags)
      $display("   ✅ Flags OK: %b\n", ALUFlags);
    else
      $display("   ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    $finish;
  end

endmodule
