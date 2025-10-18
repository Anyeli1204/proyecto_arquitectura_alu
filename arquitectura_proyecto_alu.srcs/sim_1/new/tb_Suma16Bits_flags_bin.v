`timescale 1ns/1ps

module tb_alu_special_cases;

  reg  [15:0] a, b;
  reg  [1:0]  op;
  wire [15:0] y;
  wire [4:0]  ALUFlags;  // {invalid, div_zero, overflow, underflow, inexact}

  alu dut(.a(a), .b(b), .op(op), .y(y), .ALUFlags(ALUFlags));

  // Valores especiales IEEE 754
  localparam [15:0]
    POS_ZERO = 16'h0000,
    NEG_ZERO = 16'h8000,
    POS_INF  = 16'h7C00,
    NEG_INF  = 16'hFC00,
    QNAN     = 16'h7E00,
    ONE      = 16'h3C00,
    TWO      = 16'h4000,
    DENORM   = 16'h0001;  // Número denormal mínimo

  localparam [1:0] OP_ADD = 2'b00, OP_SUB = 2'b01, OP_MUL = 2'b10, OP_DIV = 2'b11;

  integer passed, failed, total;
  
  task check(
    input [127:0] name,
    input [15:0] exp_y,
    input exp_invalid,
    input exp_div_zero,
    input exp_overflow
  );
    begin
      total = total + 1;
      #1;
      if (y !== exp_y || 
          ALUFlags[4] !== exp_invalid ||
          ALUFlags[3] !== exp_div_zero ||
          ALUFlags[2] !== exp_overflow) begin
        failed = failed + 1;
        $display("[FAIL] %s: y=%h (exp=%h) flags=%b (exp: I=%b DZ=%b OV=%b)", 
                 name, y, exp_y, ALUFlags, exp_invalid, exp_div_zero, exp_overflow);
      end else begin
        passed = passed + 1;
        $display("[PASS] %s", name);
      end
    end
  endtask

  initial begin
    passed = 0; failed = 0; total = 0;
    $display("=== TEST: Casos Especiales IEEE 754 ===\n");
    
    // ========== NaN PROPAGATION ==========
    $display("--- NaN Propagation ---");
    op = OP_ADD; a = QNAN; b = ONE; 
    check("NaN + 1", QNAN, 1, 0, 0);
    
    op = OP_MUL; a = QNAN; b = TWO;
    check("NaN * 2", QNAN, 1, 0, 0);
    
    op = OP_DIV; a = ONE; b = QNAN;
    check("1 / NaN", QNAN, 1, 0, 0);
    
    // ========== INFINITY OPERATIONS ==========
    $display("\n--- Infinity Operations ---");
    
    // Inf + Inf (mismo signo) = Inf (sin overflow, es resultado correcto)
    op = OP_ADD; a = POS_INF; b = POS_INF;
    check("Inf + Inf", POS_INF, 0, 0, 0);  // ? Sin overflow
    
    // Inf - Inf = NaN (INVALID)
    op = OP_SUB; a = POS_INF; b = POS_INF;
    check("Inf - Inf", QNAN, 1, 0, 0);
    
    // Inf + x = Inf (sin overflow)
    op = OP_ADD; a = POS_INF; b = ONE;
    check("Inf + 1", POS_INF, 0, 0, 0);  // ? Sin overflow
    
    // Inf * 0 = NaN (INVALID)
    op = OP_MUL; a = POS_INF; b = POS_ZERO;
    check("Inf * 0", QNAN, 1, 0, 0);
    
    // Inf * 2 = Inf (sin overflow)
    op = OP_MUL; a = POS_INF; b = TWO;
    check("Inf * 2", POS_INF, 0, 0, 0);  // ? Sin overflow
    
    // Inf / Inf = NaN (INVALID)
    op = OP_DIV; a = POS_INF; b = POS_INF;
    check("Inf / Inf", QNAN, 1, 0, 0);
    
    // Inf / 2 = Inf (sin overflow)
    op = OP_DIV; a = POS_INF; b = TWO;
    check("Inf / 2", POS_INF, 0, 0, 0);  // ? Sin overflow
    
    // 1 / Inf = 0
    op = OP_DIV; a = ONE; b = POS_INF;
    check("1 / Inf", POS_ZERO, 0, 0, 0);
    
    // ========== ZERO OPERATIONS ==========
    $display("\n--- Zero Operations ---");
    
    // 0 + 0 = +0
    op = OP_ADD; a = POS_ZERO; b = POS_ZERO;
    check("0 + 0", POS_ZERO, 0, 0, 0);
    
    // -0 + -0 = -0
    op = OP_ADD; a = NEG_ZERO; b = NEG_ZERO;
    check("-0 + -0", NEG_ZERO, 0, 0, 0);
    
    // 0 * 5 = 0
    op = OP_MUL; a = POS_ZERO; b = 16'h4500;  // 5.0
    check("0 * 5", POS_ZERO, 0, 0, 0);
    
    // 0 / 0 = NaN (INVALID)
    op = OP_DIV; a = POS_ZERO; b = POS_ZERO;
    check("0 / 0", QNAN, 1, 0, 0);
    
    // 1 / 0 = Inf (DIVIDE BY ZERO)
    op = OP_DIV; a = ONE; b = POS_ZERO;
    check("1 / 0", POS_INF, 0, 1, 0);
    
    // 0 / 1 = 0
    op = OP_DIV; a = POS_ZERO; b = ONE;
    check("0 / 1", POS_ZERO, 0, 0, 0);
    
    // ========== SIGNED ZEROS ==========
    $display("\n--- Signed Zeros ---");
    
    // -1 * 0 = -0
    op = OP_MUL; a = 16'hBC00; b = POS_ZERO;  // -1.0 * 0
    check("-1 * 0", NEG_ZERO, 0, 0, 0);
    
    // 1 / -0 = -Inf
    op = OP_DIV; a = ONE; b = NEG_ZERO;
    check("1 / -0", NEG_INF, 0, 1, 0);
    
    // ========== DENORMALS ==========
    $display("\n--- Denormals ---");
    
    // Denormal + 0 = Denormal
    op = OP_ADD; a = DENORM; b = POS_ZERO;
    check("denorm + 0", DENORM, 0, 0, 0);
    
    // ========== RESUMEN ==========
    $display("\n==========================================");
    $display("Total: %0d  Passed: %0d  Failed: %0d", total, passed, failed);
    if (failed == 0)
      $display(">>> ALL SPECIAL CASES PASSED! ?");
    else
      $display(">>> %0d SPECIAL CASES FAILED ?", failed);
    $display("==========================================");
    
    $finish;
  end

endmodule