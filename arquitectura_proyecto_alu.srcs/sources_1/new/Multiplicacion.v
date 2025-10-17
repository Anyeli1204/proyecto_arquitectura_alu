`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.10.2025 15:22:57
// Design Name: 
// Module Name: Multiplicacion
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


module FullSub_mul(Si, Ri, Din, Debe, Dout);
  input Si, Ri, Din;
  output wire Debe, Dout;
  
  assign Debe = (~Si & Ri) | (~Si & Din) | (Ri & Din);
  assign Dout = Si ^ Ri ^ Din;
  
endmodule

module RestaExp(S, R, F);
  input [4:0] S, R;
  output wire[4: 0] F;
  
  wire [5:0] Debe;
  assign Debe[0] = 1'b0;
  
  genvar i;
  generate
    for(i = 0; i < 5; i = i + 1)
      FullSub_mul sub_i(S[i], R[i], Debe[i], Debe[i+1], F[i]);
  endgenerate
  
  // Maybe si Debe[5] da 1, hay overflow

endmodule

module restar_1_bit_expo(exp, F);
  input [4:0] exp;
  output [4:0] F;
  RestaExp sub_exp(exp, 5'b00001, F);
endmodule

module right_shift_pf(mantisa, is_same_exp, shifts, F);
  input is_same_exp;
  input [9:0] mantisa;
  input [4:0] shifts;
  output [9:0] F;
  
  wire [9:0] e1 = {1'b1, mantisa[9:1]};
 
  wire [4:0] aux_shifts;
  restar_1_bit_expo sub_shift(.exp(shifts), .F(aux_shifts));
  
  //(shifts > 0 || is_same_exp)
  assign F = (shifts > 0) ? e1 >> aux_shifts : mantisa;
  
endmodule

module Prod(Sm, Rm, ExpIn, Fm, ExpOut);
  
  input [10:0] Sm, Rm;
  input [4:0] ExpIn;
  output wire [9:0] Fm;
  output wire [4:0] ExpOut;
  
  wire [21:0] Result = Sm * Rm;
  
function [4:0] first_one;
  
  input [20:0] bits;
  integer idx;
  reg found;
  
  begin
    found = 0;
    first_one = 5'b00000; 
    
    for (idx = 18; idx >= 9 && !found; idx = idx - 1) begin
      if (bits[idx]) begin
        first_one = (20 - idx);
        found = 1;
      end
    end

  end
  
endfunction
  
  initial begin
    $monitor("m1: %b, m2: %b, result: %b", Sm, Rm, Result);
  end
  
  // Debe <- para los casos de 1x.xxx 
  // ShiftCondition <- para decir: si 0.xxx, detecto cuantos pasos debo dar para llegar
  // al primer 1.
  wire Debe = Result[21];
  wire ShiftCondition = !Debe && !Result[20];
  
  // Si no es ShiftCondition, entonces estamos en los casos 1x.xxx o 01.xxx
  wire [4:0] shifts = (ShiftCondition) ? first_one(Result) : 5'b00000;  
  
  // Rescato los 10 bits más significativos
  wire [9:0] Fm_out = (Debe) ? Result[20:11] : Result[19:10];
  
  // Si estamos 1x.xx, sumo uno al exponente para que quede 1.xxx
  // Si estamos en el caso de 1.xx o 0.xx, resto la cantidad de veces necesaria
  // hasta encontrar el primer 1 (en 1.xx -> shifts = 0)
  assign ExpOut = (Debe) ? (ExpIn + 1) : (ExpIn - shifts);
  
  // La misma idea que ExpOut, pero ahora afectando a la mantisa.
  assign Fm = (Debe) ? Fm_out : (Fm_out >> shifts);
  
endmodule


// #(parameter N=8), LUEGO adaptar con parameter a 32 bits.
module ProductHP (S, R, F);
  
  input [15:0] S, R;
  output wire [15:0] F;
  
  wire[9:0] m1 = S[9:0];
  wire[9:0] m2 = R[9:0];
  
  wire[4:0] e1 = S[14:10];
  wire[4:0] e2 = R[14:10];
  
  wire s1 = S[15];
  wire s2 = R[15];
  wire sign;
       
  // Suma de exponentes en el producto.
  wire [4:0] exp_to_use = e1 + e2 - 5'd15;
    
  // Apartir del signo, sabremos si se suma o se resta.
  wire boolean2 = (s1 != s2);
  assign sign = (boolean2) ? 1 : 0;
  wire [10:0] param_m1 = {1'b1, m1};
  wire [10:0] param_m2 = {1'b1, m2};
  
  wire [9:0] m_final;
  wire [4:0] exp_final;
  Prod product_mantisa(param_m1, param_m2, exp_to_use, m_final, exp_final);
  
  assign F[15] = sign;
  assign F[14:10] = exp_final;
  assign F[9:0] = m_final;
  
  
  initial begin
    $monitor("m1: %b, m2: %b", m1, m2);
    $monitor("sign: %b, exp: %b, mantisa: %b, is_resta: %b", sign, exp_final, m_final, boolean2);
  end
  
endmodule