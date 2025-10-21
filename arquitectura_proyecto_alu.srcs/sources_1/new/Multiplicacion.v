`timescale 1ns / 1ps

module Prod #(parameter MBS=9, parameter EBS=4, parameter BS=15) (Sm, Rm, ExpIn, Fm, ExpOut, 
  overflow, inexact);
  
  input [MBS+1:0] Sm, Rm;
  input [EBS:0] ExpIn;
  output wire [MBS:0] Fm;
  output wire [EBS:0] ExpOut;
  output        overflow, inexact;

  parameter FSIZE = MBS + 5;
  parameter MSIZE = MBS + MBS + 3;
  parameter STEAMSIZE = MBS + MBS + 3 + 6;
  
  // ------------ Function Section -------------
  function [EBS:0] first_one;
  
    input [MBS+1 + MBS+1 :0] bits;
    integer idx;
    reg found;
    
    begin
      found = 0;
      first_one = 5'b00000; 
      
      // MBS + MBS + 1 + 1 - 2 <-- -2 por el xx.mantisa
      for (idx = MBS + MBS; idx >= 9 && !found; idx = idx - 1) begin
        if (bits[idx]) begin
          first_one = (MBS + MBS + 2 - idx);
          found = 1;
        end
      end

    end
  
  endfunction

  // ------------ Op Section -------------
  wire [MSIZE: 0] Result = Sm * Rm;
  wire Debe = Result[MSIZE];
  wire ShiftCondition = !Debe && !Result[MSIZE - 1];
  wire [EBS + 5:0] shifts = (ShiftCondition) ? first_one(Result) : 5'b00000;

  wire [EBS:0] exp_pre = (Debe) ? (ExpIn + 1) : (ExpIn - shifts);

  wire [STEAMSIZE: 0] stream0 = {Result[MSIZE: 0], 6'b0};           
  wire [STEAMSIZE: 0] stream1 = Debe ? (stream0 >> MBS + 2) : (stream0 >> MBS + 1);
  wire [STEAMSIZE: 0] stream2 = ShiftCondition ? (stream1 << shifts) : stream1;

  // top10 (10), guard (1), rest3 (3) + sticky (1)
  // Genera 5 bits en el LSB para el redondeo
  wire [MBS:0] top10  = stream2[MBS+6 :6];
  wire       guard  = stream2[5];
  wire [2:0] rest3  = stream2[4:2];
  wire       sticky = |stream2[1:0];                     // OR de lo que queda
  wire [3:0] rest4  = {rest3, sticky};

  // Paquete de 15 bits para el redondeo
  wire [FSIZE: 0] ms15 = {top10, guard, rest4};

  // Redondeo al par
  wire [MBS:0] frac_rnd;
  wire [EBS:0] exp_rnd;
  RoundNearestEven #(.MBS(MBS), .EBS(EBS), .BS(BS), .FSIZE(FSIZE))
  rne_mul(.ms(ms15), .exp(exp_pre), .ms_round(frac_rnd), .exp_round(exp_rnd));

  // Salidas finales de Prod
  assign Fm     = frac_rnd;
  assign ExpOut = exp_rnd;

  // ------------ Flag Section -------------  
  wire h_overflow;
  
  // Si en la parte adicional hay almenos 1 bit de 1, la operación es inexacta.
  assign inexact = guard | |rest4;
  
  is_overflow #(.MBS(MBS), .EBS(EBS), .BS(BS))
  flag2(.Exp(ExpIn), .AddExp(5'b00001), .OverFlow(h_overflow));
  
  assign overflow = (Debe) ? h_overflow : 1'b0;
  
endmodule



// #(parameter N=8), LUEGO adaptar con parameter a 32 bits.
module ProductHP #(parameter MBS=9, parameter EBS=4, parameter BS=15) (S, R, F,
  overflow, underflow, inv_op, inexact);
  
  input [BS:0] S, R;
  output wire [BS:0] F;
  output overflow, underflow, inv_op, inexact;
  
  wire[MBS:0] m1 = S[MBS:0];
  wire[MBS:0] m2 = R[MBS:0];
  
  wire[EBS:0] e1 = S[BS-1: BS-EBS-1];
  wire[EBS:0] e2 = R[BS-1: BS-EBS-1];
  
  wire s1 = S[BS];
  wire s2 = R[BS];
  wire sign = s1^s2;

  wire is_zero_s = (e1 == {EBS+1{1'b0}}) && (m1 == {EBS+1{1'b0}});
  wire is_zero_r = (e2 == {EBS+1{1'b0}}) && (m2 == {EBS+1{1'b0}});
  wire result_is_zero = is_zero_s | is_zero_r;

  wire [7:0] bias = (EBS == 4) ? 8'd15 : 8'd127;
  wire [EBS:0] exp_to_use = e1 + e2 - bias;
  wire [EBS+1:0] evaluate_flags  = e1 + e2;
  wire [EBS+1:0] despues_la_borro= e1 + e2 - bias;

  wire [MBS+1:0] param_m1 = {1'b1, m1};
  wire [MBS+1:0] param_m2 = {1'b1, m2};
  
  wire [MBS:0] m_final;
  wire [EBS:0] exp_final;
  wire over_t2, inexact_core;

  Prod #(.MBS(MBS), .EBS(EBS), .BS(BS)) 
  product_mantisa(param_m1, param_m2, exp_to_use, m_final, exp_final, over_t2, inexact_core);

  assign F[BS]    = result_is_zero ? 1'b0 : sign;
  assign F[BS-1:BS-EBS-1] = result_is_zero ? {EBS+1{1'b0}} : exp_final;
  assign F[MBS:0]   = result_is_zero ? {MBS+1{1'b0}} : m_final;

  // ------------------- Flags ---------------------
  is_invalid_op #(.MBS(MBS), .EBS(EBS), .BS(BS))
  flag4(.Exp1(e1), .Exp2(e2), .Man1(m1), .Man2(m2), .InvalidOp(inv_op));

  wire over_t1   = (evaluate_flags >= bias) && (despues_la_borro >= {EBS+1{1'b1}});
  wire under_t1  = (evaluate_flags <  bias);

  assign overflow   = result_is_zero ? 1'b0 : (over_t1 | over_t2 | inv_op);
  assign underflow  = result_is_zero ? 1'b0 : under_t1;
  assign inexact    = result_is_zero ? 1'b0 : inexact_core;


endmodule