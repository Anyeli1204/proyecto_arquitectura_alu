module alu(
  input  [15:0] a,
  input  [15:0] b,
  input  [1:0]  op,
  output reg [15:0] y,
  output reg [4:0]  ALUFlags  // {invalid, div_zero, overflow, underflow, inexact}
);

  // ============== PASO 1: Verificar casos especiales ==============
  wire is_special;
  wire [15:0] special_result;
  wire special_invalid, special_div_zero;
  
  fp16_special_case_handler special_handler(
    .a(a),
    .b(b),
    .op(op),
    .is_special_case(is_special),
    .special_result(special_result),
    .invalid_op(special_invalid),
    .div_by_zero(special_div_zero)
  );
  
  // ============== PASO 2: Operaciones normales ==============
  wire [15:0] add_y, sub_y, mul_y, div_y;
  wire ov_add, un_add, ix_add;
  wire ov_sub, un_sub, ix_sub;
  wire ov_mul, un_mul, iv_mul, ix_mul;
  wire ov_div, un_div, iv_div, ix_div;
  
  Suma16Bits U_ADD(
    .S(a), .R(b), .F(add_y),
    .overflow(ov_add), .underflow(un_add), .inexact(ix_add)
  );

  Suma16Bits U_SUB(
    .S(a), .R({~b[15], b[14:0]}), .F(sub_y),
    .overflow(ov_sub), .underflow(un_sub), .inexact(ix_sub)
  );

  ProductHP U_MUL(
    .S(a), .R(b), .F(mul_y),
    .overflow(ov_mul), .underflow(un_mul),
    .inv_op(iv_mul), .inexact(ix_mul)
  );

  DivHP U_DIV(
    .S(a), .R(b), .F(div_y),
    .overflow(ov_div), .underflow(un_div),
    .inv_op(iv_div), .inexact(ix_div)
  );
  
  // ============== PASO 3: Clasificar resultado especial ==============
  wire [4:0] special_exp = special_result[14:10];
  wire [9:0] special_man = special_result[9:0];
  wire special_is_inf = (special_exp == 5'd31) && (special_man == 10'd0);
  wire special_is_denorm = (special_exp == 5'd0) && (special_man != 10'd0);
  
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
          y = 16'h0000;
          ALUFlags = 5'b00000;
        end
      endcase
    end
  end
  
endmodule