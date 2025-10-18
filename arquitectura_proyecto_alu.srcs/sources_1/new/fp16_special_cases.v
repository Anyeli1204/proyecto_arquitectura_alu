`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Módulo de manejo de casos especiales IEEE 754 Half-Precision
// Incluye detección de NaN, Inf, denormales, y generación de resultados especiales
//////////////////////////////////////////////////////////////////////////////////

// ============== DETECCIÓN DE CASOS ESPECIALES EN OPERANDOS ==============

module fp16_classifier(
  input [15:0] val,
  output is_zero,
  output is_denorm,
  output is_normal,
  output is_inf,
  output is_nan,
  output sign
);
  wire [4:0] exp = val[14:10];
  wire [9:0] man = val[9:0];
  
  assign sign = val[15];
  
  // Zero: exp=0, man=0
  assign is_zero = (exp == 5'd0) && (man == 10'd0);
  
  // Denormal: exp=0, man?0
  assign is_denorm = (exp == 5'd0) && (man != 10'd0);
  
  // Normal: 0 < exp < 31
  assign is_normal = (exp != 5'd0) && (exp != 5'd31);
  
  // Infinity: exp=31, man=0
  assign is_inf = (exp == 5'd31) && (man == 10'd0);
  
  // NaN: exp=31, man?0
  assign is_nan = (exp == 5'd31) && (man != 10'd0);
endmodule

// ============== GENERADOR DE VALORES ESPECIALES ==============

module fp16_special_values(
  input sign_in,
  output [15:0] pos_zero,
  output [15:0] neg_zero,
  output [15:0] pos_inf,
  output [15:0] neg_inf,
  output [15:0] qnan,        // Quiet NaN (señalización silenciosa)
  output [15:0] snan,        // Signaling NaN (señalización activa)
  output [15:0] signed_inf,  // Infinity con signo variable
  output [15:0] signed_zero  // Zero con signo variable
);
  // Valores hardcodeados IEEE 754
  assign pos_zero = 16'h0000;  // +0.0
  assign neg_zero = 16'h8000;  // -0.0
  assign pos_inf  = 16'h7C00;  // +Infinity
  assign neg_inf  = 16'hFC00;  // -Infinity
  assign qnan     = 16'h7E00;  // Quiet NaN (canonical)
  assign snan     = 16'h7D00;  // Signaling NaN
  
  // Con signo parametrizable
  assign signed_inf  = sign_in ? neg_inf : pos_inf;
  assign signed_zero = sign_in ? neg_zero : pos_zero;
endmodule

// ============== MANEJO DE CASOS ESPECIALES POR OPERACIÓN ==============

module fp16_special_case_handler(
  input [15:0] a,
  input [15:0] b,
  input [1:0] op,  // 00=ADD, 01=SUB, 10=MUL, 11=DIV
  
  output is_special_case,
  output [15:0] special_result,
  output invalid_op,
  output div_by_zero
);

  // Clasificar operandos
  wire a_zero, a_denorm, a_normal, a_inf, a_nan, a_sign;
  wire b_zero, b_denorm, b_normal, b_inf, b_nan, b_sign;
  
  fp16_classifier class_a(a, a_zero, a_denorm, a_normal, a_inf, a_nan, a_sign);
  fp16_classifier class_b(b, b_zero, b_denorm, b_normal, b_inf, b_nan, b_sign);
  
  // Valores especiales
  wire [15:0] pos_zero, neg_zero, pos_inf, neg_inf, qnan, snan;
  wire [15:0] signed_inf_a, signed_zero_a;
  
  fp16_special_values special(
    a_sign, pos_zero, neg_zero, pos_inf, neg_inf, qnan, snan,
    signed_inf_a, signed_zero_a
  );
  
  // Calcular signo del resultado (fuera del always)
  wire result_sign = a_sign ^ b_sign;
  
  // ==================== DETECCIÓN DE CASOS ESPECIALES ====================
  
  reg is_special;
  reg [15:0] result;
  reg invalid;
  reg div_zero;
  
  always @(*) begin
    is_special = 1'b0;
    result = 16'h0000;
    invalid = 1'b0;
    div_zero = 1'b0;
    
    // ====== CASO 1: Operandos NaN ======
    if (a_nan || b_nan) begin
      is_special = 1'b1;
      result = qnan;
      invalid = 1'b1;
    end
    
    // ====== CASO 2: SUMA/RESTA ======
    else if (op == 2'b00 || op == 2'b01) begin
      // Inf + Inf (signos iguales) = Inf
      // Inf - Inf (signos iguales) = NaN (INVALID)
      if (a_inf && b_inf) begin
        is_special = 1'b1;
        if ((op == 2'b00 && a_sign == b_sign) ||
            (op == 2'b01 && a_sign != b_sign)) begin
          result = signed_inf_a;
        end else begin
          result = qnan;
          invalid = 1'b1;
        end
      end
      // Inf + x = Inf
      else if (a_inf) begin
        is_special = 1'b1;
        result = a;
      end
      else if (b_inf) begin
        is_special = 1'b1;
        result = (op == 2'b00) ? b : {~b[15], b[14:0]};
      end
      // 0 + 0 = +0 (excepto -0 + -0 = -0)
      else if (a_zero && b_zero) begin
        is_special = 1'b1;
        result = (a_sign && b_sign) ? neg_zero : pos_zero;
      end
      // ? NUEVO: Denormal + 0 = Denormal
      else if (a_denorm && b_zero) begin
        is_special = 1'b1;
        result = a;
      end
      else if (a_zero && b_denorm) begin
        is_special = 1'b1;
        result = (op == 2'b00) ? b : {~b[15], b[14:0]};
      end
    end
    
    // ====== CASO 3: MULTIPLICACIÓN ======
    else if (op == 2'b10) begin
      // Inf × 0 = NaN (INVALID)
      if ((a_inf && b_zero) || (a_zero && b_inf)) begin
        is_special = 1'b1;
        result = qnan;
        invalid = 1'b1;
      end
      // Inf × x = ±Inf (x?0)
      else if (a_inf || b_inf) begin
        is_special = 1'b1;
        result = result_sign ? neg_inf : pos_inf;
      end
      // 0 × x = ±0
      else if (a_zero || b_zero) begin
        is_special = 1'b1;
        result = result_sign ? neg_zero : pos_zero;
      end
    end
    
    // ====== CASO 4: DIVISIÓN ======
    else if (op == 2'b11) begin
      // 0 / 0 = NaN (INVALID)
      if (a_zero && b_zero) begin
        is_special = 1'b1;
        result = qnan;
        invalid = 1'b1;
      end
      // Inf / Inf = NaN (INVALID)
      else if (a_inf && b_inf) begin
        is_special = 1'b1;
        result = qnan;
        invalid = 1'b1;
      end
      // x / 0 = ±Inf (DIVIDE BY ZERO, x?0)
      else if (b_zero && !a_zero) begin
        is_special = 1'b1;
        result = result_sign ? neg_inf : pos_inf;
        div_zero = 1'b1;
      end
      // Inf / x = ±Inf (x?Inf)
      else if (a_inf && !b_inf) begin
        is_special = 1'b1;
        result = result_sign ? neg_inf : pos_inf;
      end
      // x / Inf = ±0
      else if (b_inf && !a_inf) begin
        is_special = 1'b1;
        result = result_sign ? neg_zero : pos_zero;
      end
      // 0 / x = ±0 (x?0)
      else if (a_zero && !b_zero) begin
        is_special = 1'b1;
        result = result_sign ? neg_zero : pos_zero;
      end
    end
  end
  
  assign is_special_case = is_special;
  assign special_result = result;
  assign invalid_op = invalid;
  assign div_by_zero = div_zero;
  
endmodule

// ============== FLAGS IEEE 754 COMPLETOS ==============

module fp16_flags(
  input [15:0] result,
  input [15:0] a,
  input [15:0] b,
  input [1:0] op,
  input core_overflow,
  input core_underflow,
  input core_inexact,
  input special_invalid,
  input special_div_zero,
  
  output overflow,
  output underflow,
  output inexact,
  output invalid,
  output div_by_zero
);

  wire [4:0] exp_result = result[14:10];
  wire [9:0] man_result = result[9:0];
  
  // Clasificar resultado
  wire res_inf = (exp_result == 5'd31) && (man_result == 10'd0);
  wire res_nan = (exp_result == 5'd31) && (man_result != 10'd0);
  wire res_denorm = (exp_result == 5'd0) && (man_result != 10'd0);
  
  // OVERFLOW: resultado es infinito (no NaN)
  assign overflow = res_inf || core_overflow;
  
  // UNDERFLOW: resultado es denormal o flushed a cero con inexactitud
  assign underflow = res_denorm || core_underflow;
  
  // INEXACT: redondeo cambió el resultado
  assign inexact = core_inexact || underflow;
  
  // INVALID: operación no válida (NaN generado)
  assign invalid = res_nan || special_invalid;
  
  // DIVIDE BY ZERO: división por cero (genera infinito)
  assign div_by_zero = special_div_zero;
  
endmodule