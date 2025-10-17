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


// Con fe la placa no explote con tanto wire

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
  
  // Maybe si Debe[5] da 1, hay overflow


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

module right_shift_pf_sum(mantisa, is_same_exp, shifts, F);
  input is_same_exp;
  input [9:0] mantisa;
  input [4:0] shifts;
  output [9:0] F;
  
  wire [9:0] e1 = {1'b1, mantisa[9:1]};
 
  wire [4:0] aux_shifts;
  restar_1_bit_expo_sum sub_shift(.exp(shifts), .F(aux_shifts));
  
  //(shifts > 0 || is_same_exp)
  assign F = (shifts > 0) ? e1 >> aux_shifts : mantisa;
  
endmodule

module SumMantisa(S, R, is_same_exp, ExpIn, ExpOut, F);
  input is_same_exp;
  input [9:0] S, R;
  input [4:0] ExpIn;
  
  output wire[4:0] ExpOut;
  output wire[9:0] F;
  
  wire [10:0] Debe;
  wire [9: 0] F_aux;
  wire [4:0] ExpAux;
  
  assign Debe[0] = 1'b0;
  
  genvar i;
  generate
    for(i = 0; i < 10; i = i + 1)
      FullAdder add_i(S[i], R[i], Debe[i], Debe[i+1], F_aux[i]);
  endgenerate
  
  // Aumentar el exponente en +1 si tienen la misma base (único caso)
  mas_1_bit_expo add_exp(.exp(ExpIn), .F(ExpAux));
  
wire normalize = Debe[10] | (is_same_exp & |ExpIn);
assign ExpOut  = normalize ? ExpAux : ExpIn;
assign F = normalize ? (F_aux >> 1) : F_aux;

endmodule

module RestaMantisa(S, R, is_same_exp, is_mayus_exp, ExpIn, ExpOut, F);
  
  input is_same_exp;
  input [9:0] S, R;
  input [4:0] ExpIn;
  input is_mayus_exp;
  
  output wire[4:0] ExpOut;
  output wire[9: 0] F;
  
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
  
  RestaExp_sum sub_exp(ExpIn, idx_to_use, ExpAux);
  assign ExpOut = (cond_F_shift) ? ExpAux : ExpIn;
  assign F = (cond_F_shift) ? (F_to_use << idx_to_use) : F_to_use;
  
  
endmodule

// Mantisa [9:0]
// Exponente [10:14]
// Signo [15]
module Suma16Bits(S, R, F);
  
  input [15:0] S, R;
  output wire [15:0] F;
  
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
  
  // Shift para que estén en la misma base...
  right_shift_pf_sum mshift1(m1_init, is_same_exp, diff_exp2, m1_shift);
  right_shift_pf_sum mshift2(m2_init, is_same_exp, diff_exp1, m2_shift);
  
  assign m2 = (boolean1) ? m2_shift : m2_init;
  assign m1 = (boolean1) ? m1_init : m1_shift;
  
  // La base inicial será del exponente mayor.
  assign exp_aux = (boolean1) ? e1 : e2;
  
  // Apartir del signo, sabremos si se suma o se resta.
  wire boolean2 = (s1 != s2);
  assign sign = (boolean2) ? 
                ((e1 > e2) ? s1 : 
                 (e1 < e2) ? s2 : 
                 (m1 >= m2) ? s1 : s2) 
              : s1;
  
  // Parámetros de ayuda (ya que verilog no soporta if/else en el nivel del modulo)
  wire [9:0] op_sum_sub;
  wire [9:0] op_sum_add;
  
  wire [4:0] exp_sum_sub;
  wire [4:0] exp_sum_add;
  
  SumMantisa sm(m1, m2, is_same_exp, exp_aux, exp_sum_add, op_sum_add);
  RestaMantisa rm(m1, m2, is_same_exp, boolean1, exp_aux, exp_sum_sub, op_sum_sub);
  
  
  assign op_sum = (boolean2) ? op_sum_sub : op_sum_add;
  wire [4:0] final_exp = (boolean2) ? exp_sum_sub : exp_sum_add;

 
  initial begin
    $monitor("m1: %b, m2: %b", m1, m2);
    $monitor("sign: %b, exp: %b, mantisa: %b, is_resta: %b", sign, final_exp, op_sum, boolean2);
  end
 
  
  assign F[15] = sign;
  assign F[14:10] = final_exp;
  assign F[9:0] = op_sum;
  
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

