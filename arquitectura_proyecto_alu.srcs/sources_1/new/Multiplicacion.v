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

module is_overflow(Exp, AddExp, OverFlow);
  input [4:0] Exp;
  input [4:0] AddExp;
  output OverFlow;
 
  wire [5:0] NewExp = Exp + AddExp;
  
  assign OverFlow = (NewExp >= 6'b011111);
  
  
endmodule

module is_underflow(Exp, SubExp, UnderFlow);
  input [4:0] Exp;
  input [4:0] SubExp;
  output UnderFlow;
  
  assign UnderFlow = ( SubExp > Exp );
  
endmodule

module is_inexact(Man, CarryOut, inexact);
  input CarryOut;
  input [9:0] Man;
  output inexact;
  
  assign inexact = (Man[0] && CarryOut);
  
endmodule

module is_invalid_op(Exp1, Exp2, Man1, Man2, InvalidOp);
  input [4:0] Exp1, Exp2;
  input [9:0] Man1, Man2;
  output InvalidOp;
  
  wire is_inf_Val1 = (&Exp1 && ~|Man1);
  wire is_inf_Val2 = (&Exp2 && ~|Man2);
  
  wire is_invalid_Val1 = (&Exp1 && |Man1);
  wire is_invalid_Val2 = (&Exp2 && |Man2);
  
  assign InvalidOp = (is_inf_Val1 | is_inf_Val2 | is_invalid_Val1 | is_invalid_Val2);

endmodule

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

module Prod(Sm, Rm, ExpIn, Fm, ExpOut, overflow, inexact);
  
  input [10:0] Sm, Rm;
  input [4:0] ExpIn;
  output wire [9:0] Fm;
  output wire [4:0] ExpOut;
  output        overflow, inexact;
  
  wire [21:0] Result = Sm * Rm;
  
function [4:0] first_one;
  
  input [21:0] bits;
  integer idx;
  reg found;
  
  begin
    found = 1'b0;
    first_one = 5'd0; 
    
    for (idx = 20; idx >= 0 && !found; idx = idx - 1) begin
      if (bits[idx]) begin
        first_one = (20 - idx);
        found = 1'b1;
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
  //wire [9:0] Fm_out = (Debe) ? Result[20:11] : Result[19:10];
  
  // Si estamos 1x.xx, sumo uno al exponente para que quede 1.xxx
  // Si estamos en el caso de 1.xx o 0.xx, resto la cantidad de veces necesaria
  // hasta encontrar el primer 1 (en 1.xx -> shifts = 0)
  //assign ExpOut = (Debe) ? (ExpIn + 1) : (ExpIn - shifts);
  
  // La misma idea que ExpOut, pero ahora afectando a la mantisa.
  //assign Fm = (Debe) ? Fm_out : (Fm_out >> shifts);
  // Exponente previo a redondeo (misma lógica que ya tenías)
wire [4:0] exp_pre = (Debe) ? (ExpIn + 1) : (ExpIn - shifts);

// Construimos un "stream" para sacar top10/guard/rest y sticky
wire [27:0] stream0 = {Result[21:0], 6'b0};            // relleno para sticky
wire [27:0] stream1 = Debe ? (stream0 >> 11) : (stream0 >> 10);
wire [27:0] stream2 = ShiftCondition ? (stream1 << shifts) : stream1;

// top10 (10), guard (1), rest3 (3) + sticky (1)
wire [9:0] top10  = stream2[15:6];
wire       guard  = stream2[5];
wire [2:0] rest3  = stream2[4:2];
wire       sticky = |stream2[1:0];                     // OR de lo que queda
wire [3:0] rest4  = {rest3, sticky};

// Paquete de 15 bits para el redondeo
wire [14:0] ms15 = {top10, guard, rest4};

// Redondeo al par
wire [9:0] frac_rnd;
wire [4:0] exp_rnd;
RoundNearestEven rne_mul(.ms(ms15), .exp(exp_pre), .ms_round(frac_rnd), .exp_round(exp_rnd));

// Salidas finales de Prod
assign Fm     = frac_rnd;
assign ExpOut = exp_rnd;
// ------------ Flag Section -------------  
  wire h_overflow;
  is_inexact flag1(.Man(Result[19:10]), .CarryOut(Debe), .inexact(inexact));
  is_overflow flag2(.Exp(ExpIn), .AddExp(5'b00001), .OverFlow(h_overflow));
  
  assign overflow = (Debe) ? h_overflow : 1'b0;
endmodule


// #(parameter N=8), LUEGO adaptar con parameter a 32 bits.
module ProductHP (S, R, F, overflow, underflow, inv_op, inexact);  
  input [15:0] S, R;
  output wire [15:0] F;
  output overflow, underflow, inv_op, inexact;

  wire[9:0] m1 = S[9:0];
  wire[9:0] m2 = R[9:0];
  
  wire[4:0] e1 = S[14:10];
  wire[4:0] e2 = R[14:10];
  
  wire s1 = S[15];
  wire s2 = R[15];
  wire sign = s1^s2;
       
  wire [4:0] exp_to_use      = e1 + e2 - 5'd15;
  wire [5:0] evaluate_flags  = e1 + e2;
  wire [5:0] despues_la_borro= e1 + e2 - 5'd15;

  wire [10:0] param_m1 = {1'b1, m1};
  wire [10:0] param_m2 = {1'b1, m2};

  wire [9:0] m_final;
  wire [4:0] exp_final;
  wire over_t2; // overflow interno por "carry" de normalización
  Prod product_mantisa(param_m1, param_m2, exp_to_use, m_final, exp_final,
                       over_t2, inexact);

  assign F[15]    = sign;
  assign F[14:10] = exp_final;
  assign F[9:0]   = m_final;

  // Flags (igual que tenías antes)
  is_invalid_op flag4(.Exp1(e1), .Exp2(e2), .Man1(m1), .Man2(m2), .InvalidOp(inv_op));

  wire over_t1   = (evaluate_flags >= 6'd15) && (despues_la_borro >= 6'b011111);
  wire under_t1  = (evaluate_flags <  6'd15);

  assign overflow   = over_t1 | over_t2 | inv_op;
  assign underflow  = under_t1;
endmodule