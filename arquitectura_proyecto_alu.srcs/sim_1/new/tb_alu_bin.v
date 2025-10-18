`timescale 1ns/1ps

module tb_alu_bin;

  reg  [15:0] a, b;
  reg  [1:0]  op;
  wire [15:0] y;
  reg  [15:0] expected;
  wire [4:0]  ALUFlags;
  reg  [4:0]  expectedFlags;

  alu #( .system(16) ) DUT (
    .a(a),
    .b(b),
    .op(op),
    .y(y),
    .ALUFlags(ALUFlags)
  );

  initial begin
    
    // === TESTS DE RESTA (op = 2'b01) ===
    op = 2'b01;


    // Test 1: 1.5 - 1.0 = 0.5
a = 16'b0_01111_1000000000; // 1.5
b = 16'b0_01111_0000000000; // 1.0
expected = 16'b0_01110_0000000000; // 0.5
expectedFlags = 5'b00000;
#10;
if (y == expected)
  $display("✅ Test 1 OK: 1.5 - 1.0 => %b (esperado %b)", y, expected);
else
  $display("❌ Test 1 FAIL: 1.5 - 1.0 => %b (esperado %b)", y, expected);
#1;
if (ALUFlags == expectedFlags)
  $display("   ✅ Flags OK: %b\n", ALUFlags);
else
  $display("   ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

// Test 2: 2.0 - 1.5 = 0.5
a = 16'b0_10000_0000000000; // 2.0
b = 16'b0_01111_1000000000; // 1.5
expected = 16'b0_01110_0000000000; // 0.5
expectedFlags = 5'b00000;
#10;
if (y == expected)
  $display("✅ Test 2 OK: 2.0 - 1.5 => %b (esperado %b)", y, expected);
else
  $display("❌ Test 2 FAIL: 2.0 - 1.5 => %b (esperado %b)", y, expected);
#1;
if (ALUFlags == expectedFlags)
  $display("   ✅ Flags OK: %b\n", ALUFlags);
else
  $display("   ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

// Test 3: 1.0 - 2.0 = -1.0
a = 16'b0_01111_0000000000; // 1.0
b = 16'b0_10000_0000000000; // 2.0
expected = 16'b1_01111_0000000000; // -1.0
expectedFlags = 5'b00000;
#10;
if (y == expected)
  $display("✅ Test 3 OK: 1.0 - 2.0 => %b (esperado %b)", y, expected);
else
  $display("❌ Test 3 FAIL: 1.0 - 2.0 => %b (esperado %b)", y, expected);
#1;
if (ALUFlags == expectedFlags)
  $display("   ✅ Flags OK: %b\n", ALUFlags);
else
  $display("   ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

// Test 4: -1.5 - (-1.0) = -0.5
a = 16'b1_01111_1000000000; // -1.5
b = 16'b1_01111_0000000000; // -1.0
expected = 16'b1_01110_0000000000; // -0.5
expectedFlags = 5'b00000;
#10;
if (y == expected)
  $display("✅ Test 4 OK: -1.5 - (-1.0) => %b (esperado %b)", y, expected);
else
  $display("❌ Test 4 FAIL: -1.5 - (-1.0) => %b (esperado %b)", y, expected);
#1;
if (ALUFlags == expectedFlags)
  $display("   ✅ Flags OK: %b\n", ALUFlags);
else
  $display("   ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

// Test 5: 0.0 - 1.0 = -1.0
a = 16'b0_00000_0000000000; // 0.0
b = 16'b0_01111_0000000000; // 1.0
expected = 16'b1_01111_0000000000; // -1.0
expectedFlags = 5'b00000;
#10;
if (y == expected)
  $display("✅ Test 5 OK: 0.0 - 1.0 => %b (esperado %b)", y, expected);
else
  $display("❌ Test 5 FAIL: 0.0 - 1.0 => %b (esperado %b)", y, expected);
#1;
if (ALUFlags == expectedFlags)
  $display("   ✅ Flags OK: %b\n", ALUFlags);
else
  $display("   ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

// Test 6: +Inf - +Inf = NaN
a = 16'b0_11111_0000000000; // +Inf
b = 16'b0_11111_0000000000; // +Inf
expected = 16'b0_11111_1000000000; // NaN
expectedFlags = 5'b10000; // invalid
#10;
if (y == expected)
  $display("✅ Test 6 OK: Inf - Inf => %b (esperado %b)", y, expected);
else
  $display("❌ Test 6 FAIL: Inf - Inf => %b (esperado %b)", y, expected);
#1;
if (ALUFlags == expectedFlags)
  $display("   ✅ Flags OK: %b\n", ALUFlags);
else
  $display("   ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

// Test 7: +Inf - (-Inf) = +Inf (overflow)
a = 16'b0_11111_0000000000; // +Inf
b = 16'b1_11111_0000000000; // -Inf
expected = 16'b0_11111_0000000000; // +Inf
expectedFlags = 5'b00100; // overflow
#10;
if (y == expected)
  $display("✅ Test 7 OK: Inf - (-Inf) => %b (esperado %b)", y, expected);
else
  $display("❌ Test 7 FAIL: Inf - (-Inf) => %b (esperado %b)", y, expected);
#1;
if (ALUFlags == expectedFlags)
  $display("   ✅ Flags OK: %b\n", ALUFlags);
else
  $display("   ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

// Test 8: -Inf - (+Inf) = -Inf (overflow)
a = 16'b1_11111_0000000000; // -Inf
b = 16'b0_11111_0000000000; // +Inf
expected = 16'b1_11111_0000000000; // -Inf
expectedFlags = 5'b00100; // overflow
#10;
if (y == expected)
  $display("✅ Test 8 OK: -Inf - (+Inf) => %b (esperado %b)", y, expected);
else
  $display("❌ Test 8 FAIL: -Inf - (+Inf) => %b (esperado %b)", y, expected);
#1;
if (ALUFlags == expectedFlags)
  $display("   ✅ Flags OK: %b\n", ALUFlags);
else
  $display("   ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

// Test 9: 1.0 - NaN = NaN
a = 16'b0_01111_0000000000; // 1.0
b = 16'b0_11111_1000000000; // NaN
expected = 16'b0_11111_1000000000; // NaN
expectedFlags = 5'b10000; // invalid
#10;
if (y == expected)
  $display("✅ Test 9 OK: 1.0 - NaN => %b (esperado %b)", y, expected);
else
  $display("❌ Test 9 FAIL: 1.0 - NaN => %b (esperado %b)", y, expected);
#1;
if (ALUFlags == expectedFlags)
  $display("   ✅ Flags OK: %b\n", ALUFlags);
else
  $display("   ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

// Test 10: 1e-5 - 1e-5 = 0.0 (underflow)
a = 16'b0_00110_0101101101; // ~1e-5
b = 16'b0_00110_0101101101; // ~1e-5
expected = 16'b0_00000_0000000000; // 0.0
expectedFlags = 5'b00010; // underflow
#10;
if (y == expected)
  $display("✅ Test 10 OK: 1e-5 - 1e-5 => %b (esperado %b)", y, expected);
else
  $display("❌ Test 10 FAIL: 1e-5 - 1e-5 => %b (esperado %b)", y, expected);
#1;
if (ALUFlags == expectedFlags)
  $display("   ✅ Flags OK: %b\n", ALUFlags);
else
  $display("   ❌ Flags FAIL: %b (esperado %b)\n", ALUFlags, expectedFlags);

    #10;
    $display("✅ Todos los tests de SUMA (32 bits) completados.\n");
    $finish;
  end

endmodule
