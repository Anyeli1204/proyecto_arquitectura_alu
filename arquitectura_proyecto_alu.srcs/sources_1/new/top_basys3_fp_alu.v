// top_basys3_fp_alu.v
`timescale 1ns/1ps

// ========================= Wrapper: adapta tu 'alu' a la interfaz del enunciado =========================
module fp_alu (
  input              clk,
  input              rst,
  input              start,
  input       [31:0] op_a,
  input       [31:0] op_b,
  input        [2:0] op_code,     // 000=ADD, 001=SUB, 010=MUL, 011=DIV
  input              mode_fp,     // 0=half(16), 1=single(32)
  input        [1:0] round_mode,  // 00=nearest-even (por ahora ignorado)
  output reg  [31:0] result,
  output reg         valid_out,
  output reg   [4:0] flags        // {invalid, div_by_zero, overflow, underflow, inexact}
);
  // Map a 2 bits para tu 'alu'
  wire [1:0] op2 = op_code[1:0];

  // Instancias HALF (16) y SINGLE (32). Tu 'alu' es combinacional.
  wire [15:0] y16;  wire [4:0] f16;
  alu #(.system(16)) u_alu16 (.a(op_a[15:0]), .b(op_b[15:0]), .op(op2), .y(y16), .ALUFlags(f16));

  wire [31:0] y32;  wire [4:0] f32;
  alu #(.system(32)) u_alu32 (.a(op_a),       .b(op_b),       .op(op2), .y(y32), .ALUFlags(f32));

  reg [31:0] next_result;  reg [4:0] next_flags;
  always @* begin
    if (mode_fp == 1'b0) begin
      next_result = {16'b0, y16};  // en half solo valen los 16 LSB
      next_flags  = f16;
    end else begin
      next_result = y32;
      next_flags  = f32;
    end
  end

  // Handshake simple: captura a 1 ciclo de 'start'
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      result    <= 32'b0;
      flags     <= 5'b0;
      valid_out <= 1'b0;
    end else begin
      valid_out <= 1'b0;
      if (start) begin
        result    <= next_result;
        flags     <= next_flags;
        valid_out <= 1'b1;   // listo y estable
      end
    end
  end
endmodule

// ========================= Sincronizador de botones & pulso por flanco =========================
module sync_2ff(input clk, input d, output reg q);
  reg q1;
  always @(posedge clk) begin q1 <= d; q <= q1; end
endmodule

module edge_up(input clk, input btn_raw, output pulse);
  wire s; reg s_d;
  sync_2ff u1(clk, btn_raw, s);
  always @(posedge clk) s_d <= s;
  assign pulse = s & ~s_d;
endmodule

// ========================= 7 segmentos (HEX, anodo común Basys3: activo en bajo) =========================
module hex7(input [3:0] nib, output reg [6:0] seg);
  always @* begin
    case(nib)
      4'h0: seg = 7'b1000000; 4'h1: seg = 7'b1111001; 4'h2: seg = 7'b0100100; 4'h3: seg = 7'b0110000;
      4'h4: seg = 7'b0011001; 4'h5: seg = 7'b0010010; 4'h6: seg = 7'b0000010; 4'h7: seg = 7'b1111000;
      4'h8: seg = 7'b0000000; 4'h9: seg = 7'b0010000; 4'hA: seg = 7'b0001000; 4'hB: seg = 7'b0000011;
      4'hC: seg = 7'b1000110; 4'hD: seg = 7'b0100001; 4'hE: seg = 7'b0000110; 4'hF: seg = 7'b0001110;
      default: seg = 7'b1111111;
    endcase
  end
endmodule

module sevenseg_mux(
  input        clk,           // 100 MHz
  input [15:0] value,         // 4 nibbles en HEX
  output reg [3:0] an,        // anodos (activo en bajo)
  output reg [6:0] seg,       // segmentos (activo en bajo)
  output       dp             // punto decimal
);
  assign dp = 1'b1; // apagado

  reg [15:0] refresh_cnt;
  always @(posedge clk) refresh_cnt <= refresh_cnt + 1'b1;

  wire [1:0] sel = refresh_cnt[15:14]; // ~1.5 kHz / dígito (suave, sin parpadeo)
  reg  [3:0] nib;
  always @* begin
    case(sel)
      2'b00: begin an=4'b1110; nib=value[3:0];   end
      2'b01: begin an=4'b1101; nib=value[7:4];   end
      2'b10: begin an=4'b1011; nib=value[11:8];  end
      2'b11: begin an=4'b0111; nib=value[15:12]; end
    endcase
  end
  wire [6:0] seg_w;
  hex7 uhex(nib, seg_w);
  always @* seg = seg_w;
endmodule

// ========================= TOP Basys3: carga por bloques de 8 bits =========================
//
// Controles (SW / BTN):
//  - SW[7:0]   : bus de entrada para 8 bits (hex) a cargar.
//  - SW[8]     : 0 -> cargar en A ; 1 -> cargar en B.
//  - SW[10:9]  : op_code[1:0] (00=ADD,01=SUB,10=MUL,11=DIV).
//  - SW[11]    : mode_fp (0=half-16b, 1=single-32b).
//  - SW[13:12] : round_mode (00=nearest-even; hoy no se usa en tu core).
//  - SW[14]    : qué 16 bits mostrar en 7seg (0=LSB, 1=MSB).
//
//  - BTNL : LOAD 8 bits en el bloque seleccionado (chunk_idx).
//  - BTNR : NEXT bloque (avanza chunk_idx -> 0..1 si half, 0..3 si single).
//  - BTNC : START (ejecuta operación; produce 'valid_out' un ciclo).
//  - BTND : RESET síncrono.
//  - BTNU : sin uso funcional aquí (libre), puedes reasignarlo si quieres.
//
// Indicadores (LED):
//  - LED[4:0]  : flags = {inexact(0), underflow(1), overflow(2), div0(3), invalid(4)} mapeados abajo.
//  - LED[6]    : valid_out.
//  - LED[7]    : sel_b (1=B).
//  - LED[8]    : mode_fp (1=single).
//  - LED[11:9] : op_code.
//  - LED[13:12]: chunk_idx (binario: 00..11).
//  - LED[15]   : tick lento de clock divider (para "ver" el reloj).
//
module top_basys3_fp_alu(
  input         CLK100MHZ,
  input  [15:0] SW,
  input         BTNC, BTNU, BTND, BTNL, BTNR,
  output [15:0] LED,
  output [3:0]  AN,
  output        CA, CB, CC, CD, CE, CF, CG, DP
);
  // ----------------- Clock divider (LED[15] parpadea ~1 Hz aprox) -----------------
  reg [26:0] clkdiv;
  always @(posedge CLK100MHZ) clkdiv <= clkdiv + 1'b1;
  wire slow_tick = clkdiv[26];  // ~0.75 Hz
  assign LED[15] = slow_tick;

  // ----------------- Señales de UI -----------------
  wire [7:0]  data_byte = SW[7:0];
  wire        sel_b     = SW[8];
  wire [1:0]  op2       = SW[10:9];
  wire        mode_fp   = SW[11];
  wire [1:0]  round_md  = SW[13:12];
  wire        show_upper= SW[14];

  // Pulsos limpios de botones
  wire p_start, p_reset, p_load, p_next;
  edge_up e_start(CLK100MHZ, BTNC, p_start);
  edge_up e_reset(CLK100MHZ, BTND, p_reset);
  edge_up e_load (CLK100MHZ, BTNL, p_load);
  edge_up e_next (CLK100MHZ, BTNR, p_next);

  // Chunk index (bloque de 8 bits a escribir): 0..1 (half) o 0..3 (single)
  reg [1:0] chunk_idx = 2'd0;
  always @(posedge CLK100MHZ) begin
    if (p_reset) chunk_idx <= 2'd0;
    else if (p_next) begin
      if (!mode_fp) begin
        // half: solo dos bloques 0..1
        chunk_idx <= (chunk_idx==2'd1) ? 2'd0 : (chunk_idx + 1'b1);
      end else begin
        // single: cuatro bloques 0..3
        chunk_idx <= chunk_idx + 1'b1;
      end
    end
  end

  // Registros de operandos A/B (32 bits)
  reg [31:0] op_a = 32'h0, op_b = 32'h0;

  // Escritura de 8 bits en el bloque seleccionado del operando seleccionado
  integer k;
  always @(posedge CLK100MHZ) begin
    if (p_reset) begin
      op_a <= 32'h0;
      op_b <= 32'h0;
    end else if (p_load) begin
      // Calcula posiciones del bloque
      case (chunk_idx)
        2'd0: begin
          if (!sel_b) op_a[7:0]    <= data_byte;
          else        op_b[7:0]    <= data_byte;
        end
        2'd1: begin
          if (!sel_b) op_a[15:8]   <= data_byte;
          else        op_b[15:8]   <= data_byte;
        end
        2'd2: begin
          if (!sel_b) op_a[23:16]  <= data_byte;
          else        op_b[23:16]  <= data_byte;
        end
        2'd3: begin
          if (!sel_b) op_a[31:24]  <= data_byte;
          else        op_b[31:24]  <= data_byte;
        end
      endcase
    end
  end

  // ----------------- Instancia del wrapper de ALU -----------------
  wire [31:0] y;
  wire        valid;
  wire [4:0]  flags_wrapped; // {invalid, div0, overflow, underflow, inexact}
  wire        rst_sync = p_reset;

  fp_alu DUT (
    .clk(CLK100MHZ), .rst(rst_sync), .start(p_start),
    .op_a(op_a), .op_b(op_b),
    .op_code({1'b0, op2}),      // dejamos MSB en 0 por ahora
    .mode_fp(mode_fp), .round_mode(round_md),
    .result(y), .valid_out(valid), .flags(flags_wrapped)
  );

  // ----------------- LEDs de estado (mapeo pedido) -----------------
  // El enunciado pone flags[4:0]; aquí mostramos cada uno en un LED:
  // flags_wrapped = {invalid(4), div0(3), overflow(2), underflow(1), inexact(0)}
  assign LED[0] = flags_wrapped[0]; // inexact
  assign LED[1] = flags_wrapped[1]; // underflow
  assign LED[2] = flags_wrapped[2]; // overflow
  assign LED[3] = flags_wrapped[3]; // div-by-zero
  assign LED[4] = flags_wrapped[4]; // invalid

  assign LED[6] = valid;           // valid_out
  assign LED[7] = sel_b;           // 0=A, 1=B
  assign LED[8] = mode_fp;         // 0=half, 1=single
  assign LED[11:9] = {1'b0, op2};  // op_code visible
  assign LED[13:12] = chunk_idx;   // bloque que estás cargando (binario)

  // ----------------- 7 segmentos: muestra resultado en HEX -----------------
  // Si SW[14]=0 -> LSB 16 bits; si =1 -> MSB 16 bits.
  // En half, los MSB serán 0 (el resultado válido vive en los 16 LSB).
  wire [15:0] seg_val = show_upper ? y[31:16] : y[15:0];

  wire [3:0]  AN_w;
  wire [6:0]  SEG_w;
  sevenseg_mux disp(.clk(CLK100MHZ), .value(seg_val), .an(AN_w), .seg(SEG_w), .dp(DP));

  assign AN = AN_w;
  assign {CA,CB,CC,CD,CE,CF,CG} = SEG_w;

endmodule
