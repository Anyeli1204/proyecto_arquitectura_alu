`timescale 1ns / 1ps

module alu #(parameter system = 16) (
  input  wire [system-1:0] a,
  input  wire [system-1:0] b,
  input  wire [1:0]        op,       // 00=ADD, 01=SUB, 10=MUL, 11=DIV
  output reg  [system-1:0] y,
  output reg  [4:0]        ALUFlags  // {invalid, div0, ovf, unf, inx}
);
  initial begin
    if (system != 16 && system != 32) begin
      $display("Error: system must be 16 or 32");
      $finish;
    end
  end

  // Bits de formato (clarito)
  localparam integer EXP_BITS  = (system == 16) ? 5  : 8;
  localparam integer FRAC_BITS = (system == 16) ? 10 : 23;
  localparam integer SIGN_POS  = system - 1;

  // Compatibilidad con tus parámetros internos (si tus submódulos los usan así)
  localparam integer MBS = FRAC_BITS - 1;
  localparam integer EBS = EXP_BITS  - 1;
  localparam integer BS  = system - 1;

  // ---------------- Casos especiales ----------------
  wire                        is_special;
  wire [BS:0]                 special_result;
  wire                        special_invalid, special_div_zero;

  // Si tu handler se llama distinto (p.ej. fp_special_case_handler), cambia aquí:
  fp16_special_case_handler #(.MBS(MBS), .EBS(EBS), .BS(BS)) SPECIAL (
    .a(a),
    .b(b),
    .op(op),
    .is_special_case(is_special),
    .special_result(special_result),
    .invalid_op(special_invalid),
    .div_by_zero(special_div_zero)
  );

  // ---------------- Camino normal ----------------
  wire [BS:0] add_y, sub_y, mul_y, div_y;
  wire ov_add, un_add, ix_add;
  wire ov_sub, un_sub, ix_sub;
  wire ov_mul, un_mul, iv_mul, ix_mul;
  wire ov_div, un_div, iv_div, ix_div;

  Suma16Bits #(.MBS(MBS), .EBS(EBS), .BS(BS)) U_ADD (
    .S(a), .R(b), .F(add_y),
    .overflow(ov_add), .underflow(un_add), .inexact(ix_add)
  );

  // Resta = sumar con signo de b invertido
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

  // ---------------- Flags para especiales (IEEE) ----------------
  // Extrae exp/frac de special_result por si los quisieras usar:
  wire [EXP_BITS-1:0]  sp_exp  = special_result[SIGN_POS-1 -: EXP_BITS];
  wire [FRAC_BITS-1:0] sp_frac = special_result[FRAC_BITS-1:0];
  wire special_is_inf    = (sp_exp == {EXP_BITS{1'b1}}) && (sp_frac == {FRAC_BITS{1'b0}});
  wire special_is_denorm = (sp_exp == {EXP_BITS{1'b0}})  && (sp_frac != {FRAC_BITS{1'b0}});

  // ---------------- Selección final ----------------
  always @* begin
    if (is_special) begin
      y = special_result;

      // IEEE754: div_by_zero ? resultado ±Inf, flag div0=1; no overflow aquí.
      if (special_div_zero) begin
        ALUFlags = {special_invalid, 1'b1, 1'b0, 1'b0, 1'b0};
      end
      else if (special_invalid) begin
        ALUFlags = 5'b1_0_0_0_0; // invalid=1
      end
      else if (special_is_inf) begin
        // Inf proveniente de operandos Inf no es overflow per se.
        ALUFlags = 5'b0_0_0_0_0;
      end
      else begin
        // Cero, denormal, etc.: sin inexact por defecto
        ALUFlags = {1'b0, 1'b0, 1'b0, (special_is_denorm ? 1'b1 : 1'b0), 1'b0};
      end
    end
    else begin
      case (op)
        2'b00: begin // ADD
          y        = add_y;
          ALUFlags = {1'b0, 1'b0, ov_add, un_add, ix_add};
        end
        2'b01: begin // SUB
          y        = sub_y;
          ALUFlags = {1'b0, 1'b0, ov_sub, un_sub, ix_sub};
        end
        2'b10: begin // MUL
          y        = mul_y;
          ALUFlags = {iv_mul, 1'b0, ov_mul, un_mul, ix_mul};
        end
        2'b11: begin // DIV
          y        = div_y;
          ALUFlags = {iv_div, 1'b0, ov_div, un_div, ix_div};
        end
        default: begin
          y        = {system{1'b0}};
          ALUFlags = 5'b0;
        end
      endcase
    end
  end
endmodule
