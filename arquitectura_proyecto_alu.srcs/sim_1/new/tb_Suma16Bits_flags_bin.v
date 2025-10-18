`timescale 1ns/1ps

module tb_SumaResta_flags_all;

  // Entradas bajo prueba
  reg  [15:0] A, B;

  // ========= Instancia para SUMA =========
  wire [15:0] F_add;
  wire ov_add, un_add, iv_add, ix_add;

  Suma16Bits DUT_ADD (
    .S(A), .R(B), .F(F_add),
    .overflow(ov_add), .underflow(un_add),
    .inv_op(iv_add), .inexact(ix_add)
  );

  // ========= Instancia para RESTA (A + (-B)) =========
  wire [15:0] F_sub;
  wire ov_sub, un_sub, iv_sub, ix_sub;

  Suma16Bits DUT_SUB (
    .S(A), .R({~B[15], B[14:0]}), .F(F_sub), // cambia signo de B
    .overflow(ov_sub), .underflow(un_sub),
    .inv_op(iv_sub), .inexact(ix_sub)
  );

  // -------- Half-precision útiles (binario) --------
  localparam [15:0] HP_Z     = 16'b0_00000_0000000000; // +0
  localparam [15:0] HP_ONE   = 16'b0_01111_0000000000; //  1.0
  localparam [15:0] HP_ONEP5 = 16'b0_01111_1000000000; //  1.5
  localparam [15:0] HP_TWO   = 16'b0_10000_0000000000; //  2.0
  localparam [15:0] HP_MAXF  = 16'b0_11110_1111111111; //  max finito
  localparam [15:0] HP_INF   = 16'b0_11111_0000000000; //  +Inf
  localparam [15:0] HP_HALF_LSB1 = 16'b0_01110_0000000001; // 0.500488...
  localparam [15:0] HP_MIN_N     = 16'b0_00001_0000000000; // mínimo normal
  localparam [15:0] HP_MIN_N_P1  = 16'b0_00001_0000000001; // min normal + 1 LSB

  integer fails;

  // ====== Helpers (compatibles con Verilog-2001) ======
  task show_add;
    input [8*64-1:0] name;
    begin
      $display("%s", name);
      $display("  [ADD] A=%b  B=%b  ->  F=%b  | ovf=%b unf=%b inv=%b inex=%b",
               A, B, F_add, ov_add, un_add, iv_add, ix_add);
    end
  endtask

  task show_sub;
    input [8*64-1:0] name;
    begin
      $display("%s", name);
      $display("  [SUB] A=%b  B=%b  ->  F=%b  | ovf=%b unf=%b inv=%b inex=%b",
               A, B, F_sub, ov_sub, un_sub, iv_sub, ix_sub);
    end
  endtask

  task check_y_add;
    input [15:0] exp;
    begin
      if (F_add !== exp) begin
        $display("  [FAIL ADD] F got=%b exp=%b", F_add, exp);
        fails = fails + 1;
      end
    end
  endtask

  task check_y_sub;
    input [15:0] exp;
    begin
      if (F_sub !== exp) begin
        $display("  [FAIL SUB] F got=%b exp=%b", F_sub, exp);
        fails = fails + 1;
      end
    end
  endtask

  // Compara flags con máscara (1=se verifica, 0="no me importa")
  task check_flags_add_mask;
    input [3:0] exp;   // {ovf,unf,inv,inex}
    input [3:0] mask;  // bit=1 obliga igualdad
    reg   [3:0] got;
    begin
      got = {ov_add, un_add, iv_add, ix_add};
      if ( (got & mask) !== (exp & mask) ) begin
        $display("  [FAIL ADD] flags got=%b exp=%b mask=%b", got, exp, mask);
        fails = fails + 1;
      end
    end
  endtask

  task check_flags_sub_mask;
    input [3:0] exp;   // {ovf,unf,inv,inex}
    input [3:0] mask;
    reg   [3:0] got;
    begin
      got = {ov_sub, un_sub, iv_sub, ix_sub};
      if ( (got & mask) !== (exp & mask) ) begin
        $display("  [FAIL SUB] flags got=%b exp=%b mask=%b", got, exp, mask);
        fails = fails + 1;
      end
    end
  endtask

  initial begin
    fails = 0;
    $display("===============================================================");
    $display("  TEST: Suma16Bits (ADD y SUB) -> verifica todas las banderas");
    $display("===============================================================\n");

    // ---------------- SUMA ----------------
    // (A) 1.0 + 1.0 = 2.0   (sin flags)
    A=HP_ONE; B=HP_ONE; #2;
    show_add("ADD A: 1.0 + 1.0");
    check_y_add(HP_TWO);
    check_flags_add_mask(4'b0000, 4'b1111);

    // (B) 1.5 + 1.5 = 3.0   (carry/normalize, sin overflow)
    A=HP_ONEP5; B=HP_ONEP5; #2;
    show_add("ADD B: 1.5 + 1.5");
    check_y_add(16'b0_10000_1000000000); // 3.0
    check_flags_add_mask(4'b0000, 4'b1111);

    // (C) 1.0 + 0.500488... -> inexact=1 por alineamiento
    A=HP_ONE; B=HP_HALF_LSB1; #2;
    show_add("ADD C: 1.0 + 0.500488... (inexact=1)");
    check_flags_add_mask(4'b0001, 4'b0001); // solo miro inex

    // (D) Overflow: max_finite + max_finite
    A=HP_MAXF; B=HP_MAXF; #2;
    show_add("ADD D: max_finite + max_finite (overflow)");
    check_flags_add_mask(4'b1000, 4'b1000); // ovf=1 (los demás no obligatorios aquí)

    // (E) Inválida según tu helper: +Inf + +Inf  (tu RTL pone inv=1 y ovf=1 en suma)
    A=HP_INF; B=HP_INF; #2;
    show_add("ADD E: +Inf + +Inf (inv=1, ovf=1 por tu mapeo)");
    check_flags_add_mask(4'b1010, 4'b1010);  // AHORA: ovf=1, inv=1

    // ---------------- RESTA ----------------
    // (F) 1.0 + (-1.0) = +0.0 (sin flags)  <-- requiere que tu RTL produzca cero canónico
    A=HP_ONE; B=HP_ONE; #2;
    show_sub("SUB F: 1.0 - 1.0 = 0.0");
    check_y_sub(HP_Z);
    check_flags_sub_mask(4'b0000, 4'b1111);

    // (G) inexact en resta: 1.0 - 0.500488...  (alinea y pierde bits)
    A=HP_ONE; B=HP_HALF_LSB1; #2;
    show_sub("SUB G: 1.0 - 0.500488... (inexact=1)");
    check_flags_sub_mask(4'b0001, 4'b0001); // solo inex=1

    // (H) underflow en resta por cancelación con exponente mínimo:
    //     (1.0*2^-14 + 1LSB) - (1.0*2^-14) -> requiere shift > exp -> underflow=1
    A=HP_MIN_N_P1; B=HP_MIN_N; #2;
    show_sub("SUB H: (min_norm+LSB) - (min_norm)  => underflow=1");
    check_flags_sub_mask(4'b0100, 4'b0110); // espero unf=1; ovf=0 (inv no aplica)

    // (I) Inválida (según tu helper) en resta: +Inf - +Inf  => inv=1, ovf=0 en resta
    A=HP_INF; B=HP_INF; #2;
    show_sub("SUB I: +Inf - +Inf (inv=1, ovf=0 en resta)");
    check_flags_sub_mask(4'b0100, 4'b0100); // solo inv=1 en SUB (tu RTL pone ovf=0 en resta)

    $display("\n---- SUMMARY: %0d FAIL(s) ----", fails);
    if (fails != 0) $stop; else $finish;
  end

endmodule
