`timescale 1ns/1ps

// Testbench que emula el uso "de placa":
// - SW[7:0] cargan bytes (binario)
// - BTNL = LOAD, BTNR = NEXT, BTNC = START, BTND = RESET
// - Lee 7-seg (AN, CA..CG) y los decodifica a HEX para imprimir lo que se vería.

module top_basys3_fp_alu_boardlike_tb;

  // --- DUT I/O ---
  reg          CLK100MHZ = 0;
  reg  [15:0]  SW = 16'h0000;
  reg          BTNC=0, BTNU=0, BTND=0, BTNL=0, BTNR=0;
  wire [15:0]  LED;
  wire [3:0]   AN;
  wire         CA,CB,CC,CD,CE,CF,CG,DP;

  top_basys3_fp_alu UUT(
    .CLK100MHZ(CLK100MHZ), .SW(SW),
    .BTNC(BTNC), .BTNU(BTNU), .BTND(BTND), .BTNL(BTNL), .BTNR(BTNR),
    .LED(LED), .AN(AN), .CA(CA), .CB(CB), .CC(CC), .CD(CD), .CE(CE), .CF(CF), .CG(CG), .DP(DP)
  );

  // 100 MHz
  always #5 CLK100MHZ = ~CLK100MHZ;

  // ----------------- utilidades botones / switches -----------------
  task press_start; begin BTNC=1; repeat(3) @(posedge CLK100MHZ); BTNC=0; end endtask
  task press_reset; begin BTND=1; repeat(3) @(posedge CLK100MHZ); BTND=0; end endtask
  task press_load;  begin BTNL=1; repeat(3) @(posedge CLK100MHZ); BTNL=0; end endtask
  task press_next;  begin BTNR=1; repeat(3) @(posedge CLK100MHZ); BTNR=0; end endtask

  task set_mode;  input single32;      begin SW[11]=single32; end endtask
  task set_sel_b; input is_b;          begin SW[8] = is_b;    end endtask
  task set_op;    input [1:0] op2;     begin SW[10:9]=op2;    end endtask
  task show_msb;  input on;            begin SW[14]=on;       end endtask

  // Espera a que el TOP pulse valid (LED[6]) y a que 'valid' interno sea 1
  wire V = UUT.valid;
  task wait_for_valid;
    integer t;
    begin
      t=0; while (V!==1'b1 && t<5000) begin @(posedge CLK100MHZ); t=t+1; end
      if (V!==1'b1) begin $display("TIMEOUT esperando valid"); $stop; end
      @(posedge CLK100MHZ);
    end
  endtask

  // ----------------- Carga tipo placa -----------------
  // HALF (16): 2 bytes LSB->MSB
  task load_half;
    input is_b; input [15:0] h;
    begin
      set_mode(1'b0); set_sel_b(is_b);
      SW[7:0]=h[7:0];  press_load(); press_next();
      SW[7:0]=h[15:8]; press_load(); press_next();
    end
  endtask
  // SINGLE (32): 4 bytes LSB->MSB
  task load_single;
    input is_b; input [31:0] w;
    begin
      set_mode(1'b1); set_sel_b(is_b);
      SW[7:0]=w[7:0];    press_load(); press_next();
      SW[7:0]=w[15:8];   press_load(); press_next();
      SW[7:0]=w[23:16];  press_load(); press_next();
      SW[7:0]=w[31:24];  press_load(); press_next();
    end
  endtask

  // ----------------- Decodificador 7-seg -> HEX -----------------
  // Segmentos activos en BAJO. Mismo mapa que el módulo hex7 del TOP.
  function [3:0] seg_to_hex; input [6:0] seg_al; begin
    case (seg_al) // {CA,CB,CC,CD,CE,CF,CG}
      7'b1000000: seg_to_hex=4'h0;
      7'b1111001: seg_to_hex=4'h1;
      7'b0100100: seg_to_hex=4'h2;
      7'b0110000: seg_to_hex=4'h3;
      7'b0011001: seg_to_hex=4'h4;
      7'b0010010: seg_to_hex=4'h5;
      7'b0000010: seg_to_hex=4'h6;
      7'b1111000: seg_to_hex=4'h7;
      7'b0000000: seg_to_hex=4'h8;
      7'b0010000: seg_to_hex=4'h9;
      7'b0001000: seg_to_hex=4'hA;
      7'b0000011: seg_to_hex=4'hB;
      7'b1000110: seg_to_hex=4'hC;
      7'b0100001: seg_to_hex=4'hD;
      7'b0000110: seg_to_hex=4'hE;
      7'b0001110: seg_to_hex=4'hF;
      default:    seg_to_hex=4'hX;
    endcase
  end endfunction

  // Captura un barrido completo de 7-seg y devuelve el valor de 16 bits mostrado
  // Orden de anodos (activos en bajo) según el TOP:
  //  an=1110 -> value[3:0]   (digit 0, LSB)
  //  an=1101 -> value[7:4]   (digit 1)
  //  an=1011 -> value[11:8]  (digit 2)
  //  an=0111 -> value[15:12] (digit 3, MSB)
  task read_7seg_hex16; output [15:0] hex;
    reg [3:0] d0,d1,d2,d3; reg [6:0] segs;
    begin
      // espera a ver cada anodo activo una vez y captura
      // (esperas cortas porque refresca ~1.5 kHz por dígito)
      wait (AN==4'b1110); segs={CA,CB,CC,CD,CE,CF,CG}; d0=seg_to_hex(segs);
      wait (AN!=4'b1110);
      wait (AN==4'b1101); segs={CA,CB,CC,CD,CE,CF,CG}; d1=seg_to_hex(segs);
      wait (AN!=4'b1101);
      wait (AN==4'b1011); segs={CA,CB,CC,CD,CE,CF,CG}; d2=seg_to_hex(segs);
      wait (AN!=4'b1011);
      wait (AN==4'b0111); segs={CA,CB,CC,CD,CE,CF,CG}; d3=seg_to_hex(segs);
      hex = {d3,d2,d1,d0};
    end
  endtask

  // ----------------- Constantes útiles -----------------
  // HALF
  localparam [15:0] HP_ONE=16'h3C00, HP_TWO=16'h4000, HP_THREE=16'h4200;
  localparam [15:0] HP_SIX=16'h4600, HP_THREEP5=16'h4300, HP_QTR=16'h3400;
  localparam [15:0] HP_PINF=16'h7C00, HP_NEG0=16'h8000, HP_POS0=16'h0000;
  // SINGLE
  localparam [31:0] SP_ONE=32'h3F800000, SP_TWO=32'h40000000, SP_THREE=32'h40400000;
  localparam [31:0] SP_TWOP5=32'h40200000, SP_ONEP5=32'h3FC00000;
  localparam [31:0] SP_SEVENP5=32'h40F00000, SP_QNAN=32'h7FC00000;
  localparam [31:0] SP_PINF=32'h7F800000, SP_POS0=32'h00000000;

  // ----------------- Pruebas estilo placa -----------------
  reg [15:0] hex16;
  reg [15:0] hex16_hi, hex16_lo;

  initial begin
    // RESET desde t=0
    SW=16'h0000; BTNC=0; BTNU=0; BTND=1; BTNL=0; BTNR=0; show_msb(1'b0);
    repeat(4) @(posedge CLK100MHZ); BTND=0; repeat(2) @(posedge CLK100MHZ);

    // ===== HALF: 1 + 2 = 3 (debe verse 4200 en 7-seg) =====
    load_half(1'b0, HP_ONE);
    load_half(1'b1, HP_TWO);
    set_op(2'b00); press_start(); wait_for_valid();
    show_msb(1'b0); read_7seg_hex16(hex16);
    $display("7SEG HALF (LSB) = %h (esperado 4200)", hex16);

    // ===== SINGLE: 1 + 2 = 3 (leer LSB y luego MSB) =====
    press_reset(); repeat(2) @(posedge CLK100MHZ);
    load_single(1'b0, SP_ONE);
    load_single(1'b1, SP_TWO);
    set_op(2'b00); press_start(); wait_for_valid();
    show_msb(1'b0); read_7seg_hex16(hex16_lo);  // parte baja
    show_msb(1'b1); read_7seg_hex16(hex16_hi);  // parte alta
    $display("7SEG SINGLE = %h_%h (esperado 4040_0000)", hex16_hi, hex16_lo);

    // ===== HALF: 3.5 + 0.25 = 3.75 (se ve 4380) =====
    press_reset(); repeat(2) @(posedge CLK100MHZ);
    load_half(1'b0, HP_THREEP5);
    load_half(1'b1, HP_QTR);
    set_op(2'b00); press_start(); wait_for_valid();
    show_msb(1'b0); read_7seg_hex16(hex16);
    $display("7SEG HALF 3.5+0.25 = %h (esperado 4380)", hex16);

    // ===== SINGLE: 7.5 / 2.5 = 3.0 (se ve 4040_0000) =====
    press_reset(); repeat(2) @(posedge CLK100MHZ);
    load_single(1'b0, SP_SEVENP5);
    load_single(1'b1, SP_TWOP5);
    set_op(2'b11); press_start(); wait_for_valid();
    show_msb(1'b0); read_7seg_hex16(hex16_lo);
    show_msb(1'b1); read_7seg_hex16(hex16_hi);
    $display("7SEG SINGLE 7.5/2.5 = %h_%h (esperado 4040_0000)", hex16_hi, hex16_lo);

    // ===== SINGLE: 1 / +0 = +Inf (div0 flag), se ve 7F80_0000 =====
    press_reset(); repeat(2) @(posedge CLK100MHZ);
    load_single(1'b0, SP_ONE);
    load_single(1'b1, SP_POS0);
    set_op(2'b11); press_start(); wait_for_valid();
    show_msb(1'b0); read_7seg_hex16(hex16_lo);
    show_msb(1'b1); read_7seg_hex16(hex16_hi);
    $display("7SEG SINGLE 1/0 = %h_%h (esperado 7F80_0000)  flags(div0,invalid,ovf,unf,inx)=%b",
             hex16_hi, hex16_lo, {UUT.flags_wrapped[3],UUT.flags_wrapped[4:0]});

    $display("? Fin TB estilo placa.");
    $finish;
  end

endmodule
