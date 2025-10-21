// top_basys3_fp_alu.v
`timescale 1ns/1ps

//======================= Wrapper: adapta 'alu' al enunciado =======================
module fp_alu #(
  parameter SUPPORT_SINGLE = 1  // pon 0 si a�n no usas 32 bits
)(
  input              clk,
  input              rst,
  input              start,
  input       [31:0] op_a,
  input       [31:0] op_b,
  input        [2:0] op_code,     // 000=ADD,001=SUB,010=MUL,011=DIV
  input              mode_fp,     // 0=half(16), 1=single(32)
  input        [1:0] round_mode,  // 00=nearest-even (no usado por ahora)
  output reg  [31:0] result,
  output reg         valid_out,
  output reg   [4:0] flags        // {invalid, div0, ovf, unf, inx}
);
  wire [1:0] op2 = op_code[1:0]; // solo usamos 2 bits

  // ALU half
  wire [15:0] y16; wire [4:0] f16;
  alu #(.system(16)) u_alu16 (
    .a(op_a[15:0]), .b(op_b[15:0]), .op(op2),
    .y(y16), .ALUFlags(f16)
  );

  // ALU single (opcional)
  wire [31:0] y32; wire [4:0] f32;
  generate if (SUPPORT_SINGLE) begin : G_SINGLE
    alu #(.system(32)) u_alu32 (
      .a(op_a), .b(op_b), .op(op2),
      .y(y32), .ALUFlags(f32)
    );
  end else begin : G_NOSINGLE
    assign y32 = 32'h0000_0000;
    assign f32 = 5'b0;
  end endgenerate

  // Multiplexor de salida (combi)
  reg [31:0] next_result; reg [4:0] next_flags;
  always @* begin
    if (!mode_fp) begin
      next_result = {16'b0, y16}; // half en LSBs
      next_flags  = f16;
    end else begin
      next_result = y32;
      next_flags  = f32;
    end
  end

  // Handshake: captura en el ciclo con start=1
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
        valid_out <= 1'b1;
      end
    end
  end
endmodule

//==================== Sincronizador y pulso por flanco (btns) ====================
module sync_2ff(input clk, input d, output reg q);
  reg q1 = 1'b0;  initial q = 1'b0;
  always @(posedge clk) begin q1 <= d; q <= q1; end
endmodule

module edge_up(input clk, input btn_raw, output pulse);
  wire s; reg s_d = 1'b0;
  sync_2ff u1(clk, btn_raw, s);
  always @(posedge clk) s_d <= s;
  assign pulse = s & ~s_d;
endmodule

// ========================= 7 segmentos (�NODO COM�N, activo en BAJO) =========================
module hex7(input [3:0] nib, output reg [6:0] seg);
  // seg = {a,b,c,d,e,f,g} ; 0 enciende
  always @* begin
    case(nib)
      4'h0: seg = 7'b0000001;
      4'h1: seg = 7'b1001111;
      4'h2: seg = 7'b0010010;
      4'h3: seg = 7'b0000110;
      4'h4: seg = 7'b1001100;
      4'h5: seg = 7'b0100100;
      4'h6: seg = 7'b0100000;
      4'h7: seg = 7'b0001111;
      4'h8: seg = 7'b0000000;
      4'h9: seg = 7'b0000100;
      4'hA: seg = 7'b0001000;
      4'hB: seg = 7'b1100000;
      4'hC: seg = 7'b0110001;
      4'hD: seg = 7'b1000010;
      4'hE: seg = 7'b0110000;
      4'hF: seg = 7'b0111000;
      default: seg = 7'b1111111;
    endcase
  end
endmodule

module sevenseg_mux(
  input        clk,           // 100 MHz
  input [15:0] value,         // 4 nibbles HEX
  output reg [3:0] an,        // �nodos (activos en bajo)
  output reg [6:0] seg,       // segmentos (activos en bajo)
  output       dp
);
  assign dp = 1'b1; // punto apagado
  reg [15:0] refresh_cnt = 16'd0;
  always @(posedge clk) refresh_cnt <= refresh_cnt + 1'b1;

  wire [1:0] sel = refresh_cnt[15:14];
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

//======================== TOP Basys3: carga por bloques de 8 bits ========================
module top_basys3_fp_alu #(
  parameter SUPPORT_SINGLE = 1
)(
  input         CLK100MHZ,
  input  [15:0] SW,
  input         BTNC, BTNU, BTND, BTNL, BTNR,
  output [15:0] LED,
  output [3:0]  AN,
  output        CA, CB, CC, CD, CE, CF, CG, DP
);
  //--------------- Clock divider visible en LED[15] ---------------
  reg [26:0] clkdiv = 27'd0;
  always @(posedge CLK100MHZ) clkdiv <= clkdiv + 1'b1;
  wire slow_tick = clkdiv[26];

  //--------------- UI (switches) ---------------
  wire [7:0] data_byte  = SW[7:0];
  wire       sel_b      = SW[8];      // 0=A, 1=B
  wire [1:0] op2        = SW[10:9];   // 00=ADD,01=SUB,10=MUL,11=DIV
  wire       mode_fp    = SW[11];     // 0=half, 1=single
  wire [1:0] round_md   = SW[13:12];  // reservado
  wire       show_upper = SW[14];
  wire       progress_mode = SW[15];  // LEDs de progreso

  //--------------- Botones (sincronizados) ---------------
  wire p_start, p_reset, p_load, p_next;
  edge_up e_start(CLK100MHZ, BTNC, p_start);
  edge_up e_reset(CLK100MHZ, BTND, p_reset);
  edge_up e_load (CLK100MHZ, BTNL, p_load);
  edge_up e_next (CLK100MHZ, BTNR, p_next);
  wire rst_sync = p_reset;

  //--------------- Selecci�n de bloque 0..1 (half) o 0..3 (single) ---------------
  reg [1:0] chunk_idx = 2'd0;
  always @(posedge CLK100MHZ) begin
    if (rst_sync) chunk_idx <= 2'd0;
    else if (p_next) begin
      if (!mode_fp) chunk_idx <= (chunk_idx==2'd1) ? 2'd0 : (chunk_idx + 1'b1);
      else          chunk_idx <= chunk_idx + 1'b1; // wrap natural en 2 bits
    end
  end

  //--------------- Registros de operandos ----------------
  reg [31:0] op_a = 32'h0, op_b = 32'h0;
  always @(posedge CLK100MHZ) begin
    if (rst_sync) begin
      op_a <= 32'h0; op_b <= 32'h0;
    end else if (p_load) begin
      case (chunk_idx)
        2'd0: begin if (!sel_b) op_a[7:0]    <= data_byte; else op_b[7:0]    <= data_byte; end
        2'd1: begin if (!sel_b) op_a[15:8]   <= data_byte; else op_b[15:8]   <= data_byte; end
        2'd2: begin if (!sel_b) op_a[23:16]  <= data_byte; else op_b[23:16]  <= data_byte; end
        2'd3: begin if (!sel_b) op_a[31:24]  <= data_byte; else op_b[31:24]  <= data_byte; end
      endcase
    end
  end

  //--------------- Progreso visual (cu�ntos bytes ya cargaste) ---------------
  reg [3:0] loaded_mask_A = 4'b0000;
  reg [3:0] loaded_mask_B = 4'b0000;
  always @(posedge CLK100MHZ) begin
    if (rst_sync) begin
      loaded_mask_A <= 4'b0000;
      loaded_mask_B <= 4'b0000;
    end else if (p_load) begin
      if (!sel_b) loaded_mask_A[chunk_idx] <= 1'b1;
      else        loaded_mask_B[chunk_idx] <= 1'b1;
    end
  end

  // Popcount sencillo (0..4)
  wire [2:0] bytes_loaded_A = loaded_mask_A[0] + loaded_mask_A[1] + loaded_mask_A[2] + loaded_mask_A[3];
  wire [2:0] bytes_loaded_B = loaded_mask_B[0] + loaded_mask_B[1] + loaded_mask_B[2] + loaded_mask_B[3];

  // Mapea #bytes a 8 LEDs o 16 LEDs
  function [15:0] prog_from_count;
    input [2:0] n;
    begin
      if (n >= 2)      prog_from_count = 16'hFFFF; // >=2 bytes ? 16 LEDs
      else if (n >= 1) prog_from_count = 16'h00FF; // 1 byte ? 8 LEDs
      else             prog_from_count = 16'h0000;
    end
  endfunction

  // Progreso del operando actualmente seleccionado (A/B via SW8)
  wire [15:0] prog_leds_sel = sel_b ? prog_from_count(bytes_loaded_B)
                                    : prog_from_count(bytes_loaded_A);

  //--------------- ALU wrapper ---------------
  wire [31:0] y;
  wire        valid;
  wire [4:0]  flags_wrapped; // {invalid, div0, ovf, unf, inx}
  fp_alu #(.SUPPORT_SINGLE(SUPPORT_SINGLE)) DUT (
    .clk(CLK100MHZ), .rst(rst_sync), .start(p_start),
    .op_a(op_a), .op_b(op_b),
    .op_code({1'b0, op2}), .mode_fp(mode_fp), .round_mode(round_md),
    .result(y), .valid_out(valid), .flags(flags_wrapped)
  );

  // Latch para mostrar �ltimo resultado/flags
  reg [31:0] disp_latch = 32'h0000_0000;
  reg [4:0]  flags_latch = 5'b0;
  always @(posedge CLK100MHZ or posedge rst_sync) begin
    if (rst_sync) begin
      disp_latch  <= 32'h0000_0000;
      flags_latch <= 5'b0;
    end else if (valid) begin
      disp_latch  <= y;
      flags_latch <= flags_wrapped;
    end
  end

  //--------------- LEDs (estado) ---------------
  wire [15:0] leds_status;
  assign leds_status[0]    = flags_latch[0];    // inexact
  assign leds_status[1]    = flags_latch[1];    // underflow
  assign leds_status[2]    = flags_latch[2];    // overflow
  assign leds_status[3]    = flags_latch[3];    // div-by-zero
  assign leds_status[4]    = flags_latch[4];    // invalid
  assign leds_status[5]    = 1'b0;              // libre
  assign leds_status[6]    = valid;             // pulso "listo"
  assign leds_status[7]    = sel_b;             // 0=A,1=B
  assign leds_status[8]    = mode_fp;           // 0=half,1=single
  assign leds_status[11:9] = {1'b0, op2};       // operaci�n
  assign leds_status[13:12]= chunk_idx;         // bloque actual
  assign leds_status[14]   = show_upper;        // MSB/LSB en 7seg (single)
  assign leds_status[15]   = slow_tick;         // tick visual

  // -------- Selecci�n de modo de LEDs --------
  assign LED = progress_mode ? prog_leds_sel : leds_status;

  //--------------- 7 segmentos (HEX del resultado) ---------------
  wire [15:0] seg_val = show_upper ? disp_latch[31:16] : disp_latch[15:0];
  wire [3:0]  AN_w;  wire [6:0] SEG_w;
  sevenseg_mux disp(.clk(CLK100MHZ), .value(seg_val), .an(AN_w), .seg(SEG_w), .dp(DP));
  assign AN = AN_w;
  assign {CA,CB,CC,CD,CE,CF,CG} = SEG_w;

endmodule
