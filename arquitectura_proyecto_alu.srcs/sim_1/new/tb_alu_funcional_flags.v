`timescale 1ns/1ps

module tb_alu_hp_bin;

  // DUT I/O
  reg  [15:0] a, b;
  reg  [1:0]  op;
  wire [15:0] y;
  wire [3:0]  ALUFlags; // {N,Z,C,V} = {sign, zero, inexact, overflow}

  // Instancia del DUT
  alu dut(
    .a(a), .b(b), .op(op),
    .y(y), .ALUFlags(ALUFlags)
  );

  // ----------- Constantes útiles (half precision) en BINARIO ------------
  localparam [1:0] OP_ADD = 2'b00,
                   OP_SUB = 2'b01,
                   OP_MUL = 2'b10,
                   OP_DIV = 2'b11;

  localparam [15:0] 
    HP_PZERO = 16'b0000000000000000, // +0
    HP_NZERO = 16'b1000000000000000, // -0
    HP_ONE   = 16'b0011110000000000, // 0x3C00  1.0
    HP_TWO   = 16'b0100000000000000, // 0x4000  2.0
    HP_FOUR  = 16'b0100010000000000, // 0x4400  4.0
    HP_HALF  = 16'b0011100000000000, // 0x3800  0.5
    HP_ONEP5 = 16'b0011111000000000, // 0x3E00  1.5
    HP_THREE = 16'b0100001000000000, // 0x4200  3.0
    HP_MONE  = 16'b1011110000000000, // 0xBC00 -1.0
    HP_HALF_ULP_AT_1 = 16'b0001000000000000, // 0x1000 2^-11 (mitad de ULP alrededor de 1.0)
    HP_1_ULP_ABOVE_1 = 16'b0011110000000001, // 0x3C01 1.0 + 1 ULP
    HP_2_ULP_ABOVE_1 = 16'b0011110000000010; // 0x3C02 1.0 + 2 ULP

  // Helpers
  function automatic is_zero_fp(input [15:0] v);
    is_zero_fp = (v[14:0] == 15'd0);
  endfunction

  // ----------- Infra: checker y contadores -------------------
  integer total, passed, failed;

  task automatic check_eq(
    input [127:0] name,
    input [1:0]   op_i,
    input [15:0]  a_i, b_i,
    input [15:0]  exp_y,
    input [3:0]   exp_flags,
    input [3:0]   mask_flags // 1 = comparar ese bit; 0 = ignorar
  );
    begin
      op = op_i; a = a_i; b = b_i;
      #1; // combinacional
      total = total + 1;
      if (y !== exp_y || ((ALUFlags & mask_flags) !== (exp_flags & mask_flags))) begin
        failed = failed + 1;
        $display("[FALLÓ] %-14s op=%b a=%b b=%b | y=%b flags=%b  (exp_y=%b exp_flags=%b mask=%b)",
                 name, op_i, a_i, b_i, y, ALUFlags, exp_y, exp_flags, mask_flags);
      end else begin
        passed = passed + 1;
      end
    end
  endtask

  task automatic check_flags_only(
    input [127:0] name,
    input [1:0]   op_i,
    input [15:0]  a_i, b_i,
    input [3:0]   exp_flags,
    input [3:0]   mask_flags
  );
    begin
      op = op_i; a = a_i; b = b_i; #1;
      total = total + 1;
      if ( (ALUFlags & mask_flags) !== (exp_flags & mask_flags) ) begin
        failed = failed + 1;
        $display("[FALLÓ] %-14s op=%b a=%b b=%b | y=%b flags=%b  (exp_flags=%b mask=%b)",
                 name, op_i, a_i, b_i, y, ALUFlags, exp_flags, mask_flags);
      end else passed = passed + 1;
    end
  endtask

  task automatic check_commutative(
    input [127:0] name,
    input [1:0]   op_i,
    input [15:0]  a_i, b_i
  );
    reg [15:0] y_ab, y_ba;
    reg [3:0]  f_ab, f_ba;
    begin
      op = op_i; a = a_i; b = b_i; #1; y_ab = y; f_ab = ALUFlags;
      op = op_i; a = b_i; b = a_i; #1; y_ba = y; f_ba = ALUFlags;
      total = total + 1;
      if (y_ab !== y_ba || f_ab !== f_ba) begin
        failed = failed + 1;
        $display("[FALLÓ] %-14s (no conmutativa) a=%b b=%b  y_ab=%b f=%b  y_ba=%b f=%b",
                 name, a_i, b_i, y_ab, f_ab, y_ba, f_ba);
      end else passed = passed + 1;
    end
  endtask

  task automatic check_identities(input [15:0] val);
    begin
      // a - a = +0, Z=1
      op = OP_SUB; a = val; b = val; #1;
      total = total + 1;
      if (!is_zero_fp(y) || ALUFlags[2] !== 1'b1) begin
        failed = failed + 1;
        $display("[FALLÓ] id: a-a==+0  a=%b  y=%b flags=%b", val, y, ALUFlags);
      end else passed = passed + 1;

      // si a != 0: a/a = 1.0
      if (!is_zero_fp(val)) begin
        op = OP_DIV; a = val; b = val; #1;
        total = total + 1;
        if (y !== HP_ONE) begin
          failed = failed + 1;
          $display("[FALLÓ] id: a/a==1  a=%b  y=%b flags=%b", val, y, ALUFlags);
        end else passed = passed + 1;
      end
    end
  endtask

  initial begin
    total=0; passed=0; failed=0;
    $display("=== TB ALU fp16 (bin)  N,Z,C,V = sign, zero, inexact, overflow ===");

    // ---------- Casos determinísticos ----------
    check_eq("ADD 1+1",   OP_ADD, HP_ONE,   HP_ONE,   HP_TWO,   4'b0000, 4'b1111);
    check_eq("ADD -1+1",  OP_ADD, HP_MONE,  HP_ONE,   HP_PZERO, 4'b0100, 4'b1111);
    check_eq("SUB 2-1.5", OP_SUB, HP_TWO,   HP_ONEP5, HP_HALF,  4'b0000, 4'b1111);
    check_eq("SUB 1-1",   OP_SUB, HP_ONE,   HP_ONE,   HP_PZERO, 4'b0100, 4'b1111);
    check_eq("MUL 1.5*2", OP_MUL, HP_ONEP5, HP_TWO,   HP_THREE, 4'b0000, 4'b1111);
    check_eq("MUL 0*4",   OP_MUL, HP_PZERO, HP_FOUR,  HP_PZERO, 4'b0100, 4'b1111);
    check_eq("DIV 1/2",   OP_DIV, HP_ONE,   HP_TWO,   HP_HALF,  4'b0000, 4'b1111);

    // Inexact claro (no comparamos valor, solo C=1)
    check_flags_only("DIV 1/3 IX", OP_DIV, HP_ONE, HP_THREE, 4'b0010, 4'b0010);

    // ---------- Empates RNE (ties-to-even) ----------
    // LSB(par) => redondea hacia abajo, queda 1.0; C=1
    check_eq("TIE-EVEN DN", OP_ADD, HP_ONE, HP_HALF_ULP_AT_1,
             HP_ONE, 4'b0010, 4'b1111);
    // LSB(impar) => redondea hacia arriba a mantisa par; C=1
    check_eq("TIE-EVEN UP", OP_ADD, HP_1_ULP_ABOVE_1, HP_HALF_ULP_AT_1,
             HP_2_ULP_ABOVE_1, 4'b0010, 4'b1111);

    // ---------- Propiedades ----------
    check_commutative("ADD conmut", OP_ADD, HP_ONEP5, HP_HALF);
    check_commutative("MUL conmut", OP_MUL, HP_THREE, HP_HALF);
    check_identities(HP_ONE);
    check_identities(HP_TWO);
    check_identities(HP_THREE);
    check_identities(HP_HALF);

    // ---------- Resumen ----------
    $display("--------------------------------------------------");
    $display("Total: %0d  OK: %0d  FAIL: %0d", total, passed, failed);
    if (failed==0) $display(">>> TODO OK ?");
    else           $display(">>> HAY FALLAS ?");
    $finish;
  end

endmodule

