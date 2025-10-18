`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// SumaResta.v - Módulo de suma y resta en punto flotante IEEE 754 half-precision
// Versión corregida con redondeo tie-to-even y manejo correcto de flags
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

// ============== RIGHT SHIFT CON GUARD Y STICKY SEPARADOS ==============
module right_shift_pf_sum(mantisa, shifts, F, guard_bit, sticky_bits, inexact_flag);
  input [9:0] mantisa;
  input [4:0] shifts;
  output [10:0] F;         // 11 bits principales
  output guard_bit;        // Guard bit explícito
  output sticky_bits;      // Solo sticky (para redondeo tie-to-even)
  output inexact_flag;     // Guard + sticky (para flag de inexactitud)
  
  wire [20:0] full_value = {1'b1, mantisa, 10'b0};
  wire [20:0] shifted = full_value >> shifts;
  
  assign F = shifted[20:10];           // 11 bits superiores
  assign guard_bit = shifted[9];       // Guard bit
  assign sticky_bits = |shifted[8:0];  // Solo después del guard (para redondeo)
  assign inexact_flag = |shifted[9:0]; // Guard + sticky (para flag inexact)
endmodule

// ============== SUMA DE MANTISAS CON REDONDEO ==============
module SumMantisa(S, R, guard_S, guard_R, ExpIn, ExpOut, F, sticky_for_round);
  input [10:0] S, R;      // 11 bits cada uno
  input guard_S, guard_R; // Guard bits
  input [4:0] ExpIn;
  input sticky_for_round; // Sticky bits para redondeo
  output wire[4:0] ExpOut;
  output wire[9:0] F;

  // Sumar con 12 bits (11 + guard)
  wire [11:0] A = {S, guard_S};
  wire [11:0] B = {R, guard_R};
  wire [11:0] sum_bits;
  wire [12:0] C;
  assign C[0] = 1'b0;
  
  genvar i;
  generate
    for (i = 0; i < 12; i = i + 1) begin: ADD12
      FullAdder add_i(A[i], B[i], C[i], C[i+1], sum_bits[i]);
    end
  endgenerate
  
  wire carry = C[12];
  wire [14:0] ms_for_round;
  wire [4:0] exp_for_round;
  
  // Construcción del paquete para redondeo
  assign ms_for_round = carry ? 
    {sum_bits[11:2], sum_bits[1], sum_bits[0], 2'b0, sticky_for_round} :
    {sum_bits[10:1], sum_bits[0], 3'b0, sticky_for_round};
  
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

// ============== RESTA DE MANTISAS ==============
module RestaMantisa(S, R, is_same_exp, is_mayus_exp, ExpIn, ExpOut, F, is_result_zero);
  input is_same_exp;
  input [9:0] S, R;
  input [4:0] ExpIn;
  input is_mayus_exp;
  
  output wire[4:0] ExpOut;
  output wire[9:0] F;
  output wire is_result_zero;
  
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
  endfunction
  
  wire [10:0] Debe, Debe_e;
  wire [9:0] F_aux, F_aux_e, F_to_use;
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
  
  wire cond_idx = (!is_mayus_exp && !is_same_exp) || (is_same_exp && Debe[10]);
  wire cond_F_shift = (!is_mayus_exp && Debe_e[10]) || is_same_exp || (is_mayus_exp && Debe[10]);
  
  assign idx_to_use = cond_idx ? idx_e : idx;
  assign F_to_use = !is_mayus_exp ? F_aux_e : F_aux;
  assign is_result_zero = (F_to_use == 10'd0);
  
  RestaExp_sum sub_exp(ExpIn, idx_to_use, ExpAux);
  assign ExpOut = is_result_zero ? 5'd0 : ((cond_F_shift) ? ExpAux : ExpIn);
  assign F = is_result_zero ? 10'd0 : ((cond_F_shift) ? (F_to_use << idx_to_use) : F_to_use);
endmodule

// ============== SUMA DE 16 BITS (TOP LEVEL) ==============
module Suma16Bits(S, R, F, overflow, underflow, inexact);  
  input [15:0] S, R;
  output wire [15:0] F;
  output overflow, underflow, inexact;
  
  wire [9:0] m1_init = S[9:0];
  wire [9:0] m2_init = R[9:0];
  wire [4:0] e1 = S[14:10];
  wire [4:0] e2 = R[14:10];
  wire [4:0] diff_exp1, diff_exp2;
  
  RestaExp_sum subsito1(e1, e2, diff_exp1);
  RestaExp_sum subsito2(e2, e1, diff_exp2);
  
  wire s1 = S[15];
  wire s2 = R[15];
  
  wire boolean1 = (e1 > e2);
  wire is_same_exp = (e1 == e2);
  
  // Right shift devuelve: 11 bits + guard + sticky + inexact_flag
  wire [10:0] m1_shift, m2_shift;
  wire g1_shift, g2_shift;
  wire sticky_m1, sticky_m2;
  wire inexact_m1, inexact_m2;
  
  right_shift_pf_sum mshift1(m1_init, diff_exp2, m1_shift, g1_shift, sticky_m1, inexact_m1);
  right_shift_pf_sum mshift2(m2_init, diff_exp1, m2_shift, g2_shift, sticky_m2, inexact_m2);

  // Construir valores de 11 bits + guard para suma
  wire [10:0] m1_11 = (boolean1) ? {1'b1, m1_init} : m1_shift;
  wire [10:0] m2_11 = (boolean1) ? m2_shift : {1'b1, m2_init};
  wire g1 = (boolean1) ? 1'b0 : g1_shift;
  wire g2 = (boolean1) ? g2_shift : 1'b0;
  
  // Sticky para redondeo (solo bits después del guard)
  wire sticky_for_round = sticky_m1 | sticky_m2;
  
  // Inexact flag (incluye guard + sticky)
  wire lost_align = inexact_m1 | inexact_m2;
  
  // Extraer valores de 10 bits para resta
  wire [9:0] m1_10 = (boolean1) ? m1_init : m1_shift[9:0];
  wire [9:0] m2_10 = (boolean1) ? m2_shift[9:0] : m2_init;
  
  wire [4:0] exp_aux = (boolean1) ? e1 : e2;
  
  wire boolean2 = (s1 != s2);
  wire sign = (boolean2) ? 
              ((e1 > e2) ? s1 : 
               (e1 < e2) ? s2 : 
               (m1_init >= m2_init) ? s1 : s2) 
            : s1;
  
  wire [9:0] op_sum_sub, op_sum_add;
  wire [4:0] exp_sum_sub, exp_sum_add;
  wire is_zero_result;

  SumMantisa sm(m1_11, m2_11, g1, g2, exp_aux, exp_sum_add, op_sum_add, sticky_for_round);
  RestaMantisa rm(m1_10, m2_10, is_same_exp, boolean1, exp_aux, exp_sum_sub, op_sum_sub, is_zero_result);

  wire [9:0] op_sum = (boolean2) ? op_sum_sub : op_sum_add;
  wire [4:0] final_exp = (boolean2) ? exp_sum_sub : exp_sum_add;
  
  assign F[15] = (boolean2 && is_zero_result) ? 1'b0 : sign;
  assign F[14:10] = final_exp;
  assign F[9:0] = op_sum;
  
  assign inexact = lost_align;
  assign overflow = (final_exp == 5'h1F);
  assign underflow = (final_exp == 5'd0) & inexact;
endmodule