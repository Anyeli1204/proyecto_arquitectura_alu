`timescale 1ns/1ps

module top_basys3_fp_alu_full_tb;

  // DUT I/O (mismos puertos que tu top)
  reg          CLK100MHZ = 0;
  reg  [15:0]  SW = 16'h0000;
  reg          BTNC=0, BTNU=0, BTND=0, BTNL=0, BTNR=0;
  wire [15:0]  LED;
  wire [3:0]   AN;
  wire         CA,CB,CC,CD,CE,CF,CG,DP;

  // Instancia del TOP (sin wrapper)
  top_basys3_fp_alu UUT(
    .CLK100MHZ(CLK100MHZ), .SW(SW),
    .BTNC(BTNC), .BTNU(BTNU), .BTND(BTND), .BTNL(BTNL), .BTNR(BTNR),
    .LED(LED), .AN(AN), .CA(CA), .CB(CB), .CC(CC), .CD(CD), .CE(CE), .CF(CF), .CG(CG), .DP(DP)
  );

  // Reloj 100 MHz
  always #5 CLK100MHZ = ~CLK100MHZ;

  // ====== Accesos jerárquicos útiles (resultado/flags/valid) ======
  wire [31:0] R = UUT.result;        // resultado capturado en el TOP
  wire [4:0]  F = UUT.flags;         // {invalid(4), div0(3), ovf(2), unf(1), inx(0)}
  wire        V = UUT.valid_out;

  // ====== Helpers de botones (3 ciclos por el sincronizador 2FF) ======
  task press_start; begin BTNC=1; repeat(3) @(posedge CLK100MHZ); BTNC=0; end endtask
  task press_reset; begin BTND=1; repeat(3) @(posedge CLK100MHZ); BTND=0; end endtask
  task press_load;  begin BTNL=1; repeat(3) @(posedge CLK100MHZ); BTNL=0; end endtask
  task press_next;  begin BTNR=1; repeat(3) @(posedge CLK100MHZ); BTNR=0; end endtask

  // ====== Switch helpers ======
  // SW[11]=mode_fp (0=half, 1=single), SW[8]=sel_b (0=A,1=B), SW[10:9]=op (00 add,01 sub,10 mul,11 div)
  task set_mode;  input single32;       begin SW[11]   = single32; end endtask
  task set_sel_b; input is_b;           begin SW[8]    = is_b;     end endtask
  task set_op;    input [1:0] op2;      begin SW[10:9] = op2;      end endtask
  task show_msb;  input bit on;         begin SW[14]   = on;       end endtask

  // Espera valid_out con timeout
  task wait_for_valid;
    integer cnt;
    begin
      cnt = 0;
      while (V !== 1'b1 && cnt < 2000) begin
        @(posedge CLK100MHZ);
        cnt = cnt + 1;
      end
      if (V !== 1'b1) begin
        $display("TIMEOUT esperando valid_out");
        $stop;
      end
      @(posedge CLK100MHZ); // margen
    end
  endtask

  // ====== Carga por UI (igual que en placa) ======
  // HALF (16b): 2 bytes LSB->MSB
  task load_half;
    input is_b; input [15:0] h;
    begin
      set_mode(1'b0); set_sel_b(is_b);
      SW[7:0] = h[7:0];  press_load(); press_next();
      SW[7:0] = h[15:8]; press_load(); press_next();
    end
  endtask
  // SINGLE (32b): 4 bytes LSB->MSB
  task load_single;
    input is_b; input [31:0] w;
    begin
      set_mode(1'b1); set_sel_b(is_b);
      SW[7:0] = w[7:0];    press_load(); press_next();
      SW[7:0] = w[15:8];   press_load(); press_next();
      SW[7:0] = w[23:16];  press_load(); press_next();
      SW[7:0] = w[31:24];  press_load(); press_next();
    end
  endtask

  // ====== Constantes útiles ======
  // Half (16b)
  localparam [15:0] HP_POS0 = 16'h0000, HP_NEG0 = 16'h8000;
  localparam [15:0] HP_ONE  = 16'h3C00, HP_TWO  = 16'h4000, HP_THREE=16'h4200;
  localparam [15:0] HP_FIVE = 16'h4500, HP_SIX  = 16'h4600, HP_NEG3 = 16'hC200;
  localparam [15:0] HP_QTR  = 16'h3400, HP_ONEP5= 16'h3E00, HP_TWOP5=16'h4100;
  localparam [15:0] HP_THREEP5 = 16'h4300, HP_THREEP75 = 16'h4380;
  localparam [15:0] HP_PINF = 16'h7C00, HP_QNAN = 16'h7E00;

  // Single (32b)
  localparam [31:0] SP_POS0 = 32'h00000000, SP_NEG0 = 32'h80000000;
  localparam [31:0] SP_ONE  = 32'h3F800000, SP_TWO  = 32'h40000000, SP_THREE=32'h40400000;
  localparam [31:0] SP_FIVE = 32'h40A00000, SP_SIX  = 32'h40C00000, SP_NEG3 = 32'hC0400000;
  localparam [31:0] SP_QTR  = 32'h3E800000, SP_ONEP5= 32'h3FC00000, SP_TWOP5=32'h40200000;
  localparam [31:0] SP_THREEP5 = 32'h40600000, SP_THREEP75=32'h40700000;
  localparam [31:0] SP_SEVENP5 = 32'h40F00000;
  localparam [31:0] SP_PINF = 32'h7F800000, SP_QNAN = 32'h7FC00000;

  // ====== Checks ======
  task check_half; input [15:0] exp16; input [127:0] msg;
    begin
      show_msb(1'b0); // mostrar LSB
      if (R[15:0] !== exp16) begin
        $display("ERROR HALF %0s: got=%h exp=%h", msg, R[15:0], exp16);
        $stop;
      end else $display("OK HALF %0s", msg);
    end
  endtask

  task check_single; input [31:0] exp32; input [127:0] msg;
    begin
      if (R !== exp32) begin
        $display("ERROR SINGLE %0s: got=%h exp=%h", msg, R, exp32);
        $stop;
      end else $display("OK SINGLE %0s", msg);
    end
  endtask

  // Check NaN (exp=all1 y mantisa!=0)
  function is_nan16; input [15:0] x;
    begin is_nan16 = (x[14:10]==5'b11111) && (x[9:0]!=10'b0); end
  endfunction
  function is_nan32; input [31:0] x;
    begin is_nan32 = (x[30:23]==8'hFF) && (x[22:0]!=23'b0); end
  endfunction

  // ====== Secuencia de pruebas ======
  initial begin
    // Reset inicial
    SW = 16'h0000; BTNC=0; BTNU=0; BTND=0; BTNL=0; BTNR=0;
    repeat(5) @(posedge CLK100MHZ);
    press_reset(); repeat(2) @(posedge CLK100MHZ);

    // ============================
    // 1) OPERACIONES CON ENTEROS
    // ============================

    // ---- HALF: 1 + 2 = 3
    load_half(1'b0, HP_ONE);  // A
    load_half(1'b1, HP_TWO);  // B
    set_op(2'b00); press_start(); wait_for_valid();
    check_half(HP_THREE, "ADD 1+2");

    // HALF: 5 - 3 = 2
    press_reset(); repeat(2) @(posedge CLK100MHZ);
    load_half(1'b0, HP_FIVE);
    load_half(1'b1, HP_THREE);
    set_op(2'b01); press_start(); wait_for_valid();
    check_half(HP_TWO, "SUB 5-3");

    // HALF: 2 * (-3) = -6
    press_reset(); repeat(2) @(posedge CLK100MHZ);
    load_half(1'b0, HP_TWO);
    load_half(1'b1, HP_NEG3);
    set_op(2'b10); press_start(); wait_for_valid();
    check_half(16'hC600, "MUL 2*(-3)"); // -6.0

    // HALF: 6 / 3 = 2
    press_reset(); repeat(2) @(posedge CLK100MHZ);
    load_half(1'b0, HP_SIX);
    load_half(1'b1, HP_THREE);
    set_op(2'b11); press_start(); wait_for_valid();
    check_half(HP_TWO, "DIV 6/3");

    // ---- SINGLE: 1 + 2 = 3
    press_reset(); repeat(2) @(posedge CLK100MHZ);
    load_single(1'b0, SP_ONE);
    load_single(1'b1, SP_TWO);
    set_op(2'b00); press_start(); wait_for_valid();
    check_single(SP_THREE, "ADD 1+2");

    // SINGLE: 5 - 3 = 2
    press_reset(); repeat(2) @(posedge CLK100MHZ);
    load_single(1'b0, SP_FIVE);
    load_single(1'b1, SP_THREE);
    set_op(2'b01); press_start(); wait_for_valid();
    check_single(SP_TWO, "SUB 5-3");

    // SINGLE: 2 * (-3) = -6
    press_reset(); repeat(2) @(posedge CLK100MHZ);
    load_single(1'b0, SP_TWO);
    load_single(1'b1, SP_NEG3);
    set_op(2'b10); press_start(); wait_for_valid();
    check_single(32'hC0C00000, "MUL 2*(-3)"); // -6.0

    // SINGLE: 6 / 3 = 2
    press_reset(); repeat(2) @(posedge CLK100MHZ);
    load_single(1'b0, SP_SIX);
    load_single(1'b1, SP_THREE);
    set_op(2'b11); press_start(); wait_for_valid();
    check_single(SP_TWO, "DIV 6/3");

    // ============================
    // 2) OPERACIONES CON DECIMALES
    // ============================

    // ---- HALF: 3.5 + 0.25 = 3.75
    press_reset(); repeat(2) @(posedge CLK100MHZ);
    load_half(1'b0, HP_THREEP5);
    load_half(1'b1, HP_QTR);
    set_op(2'b00); press_start(); wait_for_valid();
    check_half(HP_THREEP75, "ADD 3.5+0.25");

    // ---- SINGLE: 1.5 + 2.25 = 3.75
    press_reset(); repeat(2) @(posedge CLK100MHZ);
    load_single(1'b0, SP_ONEP5);
    load_single(1'b1, 32'h40100000); // 2.25
    set_op(2'b00); press_start(); wait_for_valid();
    check_single(SP_THREEP75, "ADD 1.5+2.25");

    // SINGLE: 1.5 * 2.5 = 3.75
    press_reset(); repeat(2) @(posedge CLK100MHZ);
    load_single(1'b0, SP_ONEP5);
    load_single(1'b1, SP_TWOP5);
    set_op(2'b10); press_start(); wait_for_valid();
    check_single(SP_THREEP75, "MUL 1.5*2.5");

    // SINGLE: 7.5 / 2.5 = 3.0
    press_reset(); repeat(2) @(posedge CLK100MHZ);
    load_single(1'b0, SP_SEVENP5);
    load_single(1'b1, SP_TWOP5);
    set_op(2'b11); press_start(); wait_for_valid();
    check_single(SP_THREE, "DIV 7.5/2.5");

    // ============================
    // 3) CASOS ESPECIALES
    // ============================

    // ---- SINGLE: 1.0 / +0.0 = +Inf, div0=1, invalid=0
    press_reset(); repeat(2) @(posedge CLK100MHZ);
    load_single(1'b0, SP_ONE);
    load_single(1'b1, SP_POS0);
    set_op(2'b11); press_start(); wait_for_valid();
    check_single(SP_PINF, "DIV 1.0/+0.0 -> +Inf");
    if (F[3] !== 1'b1) begin $display("ERROR flags: div-by-zero no activo"); $stop; end
    if (F[4] !== 1'b0) begin $display("ERROR flags: invalid debería ser 0"); $stop; end
    $display("OK flags DIV/0 (+Inf, div0=1)");

    // SINGLE: 0 * Inf = NaN, invalid=1
    press_reset(); repeat(2) @(posedge CLK100MHZ);
    load_single(1'b0, SP_POS0);
    load_single(1'b1, SP_PINF);
    set_op(2'b10); press_start(); wait_for_valid();
    if (!is_nan32(R)) begin
      $display("ERROR 0*Inf: esperaba NaN, got=%h", R); $stop;
    end
    if (F[4] !== 1'b1) begin $display("ERROR flags: invalid no activo en 0*Inf"); $stop; end
    $display("OK 0*Inf -> NaN (invalid=1)");

    // SINGLE: NaN + 1.0 = NaN (propagación)
    press_reset(); repeat(2) @(posedge CLK100MHZ);
    load_single(1'b0, SP_QNAN);
    load_single(1'b1, SP_ONE);
    set_op(2'b00); press_start(); wait_for_valid();
    if (!is_nan32(R)) begin
      $display("ERROR NaN+1.0: esperaba NaN, got=%h", R); $stop;
    end
    $display("OK NaN propagation en ADD");

    // ---- HALF: 1.0 / -0.0 = -Inf, div0=1
    press_reset(); repeat(2) @(posedge CLK100MHZ);
    load_half(1'b0, HP_ONE);
    load_half(1'b1, HP_NEG0);
    set_op(2'b11); press_start(); wait_for_valid();
    if (R[15:0] !== 16'hFC00) begin
      $display("ERROR HALF DIV 1/(-0): got=%h exp=%h", R[15:0], 16'hFC00); $stop;
    end
    if (F[3] !== 1'b1) begin $display("ERROR HALF DIV 1/(-0): div0 no activo"); $stop; end
    $display("OK HALF 1/(-0) -> -Inf");

    // HALF: 0 * Inf = NaN, invalid=1
    press_reset(); repeat(2) @(posedge CLK100MHZ);
    load_half(1'b0, HP_POS0);
    load_half(1'b1, HP_PINF);
    set_op(2'b10); press_start(); wait_for_valid();
    if (!is_nan16(R[15:0])) begin
      $display("ERROR HALF 0*Inf: esperaba NaN, got=%h", R[15:0]); $stop;
    end
    if (F[4] !== 1'b1) begin $display("ERROR HALF flags: invalid no activo en 0*Inf"); $stop; end
    $display("OK HALF 0*Inf -> NaN (invalid=1)");

    $display("? TODAS LAS PRUEBAS PASARON.");
    $finish;
  end

endmodule
