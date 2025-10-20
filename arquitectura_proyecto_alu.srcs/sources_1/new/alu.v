`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: alu
// Description: ALU IEEE-754 half/single (16/32) con flags {invalid, div0, ovf, unf, inx}
// Dependencies: fp16_special_case_handler, Suma16Bits, ProductHP, DivHP
//////////////////////////////////////////////////////////////////////////////////

module alu #(parameter system = 16) (
  input  wire [system-1:0] a,
  input  wire [system-1:0] b,
  input  wire [1:0]        op,       // 00=ADD, 01=SUB, 10=MUL, 11=DIV
  output reg  [system-1:0] y,
  output reg  [4:0]        ALUFlags  // {invalid, div0, ovf, unf, inx}
);

  initial begin
    if (system != 16 && system != 32) begin
      $display("Error: system parameter must be 16 or 32");
      $finish;
    end
  end

  // ---------- Formato ----------
  localparam integer EXP_BITS  = (system == 16) ? 5  : 8;
  localparam integer FRAC_BITS = (system == 16) ? 10 : 23;
  localparam integer SIGN_POS  = system - 1;

  // Compatibilidad con subm�dulos
  localparam integer MBS = FRAC_BITS - 1;
  localparam integer EBS = EXP_BITS  - 1;
  localparam integer BS  = system - 1;

  // ---------- Casos especiales ----------
  wire                        is_special;
  wire [BS:0]                 special_result;
  wire                        special_invalid, special_div_zero;

  fp16_special_case_handler #(.MBS(MBS), .EBS(EBS), .BS(BS)) special_handler(
    .a(a),
    .b(b),
    .op(op),
    .is_special_case(is_special),
    .special_result(special_result),
    .invalid_op(special_invalid),
    .div_by_zero(special_div_zero)
  );

  // ---------- Camino normal ----------
  wire [BS:0] add_y, sub_y, mul_y, div_y;
  wire ov_add, un_add, ix_add;
  wire ov_sub, un_sub, ix_sub;
  wire ov_mul, un_mul, iv_mul, ix_mul;
  wire ov_div, un_div, iv_div, ix_div;

  Suma16Bits #(.MBS(MBS), .EBS(EBS), .BS(BS)) U_ADD (
    .S(a), .R(b), .F(add_y),
    .overflow(ov_add), .underflow(un_add), .inexact(ix_add)
  );

  // SUB = ADD con signo de b invertido
  Suma16Bits #(.MBS(MBS), .EBS(EBS), .BS(BS)) U_SUB (
    .S(a), .R({~b[BS], b[BS-1:0]}), .F(sub_y),
    .overflow(ov_sub), .underflow(un_sub), .inexact(ix_sub)
  );

  ProductHP #(.MBS(MBS), .EBS(EBS), .BS(BS)) U_MUL (
    .S(a), .R(b), .F(mul_y),
    .overflow(ov_mul), .underflow(un_mul),
    .inv_op(iv_mul), .inexact(ix_mul)
  );

  DivHP #(.MBS(MBS), .EBS(EBS), .BS(BS)) U_DIV (
    .S(a), .R(b), .F(div_y),
    .overflow(ov_div), .underflow(un_div),
    .inv_op(iv_div), .inexact(ix_div)
  );

  // ---------- Clasificaci�n para rama especial ----------
  wire [EXP_BITS-1:0]  sp_exp  = special_result[SIGN_POS-1 -: EXP_BITS];
  wire [FRAC_BITS-1:0] sp_frac = special_result[FRAC_BITS-1:0];
  wire special_is_inf    = (sp_exp == {EXP_BITS{1'b1}}) && (sp_frac == {FRAC_BITS{1'b0}});
  wire special_is_denorm = (sp_exp == {EXP_BITS{1'b0}}) && (sp_frac != {FRAC_BITS{1'b0}});

  // ---------- Regs auxiliares (a nivel de m�dulo) ----------
  reg [BS:0]           y_sel;    // salida cruda de la unidad elegida
  reg                  ix_sel;   // inexact de la unidad
  reg                  iv_sel;   // invalid de la unidad (MUL/DIV)

  reg [BS:0]           y_pre;    // salida tras saturaci�n a �Inf si hubo ov_raw
  reg                  ov_raw, un_raw; // flags crudas de la unidad
  reg                  sign_res; // signo para saturaci�n

  reg [EXP_BITS-1:0]   r_exp, a_exp, b_exp;
  reg [FRAC_BITS-1:0]  r_frac, a_frac, b_frac;
  reg                  r_is_inf, r_is_zero, r_is_sub;
  reg                  a_is_zero, b_is_zero;

  reg                  ovf, unf, inx;

  wire is_pos_inf_a;
  wire is_neg_inf_a;
  is_inf_detector #(.MBS(MBS), .EBS(EBS), .BS(BS)) inf_det_S (
    .value(a),
    .is_posInf(is_pos_inf_a),
    .is_negInf(is_neg_inf_a)
  );

  wire is_pos_inf_b;
  wire is_neg_inf_b;
  is_inf_detector #(.MBS(MBS), .EBS(EBS), .BS(BS)) inf_det_R (
    .value(b),
    .is_posInf(is_pos_inf_b),
    .is_negInf(is_neg_inf_b)
  );


  wire any_pos_inf = is_pos_inf_a | is_pos_inf_b;
  wire any_neg_inf = is_neg_inf_a | is_neg_inf_b;

  wire is_inv_a, is_inv_b;
  is_invalid_val #(.MBS(MBS), .EBS(EBS), .BS(BS)) inv_val_1(a, is_inv_a);
  is_invalid_val #(.MBS(MBS), .EBS(EBS), .BS(BS)) inv_val_2(b, is_inv_b);

  // ================== Selecci�n y flags ==================
  always @* begin
    // Defaults para evitar latches
    y        = {BS+1{1'b0}};
    ALUFlags = 5'b0;

    y_sel  = {BS+1{1'b0}};
    y_pre  = {BS+1{1'b0}};
    ix_sel = 1'b0;
    iv_sel = 1'b0;
    ov_raw = 1'b0;
    un_raw = 1'b0;
    sign_res = 1'b0;

    r_exp = {EXP_BITS{1'b0}};
    r_frac = {FRAC_BITS{1'b0}};
    r_is_inf = 1'b0; r_is_zero = 1'b0; r_is_sub = 1'b0;

    a_exp = a[SIGN_POS-1 -: EXP_BITS];
    a_frac = a[FRAC_BITS-1:0];
    b_exp = b[SIGN_POS-1 -: EXP_BITS];
    b_frac = b[FRAC_BITS-1:0];
    a_is_zero = (a_exp == {EXP_BITS{1'b0}}) && (a_frac == {FRAC_BITS{1'b0}});
    b_is_zero = (b_exp == {EXP_BITS{1'b0}}) && (b_frac == {FRAC_BITS{1'b0}});

    ovf = 1'b0; unf = 1'b0; inx = 1'b0;

    // ---------- Casos especiales ----------
    if (is_special) begin
      y = special_result;

      // {invalid, div0, ovf, unf, inx}
      if (special_div_zero) begin
        // x/�0 con x finito ? �Inf; SOLO div0=1
        ALUFlags = {special_invalid, 1'b1, 1'b0, 1'b1, 1'b0};
      end else if (special_invalid && (is_inv_a | is_inv_b)) begin
        // NaN (0/0, ?-?, 0*?, etc.)
        ALUFlags = 5'b1_0_0_0_0;
      end else if (special_is_inf) begin
        ALUFlags = 5'b0_0_0_0_1;
        ALUFlags[1] = any_neg_inf;
        ALUFlags[2] = any_pos_inf;

      end else begin
        // Subnormal/cero forzados por el handler
        ALUFlags = {1'b0, 1'b0, 1'b0, (special_is_denorm ? 1'b1 : 1'b0), 1'b0};
      end
    end

    // ---------- Operaci�n normal ----------
    else begin
      // 1) Selecci�n de resultado y se�ales de la unidad
      case (op)
        2'b00: begin y_sel = add_y; ix_sel = ix_add; iv_sel = 1'b0;     ov_raw = ov_add; un_raw = un_add; end // ADD
        2'b01: begin y_sel = sub_y; ix_sel = ix_sub; iv_sel = 1'b0;     ov_raw = ov_sub; un_raw = un_sub; end // SUB
        2'b10: begin y_sel = mul_y; ix_sel = ix_mul; iv_sel = iv_mul;   ov_raw = ov_mul; un_raw = un_mul; end // MUL
        2'b11: begin y_sel = div_y; ix_sel = ix_div; iv_sel = iv_div;   ov_raw = ov_div; un_raw = un_div; end // DIV
        default: begin y_sel = {BS+1{1'b0}}; ix_sel = 1'b0; iv_sel = 1'b0; ov_raw = 1'b0; un_raw = 1'b0; end
      endcase

      // 2) Saturaci�n a �Inf si la UNIDAD report� overflow (evita NaN=7FFF en hardware)
      sign_res = (op==2'b10 || op==2'b11) ? (a[SIGN_POS] ^ b[SIGN_POS])  // MUL/DIV
                                          :  y_sel[SIGN_POS];             // ADD/SUB
      y_pre = y_sel;
      if (ov_raw) begin
        y_pre = { sign_res, {EXP_BITS{1'b1}}, {FRAC_BITS{1'b0}} }; // �Inf
      end
      if (un_raw) begin
        y_pre = { sign_res, {EXP_BITS{1'b0}}, {FRAC_BITS{1'b0}} };
      end

      // 3) Clasificaci�n del RESULTADO FINAL (ya normalizado/redondeado/saturado)
      r_exp   = y_pre[SIGN_POS-1 -: EXP_BITS];
      r_frac  = y_pre[FRAC_BITS-1:0];
      r_is_inf  = (r_exp == {EXP_BITS{1'b1}}) && (r_frac == {FRAC_BITS{1'b0}});
      r_is_zero = (r_exp == {EXP_BITS{1'b0}}) && (r_frac == {FRAC_BITS{1'b0}});
      r_is_sub  = (r_exp == {EXP_BITS{1'b0}}) && (r_frac != {FRAC_BITS{1'b0}});

      // 4) Flags derivadas del resultado final
      ovf = r_is_inf || ov_raw;

      // Underflow: subnormal, o 0 por "tininess" SOLO en MUL/DIV (no por cancelaci�n en ADD/SUB)
      // op[1]==1 ? 10(MUL) o 11(DIV)
      unf = r_is_sub || un_raw || ((op[1] == 1'b1) && r_is_zero && !a_is_zero && !b_is_zero);

      // Inexact: lo que diga la unidad, o si hubo ovf/unf
      inx = ix_sel | ovf | unf;

      // 5) Publicar salida y flags (invalid/div0 ya cubiertos en rama especial)
      y        = y_pre;
      ALUFlags = {iv_sel, 1'b0 /*div0*/, ovf, unf, inx};
    end
  end

endmodule
