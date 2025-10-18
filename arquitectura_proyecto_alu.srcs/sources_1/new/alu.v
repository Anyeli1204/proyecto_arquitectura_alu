`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.10.2025 15:27:41
// Design Name: 
// Module Name: alu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module alu #(parameter system = 16) (a, b, op, y, ALUFlags);

  initial begin
    if (system != 16 && system != 32) begin
      $display("Error: system parameter must be 16 or 32");
      $finish;
    end
  end

  // Si es half o single
  // MBS <- Mantissa Bit Size
  // EXP <- Exponent Bit Size
  // SP <- Sign Position
  // BS <- Bit Size
  localparam MBS = (system == 16) ? 9 : 22;
  localparam EBS = (system == 16) ? 4  : 7;
  localparam BS = system - 1;

  // ============== PASO 1: Verificar casos especiales ==============
  wire is_special;
  wire [BS:0] special_result;
  wire special_invalid, special_div_zero;

  input[BS: 0] a, b;
  input[1:0] op;

   // [4]=invalid, [3]=div_zero, [2]=overflow, [1]=underflow, [0]=inexact
  output reg [4:0] ALUFlags;
  output reg [BS: 0] y;

  fp16_special_case_handler #(.MBS(MBS), .EBS(EBS), .BS(BS)) special_handler(
    .a(a),
    .b(b),
    .op(op),
    .is_special_case(is_special),
    .special_result(special_result),
    .invalid_op(special_invalid),
    .div_by_zero(special_div_zero)
  );

// ============== PASO 2: Operaciones normales ==============
  wire [BS:0] add_y, sub_y, mul_y, div_y;
  wire ov_add, un_add, ix_add;
  wire ov_sub, un_sub, ix_sub;
  wire ov_mul, un_mul, iv_mul, ix_mul;
  wire ov_div, un_div, iv_div, ix_div;

  Suma16Bits #(.MBS(MBS), .EBS(EBS), .BS(BS)) 
  U_ADD(
    .S(a), .R(b), .F(add_y),
    .overflow(ov_add), .underflow(un_add), .inexact(ix_add)
  );

  Suma16Bits #(.MBS(MBS), .EBS(EBS), .BS(BS)) 
  U_SUB(
    .S(a), .R({~b[BS], b[BS-1:0]}), .F(sub_y),
    .overflow(ov_sub), .underflow(un_sub), .inexact(ix_sub)
  );

  ProductHP #(.MBS(MBS), .EBS(EBS), .BS(BS)) 
  U_MUL(
    .S(a), .R(b), .F(mul_y),
    .overflow(ov_mul), .underflow(un_mul),
    .inv_op(iv_mul), .inexact(ix_mul)
  );

  DivHP #(.MBS(MBS), .EBS(EBS), .BS(BS)) 
  U_DIV(
    .S(a), .R(b), .F(div_y),
    .overflow(ov_div), .underflow(un_div),
    .inv_op(iv_div), .inexact(ix_div)
  );

  // ============== PASO 3: Clasificar resultado especial ==============
  wire [EBS:0] special_exp = special_result[BS-1:BS-EBS-1];
  wire [MBS:0] special_man = special_result[MBS:0];
  wire special_is_inf = (special_exp == {EBS+1{1'b1}}) && (special_man == {MBS+1{1'b0}});
  wire special_is_denorm = (special_exp == {EBS+1{1'b0}}) && (special_man != {MBS+1{1'b0}});
  

  // ============== PASO 4: Selección de resultado y flags ==============
  always @(*) begin
    // Si es caso especial, usar resultado hardcodeado
    if (is_special) begin
      y = special_result;
      
      // ? FLAGS PARA CASOS ESPECIALES - Asignación completa
      // Formato: {invalid, div_zero, overflow, underflow, inexact}
      if (special_div_zero) begin
        // División por cero: marca div_zero Y overflow (resultado es Inf)
        ALUFlags = {special_invalid, 1'b1, 1'b1, special_is_denorm, 1'b0};
      end else if (special_is_inf && !special_invalid) begin
        // Operación con Inf: marca overflow, NO div_zero
        ALUFlags = {1'b0, 1'b0, 1'b1, special_is_denorm, 1'b0};
      end else if (special_invalid) begin
        // NaN: marca invalid, nada más
        ALUFlags = {1'b1, 1'b0, 1'b0, special_is_denorm, 1'b0};
      end else begin
        // Otros casos especiales (denormal, cero)
        ALUFlags = {1'b0, 1'b0, 1'b0, special_is_denorm, 1'b0};
      end
    end
    // Caso normal: usar resultado de operación
    else begin
      case (op)
        2'b00: begin // ADD
          y = add_y;
          ALUFlags = {1'b0, 1'b0, ov_add, un_add, ix_add};
        end
        2'b01: begin // SUB
          y = sub_y;
          ALUFlags = {1'b0, 1'b0, ov_sub, un_sub, ix_sub};
        end
        2'b10: begin // MUL
          y = mul_y;
          ALUFlags = {iv_mul, 1'b0, ov_mul, un_mul, ix_mul};
        end
        2'b11: begin // DIV
          y = div_y;
          ALUFlags = {iv_div, 1'b0, ov_div, un_div, ix_div};
        end
        default: begin
          y = {BS+1{1'b0}};
          ALUFlags = 5'b00000;
        end
      endcase
    end
  end

endmodule

