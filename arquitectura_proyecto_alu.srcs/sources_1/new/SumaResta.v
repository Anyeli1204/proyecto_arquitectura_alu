`timescale 1ns / 1ps

module FullAdder (Si, Ri, Din, Debe, Dout);
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

module RestaExp_sum #(parameter MBS=9, parameter EBS=4, parameter BS=15) (S, R, F);
  input [EBS:0] S, R;
  output wire[EBS: 0] F;
  
  wire [EBS+1:0] Debe;
  assign Debe[0] = 1'b0;
  
  genvar i;
  generate
    for(i = 0; i < EBS+1; i = i + 1)
      FullSub_add sub_i(S[i], R[i], Debe[i], Debe[i+1], F[i]);
  endgenerate
 endmodule
  

module SumarExp #(parameter MBS=9, parameter EBS=4, parameter BS=15)(S, R, F);
  input [EBS:0] S, R;
  output wire[EBS: 0] F;
  
  wire [EBS+1:0] Debe;
  assign Debe[0] = 1'b0;
  
  genvar i;
  generate
    for(i = 0; i < EBS+1; i = i + 1)
      FullAdder add_i(S[i], R[i], Debe[i], Debe[i+1], F[i]);
  endgenerate

endmodule

module mas_1_bit_expo #(parameter MBS=9, parameter EBS=4, parameter BS=15)(exp, F);
  input [EBS:0] exp;
  output [EBS:0] F;
  SumarExp #(.MBS(MBS), .EBS(EBS), .BS(BS)) add_exp (exp, 5'b00001, F);
endmodule

module restar_1_bit_expo_sum #(parameter MBS=9, parameter EBS=4, parameter BS=15)(exp, F);
  input [4:0] exp;
  output [4:0] F;
  RestaExp_sum #(.MBS(MBS), .EBS(EBS), .BS(BS)) sub_exp(exp, 5'b00001, F);
endmodule

module right_shift_pf_sum #(parameter MBS=9, parameter EBS=4, parameter BS=15)
(mantisa, shifts, F, guard_bit, sticky_bits, inexact_flag);

  input [MBS:0] mantisa;
  input [EBS:0] shifts;
  output [MBS+1:0] F;         
  output guard_bit;       
  output sticky_bits;      
  output inexact_flag;     
  
  wire [MBS+11:0] full_value = {1'b1, mantisa, 10'b0};
  wire [MBS+11:0] shifted = full_value >> shifts;
  
  assign F = shifted[MBS+11: 10];          
  assign guard_bit = shifted[9];      
  assign sticky_bits = |shifted[8: 0]; 
  assign inexact_flag = |shifted[9: 0];
  
endmodule

module SumMantisa #(parameter MBS=9, parameter EBS=4, parameter BS=15) 
(S, R, guard_S, guard_R, ExpIn, ExpOut, F, sticky_for_round);

  input [MBS+1:0] S, R; 
  input [EBS:0] ExpIn;
  output wire[EBS:0] ExpOut;
  output wire[MBS:0] F;

  input guard_S, guard_R; 
  input sticky_for_round; 

  wire [MBS+3:0] C;
  wire [MBS+2:0] sum_bits;
  
  // Sumar con 12 bits (11 + guard)
  wire [MBS+2:0] A = {S, guard_S};
  wire [MBS+2:0] B = {R, guard_R};
  assign C[0] = 1'b0;
  
  genvar i;
  generate
    for(i = 0; i < MBS+3; i = i + 1) 
      FullAdder add_i(A[i], B[i], C[i], C[i+1], sum_bits[i]);
  endgenerate
  
  wire carry = C[MBS+3];
  wire [BS-1:0] ms_for_round;
  wire [EBS:0] exp_for_round;

  assign ms_for_round = carry ? 
    {sum_bits[MBS+2:2], sum_bits[1], sum_bits[0], 2'b0, sticky_for_round} :
    {sum_bits[MBS+1:1], sum_bits[0], 3'b0, sticky_for_round};
  
  assign exp_for_round = carry ? (ExpIn + 1) : ExpIn;

  wire [MBS:0] frac_rounded;
  wire [EBS:0] exp_rounded;
  
  RoundNearestEven #(.MBS(MBS), .EBS(EBS), .BS(BS), .FSIZE(MBS+5)) rne_sum(
    .ms(ms_for_round),
    .exp(exp_for_round),
    .ms_round(frac_rounded),
    .exp_round(exp_rounded)
  );
  
  assign F = frac_rounded;
  assign ExpOut = exp_rounded;
endmodule

module RestaMantisa #(parameter MBS=9, parameter EBS=4, parameter BS=15)  
(S, R, is_same_exp, is_mayus_exp, ExpIn, ExpOut, F);
  
  input is_same_exp;
  input [MBS:0] S, R;
  input [EBS:0] ExpIn;
  input is_mayus_exp;
  
  output wire[EBS:0] ExpOut;
  output wire[MBS:0] F;
  
  // Funci�n que se encarga de encontrar el primer 1 de la mantisa, util para la resta.
  function [EBS:0] first_one_9bits;

    input [MBS:0] val;
    integer idx;
    reg found;
    begin
      found = 0;
      first_one_9bits = 0;
      for(idx = MBS; idx >= 0; idx = idx-1) begin
        if(val[idx] && !found) begin
          first_one_9bits = (MBS + 1 - idx);
          found = 1;
        end
      end
    
    end

  endfunction
    
  wire [MBS+1:0] Debe, Debe_e;
  wire [MBS:0] F_aux, F_aux_e, F_to_use;
  assign Debe[0] = 1'b0;
  assign Debe_e[0] = 1'b0;
  
  genvar i;
  generate
    for(i = 0; i < MBS+1; i = i + 1) begin
      FullSub_add sub_i(S[i], R[i], Debe[i], Debe[i+1], F_aux[i]);
      FullSub_add sub_i_extremo(R[i], S[i], Debe_e[i], Debe_e[i+1], F_aux_e[i]);
    end
  endgenerate


  wire[EBS:0] idx, idx_e, ExpAux, idx_to_use;
  assign idx = first_one_9bits(F_aux);
  assign idx_e = first_one_9bits(F_aux_e);
  
  // Debe estar bien...
  wire cond_idx = (!is_mayus_exp && !is_same_exp) || (is_same_exp && Debe[MBS+1]);

  // Esto está bien...
  wire cond_F_shift = (!is_mayus_exp  && Debe_e[MBS+1]) || is_same_exp || 
  (is_mayus_exp && Debe[MBS+1]);
  
  assign idx_to_use = cond_idx ? idx_e : idx;

  assign F_to_use = (is_mayus_exp || S >= R) ? F_aux : F_aux_e;

  

  

  RestaExp_sum #(.MBS(MBS), .EBS(EBS), .BS(BS)) 
  sub_exp(ExpIn, idx_to_use, ExpAux);

  // Para el redondeo
  wire[EBS:0] ExpOutTemp = (cond_F_shift) ? ExpAux : ExpIn;
  wire[MBS:0] FTemp = (cond_F_shift) ? (F_to_use << idx_to_use) : F_to_use;

  wire [MBS:0] lost_bits = F_to_use >> (MBS + 1 - idx_to_use);

  wire[MBS + 5:0] FToRound = {FTemp, lost_bits[4:0]};
  
  wire[MBS:0] FFinal;
  wire[EBS:0] ExpFinal;
  
  RoundNearestEven #(.MBS(MBS), .EBS(EBS), .BS(BS)) 
  rounder(
    .ms(FToRound),
    .exp(ExpOutTemp),
    .ms_round(FFinal),
    .exp_round(ExpFinal)
  );

  assign ExpOut = ExpFinal;
  assign F = FFinal;
  
  
  

endmodule

// Mantisa [9:0]
// Exponente [10:14]
// Signo [15]
module Suma16Bits #(parameter MBS=9, parameter EBS=4, parameter BS=15) (S, R, F,
  overflow, underflow, inexact);
  
  input [BS:0] S, R;
  output wire [BS:0] F;
  output overflow, underflow, inexact;
  
  wire[MBS:0] m1_init = S[MBS:0];
  wire[MBS:0] m2_init = R[MBS:0];
  
  wire[EBS:0] e1 = S[BS-1:BS-EBS-1];
  wire[EBS:0] e2 = R[BS-1:BS-EBS-1];
  wire[EBS:0] diff_exp1, diff_exp2;
  
  RestaExp_sum #(.MBS(MBS), .EBS(EBS), .BS(BS)) subsito1(e1, e2, diff_exp1);
  RestaExp_sum #(.MBS(MBS), .EBS(EBS), .BS(BS)) subsito2(e2, e1, diff_exp2);
  
  wire s1 = S[BS];
  wire s2 = R[BS];
  
  wire boolean1 = (e1 > e2);
  wire is_same_exp = (e1 == e2);
  
  // Right shift devuelve: 11 bits + guard + sticky + inexact_flag
  wire [MBS+1:0] m1_shift, m2_shift;
  wire g1_shift, g2_shift;
  wire sticky_m1, sticky_m2;
  wire inexact_m1, inexact_m2;
  
  right_shift_pf_sum #(.MBS(MBS), .EBS(EBS), .BS(BS))
  mshift1(m1_init, diff_exp2, m1_shift, g1_shift, sticky_m1, inexact_m1);

  right_shift_pf_sum #(.MBS(MBS), .EBS(EBS), .BS(BS))
  mshift2(m2_init, diff_exp1, m2_shift, g2_shift, sticky_m2, inexact_m2);

  // Construir valores de 11 bits + guard para suma
  wire [MBS+1:0] m1_11 = (boolean1) ? {1'b1, m1_init} : m1_shift;
  wire [MBS+1:0] m2_11 = (boolean1) ? m2_shift : {1'b1, m2_init};
  wire g1 = (boolean1) ? 1'b0 : g1_shift;
  wire g2 = (boolean1) ? g2_shift : 1'b0;
  
  // Sticky para redondeo (solo bits después del guard)
  wire sticky_for_round = sticky_m1 | sticky_m2;
  
  // Inexact flag (incluye guard + sticky)
  wire lost_align = inexact_m1 | inexact_m2;
  
  // Extraer valores de 10 bits para resta
  wire [MBS:0] m1_10 = (boolean1) ? m1_init : m1_shift[MBS:0];
  wire [MBS:0] m2_10 = (boolean1) ? m2_shift[MBS:0] : m2_init;
  
  wire [EBS:0] exp_aux = (boolean1) ? e1 : e2;
  
  wire boolean2 = (s1 != s2);
  wire sign = (boolean2) ? 
              ((e1 > e2) ? s1 : 
               (e1 < e2) ? s2 : 
               (m1_init >= m2_init) ? s1 : s2) 
            : s1;



  wire is_zero_result = (boolean2 && (m1_init == m2_init) && (e1 == e2)) ||
                      (!boolean2 && (&(~m1_init)) && (&(~m2_init)) && (&(~e1)) && (&(~e2)));


  
  wire [MBS:0] op_sum_sub, op_sum_add;
  wire [EBS:0] exp_sum_sub, exp_sum_add;


  SumMantisa #(.MBS(MBS), .EBS(EBS), .BS(BS))
  sm(m1_11, m2_11, g1, g2, exp_aux, exp_sum_add, op_sum_add, sticky_for_round);

  RestaMantisa #(.MBS(MBS), .EBS(EBS), .BS(BS))
  rm(m1_10, m2_10, is_same_exp, boolean1, exp_aux, exp_sum_sub, op_sum_sub);

  wire [MBS:0] op_sum = (boolean2) ? op_sum_sub : op_sum_add;
  wire [EBS:0] final_exp = (boolean2) ? exp_sum_sub : exp_sum_add;
  
  assign F[BS] = (boolean2 && is_zero_result) ? 1'b0 : sign;
  assign F[BS-1: BS-EBS-1] = is_zero_result ? {EBS+1{1'b0}}: final_exp;
  assign F[MBS:0] = is_zero_result ? {MBS+1{1'b0}} : op_sum;
  
  assign inexact = lost_align;
  assign overflow = ( final_exp == {EBS+1{1'b1}} );
  assign underflow = ( final_exp == {EBS+1{1'b0}} ) & inexact;

endmodule

