`timescale 1ns/1ps

module tb_alu_bin;

  // Señales
  reg [15:0] a, b;
  reg [1:0] op;
  wire [15:0] y;
  reg [15:0] expected;

  // Instancia de la ALU
  alu DUT (
    .a(a),
    .b(b),
    .op(op),
    .y(y)
  );

  initial begin
    op = 2'b11; // código de operación: división

    // ===== Prueba 1: 4.0 / 2.0 = 2.0 =====
    a = 16'b0100010000000000; // 4.0
    b = 16'b0100000000000000; // 2.0
    expected = 16'b0100000000000000; // 2.0
    #10;
    if (y == expected)
      $display("✅ Test 1 OK: 4.0 / 2.0 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 1 FAIL: 4.0 / 2.0 => %b (esperado %b)", y, expected);

    // ===== Prueba 2: 5.0 / 2.0 = 2.5 =====
    a = 16'b0100010100000000; // 5.0
    b = 16'b0100000000000000; // 2.0
    expected = 16'b0100000100000000; // 2.5
    #10;
    if (y == expected)
      $display("✅ Test 2 OK: 5.0 / 2.0 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 2 FAIL: 5.0 / 2.0 => %b (esperado %b)", y, expected);

    // ===== Prueba 3: 3.0 / 3.0 = 1.0 =====
    a = 16'b0100001000000000; // 3.0
    b = 16'b0100001000000000; // 3.0
    expected = 16'b0011110000000000; // 1.0
    #10;
    if (y == expected)
      $display("✅ Test 3 OK: 3.0 / 3.0 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 3 FAIL: 3.0 / 3.0 => %b (esperado %b)", y, expected);

    // ===== Prueba 4: 1.0 / 2.0 = 0.5 =====
    a = 16'b0011110000000000; // 1.0
    b = 16'b0100000000000000; // 2.0
    expected = 16'b0011100000000000; // 0.5
    #10;
    if (y == expected)
      $display("✅ Test 4 OK: 1.0 / 2.0 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 4 FAIL: 1.0 / 2.0 => %b (esperado %b)", y, expected);

    // ===== Prueba 5: 5.0 / 5.0 = 1.0 =====
    a = 16'b0100010100000000; // 5.0
    b = 16'b0100010100000000; // 5.0
    expected = 16'b0011110000000000; // 1.0
    #10;
    if (y == expected)
      $display("✅ Test 5 OK: 5.0 / 5.0 => %b (esperado %b)", y, expected);
    else
      $display("❌ Test 5 FAIL: 5.0 / 5.0 => %b (esperado %b)", y, expected);

    $finish;
  end

endmodule
