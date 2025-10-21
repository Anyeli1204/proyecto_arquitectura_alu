`timescale 1ns/1ps

module top_basys3_fp_alu_tb;

  // DUT I/O (mismos nombres que tu top)
  logic         CLK100MHZ = 0;
  logic [15:0]  SW = '0;
  logic         BTNC=0, BTNU=0, BTND=0, BTNL=0, BTNR=0;
  wire  [15:0]  LED;
  wire  [3:0]   AN;
  wire          CA,CB,CC,CD,CE,CF,CG,DP;

  // DUT
  top_basys3_fp_alu UUT(
    .CLK100MHZ(CLK100MHZ), .SW(SW),
    .BTNC(BTNC), .BTNU(BTNU), .BTND(BTND), .BTNL(BTNL), .BTNR(BTNR),
    .LED(LED), .AN(AN), .CA(CA), .CB(CB), .CC(CC), .CD(CD), .CE(CE), .CF(CF), .CG(CG), .DP(DP)
  );

  // Clock 100 MHz
  always #5 CLK100MHZ = ~CLK100MHZ;

  // --- Helpers para "pulsar" botones (edge_up usa 2FF, as� que dejo 3 ciclos) ---
  task press_start();  begin BTNC=1; repeat(3) @(posedge CLK100MHZ); BTNC=0; end endtask
  task press_reset();  begin BTND=1; repeat(3) @(posedge CLK100MHZ); BTND=0; end endtask
  task press_load();   begin BTNL=1; repeat(3) @(posedge CLK100MHZ); BTNL=0; end endtask
  task press_next();   begin BTNR=1; repeat(3) @(posedge CLK100MHZ); BTNR=0; end endtask

  // --- Atajos para setear switches ---
  // SW[11]=mode_fp, SW[8]=sel_b, SW[10:9]=op (00 add, 01 sub, 10 mul, 11 div)
  task set_mode(bit single32);
    begin SW[11] = single32; end
  endtask
  task set_sel_b(bit is_b);
    begin SW[8] = is_b; end
  endtask
  task set_op(input [1:0] op2);
    begin SW[10:9] = op2; end
  endtask

  // --- Carga HALF (16b) en A o B: se env�an 2 bytes (LSB primero) ---
  task load_half(input bit is_b, input [15:0] h);
    begin
      set_mode(1'b0);           // half
      set_sel_b(is_b);          // 0=A,1=B
      // chunk_idx arranca en 0 tras reset
      SW[7:0] = h[7:0]; press_load();     // byte bajo
      press_next();                          // -> chunk 1
      SW[7:0] = h[15:8]; press_load();    // byte alto
      press_next();                          // vuelve a 0 (por comodidad)
    end
  endtask

  // --- Carga SINGLE (32b) en A o B: 4 bytes (LSB primero) ---
  task load_single(input bit is_b, input [31:0] w);
    begin
      set_mode(1'b1);           // single
      set_sel_b(is_b);
      // chunk 0..3 (LSB->MSB)
      SW[7:0] = w[7:0];    press_load();  press_next();
      SW[7:0] = w[15:8];   press_load();  press_next();
      SW[7:0] = w[23:16];  press_load();  press_next();
      SW[7:0] = w[31:24];  press_load();  press_next(); // queda en 0 de nuevo
    end
  endtask

  // Accesos jer�rquicos �tiles para asserts (se�ales internas del top)
  // y : resultado 32b; valid : pulso; flags_wrapped : {invalid, div0, ovf, unf, inx}
  wire [31:0] y          = UUT.y;
  wire        valid      = UUT.valid;
  wire [4:0]  flags_wrap = UUT.flags_wrapped;

  initial begin
    // --------- Reset inicial ---------
    repeat(5) @(posedge CLK100MHZ);
    press_reset();
    repeat(2) @(posedge CLK100MHZ);

    // ================== TEST 1 (HALF): 1.0 + 2.0 = 3.0 ==================
    // half hex: 1.0=0x3C00, 2.0=0x4000, 3.0=0x4200
    load_half(1'b0, 16'h3C00);   // A
    load_half(1'b1, 16'h4000);   // B
    set_op(2'b00);               // ADD
    SW[14] = 1'b0;               // mostrar LSB en 7seg (no afecta a la verificaci�n)
    press_start();
    // espera valid
    wait(valid==1'b1); @(posedge CLK100MHZ); // 1 ciclo de margen
    assert(y[15:0] == 16'h4200)
      else $fatal("HALF ADD fallo: got=%h exp=%h", y[15:0], 16'h4200);
    // flags deben ser 0 en suma exacta
    assert(flags_wrap == 5'b00000)
      else $fatal("HALF ADD flags inesperados: %b", flags_wrap);

    // --------- peque�o gap ---------
    repeat(5) @(posedge CLK100MHZ);
    press_reset(); repeat(2) @(posedge CLK100MHZ);

    // ================== TEST 2 (SINGLE): 1.0 / +0.0 = +Inf, div0=1 ==================
    // single: 1.0=0x3F800000, +0=0x00000000, +Inf=0x7F800000
    load_single(1'b0, 32'h3F800000); // A=1.0
    load_single(1'b1, 32'h00000000); // B=+0.0
    set_op(2'b11);                   // DIV
    press_start();
    wait(valid==1'b1); @(posedge CLK100MHZ);
    assert(y == 32'h7F800000)
      else $fatal("SINGLE DIV/0 fallo: got=%h exp=%h", y, 32'h7F800000);
    assert(flags_wrap[3] == 1'b1)    // div-by-zero
      else $fatal("SINGLE DIV/0: flag div0 no activo");
    // (seg�n tu handler, overflow podr�a estar 1; no lo forzamos aqu�)

    $display("? Todos los tests del top pasaron. ");
    $finish;
  end

endmodule
