`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.10.2025 15:23:27
// Design Name: 
// Module Name: SumaResta
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
module FullAdder(Si, Ri, Din, Debe, Dout);
  input Si, Ri, Din;
  output wire Debe, Dout;
   
  assign Debe = (Si & Ri) | (Ri & Din) | (Si & Din);
  assign Dout = Si ^ Ri ^ Din;
  
endmodule

module FullSub_add(Si, Ri, Din, Debe, Dout);
  input Si, Ri, Din;
  output wire Debe, Dout;
  
  assign Debe = (~Si & Ri) | (~Si & Din) | (Ri & Din);
  assign Dout = Si ^ Ri ^ Din;
  
endmodule

module RestaExp_sum(S, R, F);
  input [4:0] S, R;
  output wire[4: 0] F;
  wire [5:0] Debe;
  assign Debe[0] = 1'b0;
  genvar i;
  generate
    for(i = 0; i < 5; i = i + 1)
      FullSub_add sub_i(S[i], R[i], Debe[i], Debe[i+1], F[i]);
  endgenerate
 endmodule

module SumarExp(S, R, F);
  input [4:0] S, R;
  output wire[4: 0] F;
  wire [5:0] Debe;
  assign Debe[0] = 1'b0;
  genvar i;
  generate
    for(i = 0; i < 5; i = i + 1)
      FullAdder add_i(S[i], R[i], Debe[i], Debe[i+1], F[i]);
  endgenerate
endmodule

module mas_1_bit_expo(exp, F);
  input [4:0] exp;
  output [4:0] F;
  SumarExp add_exp(exp, 5'b00001, F);
endmodule

module restar_1_bit_expo_sum(exp, F);
  input [4:0] exp;
  output [4:0] F;
  RestaExp_sum sub_exp(exp, 5'b00001, F);
endmodule

module right_shift_pf_sum(mantisa, is_same_exp, shifts, F, lost_bits);
  input is_same_exp;
  input [9:0] mantisa;
  input [4:0] shifts;
  output [9:0] F;
  output lost_bits; 
  wire [20:0] full_value = {1'b1, mantisa, 10'b0};  // Bit implícito + mantisa + padding
  wire [20:0] shifted = full_value >> shifts;
  assign F = shifted[19:10];
  assign lost_bits = (shifts > 0) ? |shifted[9:0] : 1'b0;
endmodule
 
module SumMantisa(S, R, is_same_exp, ExpIn, ExpOut, F, lost_align);
  input is_same_exp;
  input [9:0] S, R;
  input [4:0] ExpIn;
  input lost_align;
  output wire[4:0] ExpOut;
  output wire[9:0] F;

  wire [10:0] A = {1'b1, S};
  wire [10:0] B = {1'b1, R};

   wire [10:0] sum_bits;   // suma bit a bit
  wire [11:0] C;          // cadena de carries (12 para cubrir carry final)
  assign C[0] = 1'b0;
  
  genvar i;
  generate
    for (i = 0; i < 11; i = i + 1) begin: ADD11
      FullAdder add_i(A[i], B[i], C[i], C[i+1], sum_bits[i]);
    end
  endgenerate
  wire        carry = C[11];
  wire [14:0] ms_for_round;
  wire [4:0] exp_for_round;
  
  assign ms_for_round = carry ? 
    {sum_bits[10:1], sum_bits[0], 3'b0, lost_align} :  // con carry: 10 bits + guard + sticky
    {sum_bits[9:0], 4'b0, lost_align};                 // sin carry: 10 bits + sticky
  
  assign exp_for_round = carry ? (ExpIn + 5'd1) : ExpIn;
  wire [9:0] frac_rounded;
  wire [4:0] exp_rounded;
  RoundNearestEven rne_sum(
    .ms(ms_for_round),
    .exp(exp_for_round),
    .ms_round(frac_rounded),
    .exp_round(exp_rounded)
  );
  assign F = frac_rounded;
  assign ExpOut = exp_rounded;
endmodule

module RestaMantisa(S, R, is_same_exp, is_mayus_exp, ExpIn, ExpOut, F, is_result_zero);
  
  input is_same_exp;
  input [9:0] S, R;
  input [4:0] ExpIn;
  input is_mayus_exp;
  
  output wire[4:0] ExpOut;
  output wire[9: 0] F;
  output wire is_result_zero;
  
  // Función que se encarga de encontrar el primer 1 de la mantisa, util para la resta.
function [4:0] first_one_9bits;
  input [9:0] val;
  integer idx;
  reg found;
  begin
    found = 0;
    first_one_9bits = 0;
    for(idx = 9; idx >= 0; idx = idx-1) begin
      
      if(val[idx] && !found) begin
        first_one_9bits = (10 - idx);
        found = 1;
      end
    end
   
  end
  // if idx = 0, significa que la resta da 0.
endfunction
  
  wire [10:0] Debe, Debe_e;
  wire [9: 0] F_aux, F_aux_e, F_to_use;
  assign Debe[0] = 1'b0;
  assign Debe_e[0] = 1'b0;
  
  genvar i;
  generate
    for(i = 0; i < 10; i = i + 1) begin
      FullSub_add sub_i(S[i], R[i], Debe[i], Debe[i+1], F_aux[i]);
      FullSub_add sub_i_extremo(R[i], S[i], Debe_e[i], Debe_e[i+1], F_aux_e[i]);
    end
  endgenerate
  
  wire[4:0] idx, idx_e, ExpAux, idx_to_use;
  assign idx = first_one_9bits(F_aux);
  assign idx_e = first_one_9bits(F_aux_e);
  
  // (!is_mayus_exp && !is_same_exp) <- para cuando S < R
  // (is_same_exp && Debe[10]) <- para cuando S == R pero la mantisa de 
  // R es mayor a la de S.
  // En ambos casos se debe trabajar con F_aux_e
  wire cond_idx = (!is_mayus_exp && !is_same_exp) || (is_same_exp && Debe[10]);
  
  // Evalue cuando se debe hacer shift o no.
  // Hay shift si S < R y al final debe
  // Cuando son el mismo exponente ( ya que termina en 0.)
  // Cuando en S > R y al final debe.
  wire cond_F_shift = (!is_mayus_exp  && Debe_e[10]) || is_same_exp || 
  (is_mayus_exp && Debe[10]);
  
  // El caso 1 se soluciona cuando !is_same_exp y !Debe[10].
  // Con is_same_exp se soluciona el caso 3.1
  // Con Debe[10] se soluciona es caso 2
  // Con is_same_exp && Debe[10] se soluciona el caso 3.2, se necesita
  // cambiar la resta a R - S, porque si no habría overflow.
  
  // Otro caso esquina: R > S y Debe[10] is true
  
  assign idx_to_use = cond_idx ? idx_e : idx;
  assign F_to_use = !is_mayus_exp ? F_aux_e : F_aux;
  assign is_result_zero = (F_to_use == 10'd0);
  RestaExp_sum sub_exp(ExpIn, idx_to_use, ExpAux);
  assign ExpOut = is_result_zero ? 5'd0 : ((cond_F_shift) ? ExpAux : ExpIn);
  assign F = (cond_F_shift) ? (F_to_use << idx_to_use) : F_to_use;  
endmodule



// Mantisa [9:0]
// Exponente [10:14]
// Signo [15]
module Suma16Bits(S, R, F, overflow, underflow, inexact);  
  input [15:0] S, R;
  output wire [15:0] F;
  output overflow, underflow, inexact;

  
  wire[9:0] m1_init = S[9:0];
  wire[9:0] m2_init = R[9:0];
  
  wire[4:0] e1 = S[14:10];
  wire[4:0] e2 = R[14:10];
  
  wire[4:0] diff_exp1, diff_exp2;
  RestaExp_sum subsito1(e1, e2, diff_exp1);
  RestaExp_sum subsito2(e2, e1, diff_exp2);
  
  
  wire s1 = S[15];
  wire s2 = R[15];
  
  wire [9:0] m1, m2;
  wire [4:0] exp_aux;
  wire sign;
  wire [9:0] op_sum;
  
  wire boolean1 = (e1 > e2);
  wire is_same_exp = (e1 == e2);
  
  wire [9:0] m1_shift, m2_shift;
  wire lost_m1, lost_m2;
  
  right_shift_pf_sum mshift1(m1_init, is_same_exp, diff_exp2, m1_shift, lost_m1);
  right_shift_pf_sum mshift2(m2_init, is_same_exp, diff_exp1, m2_shift, lost_m2);

  assign m2      = (boolean1) ? m2_shift : m2_init;
  assign m1      = (boolean1) ? m1_init  : m1_shift;
  assign exp_aux = (boolean1) ? e1 : e2;
  
  // Apartir del signo, sabremos si se suma o se resta.
  wire boolean2 = (s1 != s2);
  assign sign = (boolean2) ? 
                ((e1 > e2) ? s1 : 
                 (e1 < e2) ? s2 : 
                 (m1 >= m2) ? s1 : s2) 
              : s1;
  
  // Parámetros de ayuda (ya que verilog no soporta if/else en el nivel del modulo)
  wire [9:0] op_sum_sub, op_sum_add;
  wire [4:0] exp_sum_sub, exp_sum_add;
  wire is_zero_result; 
  wire lost_align = lost_m1 | lost_m2;

  SumMantisa sm(m1, m2, is_same_exp, exp_aux, exp_sum_add, op_sum_add, lost_align);
  RestaMantisa rm(m1, m2, is_same_exp, boolean1, exp_aux, exp_sum_sub, op_sum_sub, is_zero_result);

  assign op_sum = (boolean2) ? op_sum_sub : op_sum_add;
  wire [4:0] final_exp = (boolean2) ? exp_sum_sub : exp_sum_add;
  assign F[15]    = (boolean2 && is_zero_result) ? 1'b0 : sign;
  assign F[14:10] = final_exp;
  assign F[9:0]   = op_sum;
  // ============== FLAGS CORREGIDOS ==============
  // Inexact: si hubo bits perdidos en alineación O en redondeo
  // El redondeo ya se maneja dentro de RoundNearestEven que puede cambiar exp
  wire inexact_sub = lost_align;
  
  // ? Simplificado: lost_align captura si hubo pérdida
  assign inexact = lost_align;

  assign overflow  = (final_exp == 5'h1F);
  assign underflow = (final_exp == 5'd0) & inexact;
endmodule

// La resta se divide en 3 casos:
// 1. La resta, despues de normalizar, solo afecta a la mantisa
// 2. La resta, despues de normalizar, la resta de mantisa afecta al exponente:
//      2.1. Cuando en a-b, a > b
// 		2.2. Cuando b > a
// ejm: 1.01 - 0.11
// 3. Ambos valores tienes el mismo exponente. ejm: 1.1011 - 1.011
//		3.1. La mantisa no afecta el exponente. ejm: 1.11 - 1.001
//		3.2. La mantisa afecta el exponente 1. ejm: 1.001 - 1.100

