`timescale 1ns / 1ps

module Division #(parameter MBS=9, EBS=4, BS=15) (Sm, Rm, ExpIn, Fm, ExpOut,
  overflow, underflow, inexact);

  input [MBS+1:0] Sm, Rm;
  input [EBS:0] ExpIn;
  output wire [MBS:0] Fm;
  output wire [EBS:0] ExpOut;
  output        overflow, underflow, inexact;

  parameter FSIZE = MBS + 5;
  wire [FSIZE:0] FauxWithoutRound;

  function [EBS:0] first_one_div;
    input [FSIZE+2:0] bits;
    integer idx;
    reg found;
    
    begin
      found = 0;
      first_one_div = {EBS+1{1'b0}};; 
      
      for (idx = FSIZE; idx >= 0 && !found; idx = idx - 1) begin
        if (bits[idx]) begin
          first_one_div = (FSIZE + 1 - idx);
          found = 1;
        end
      end


    end
  
  endfunction

  // 15'b0 <- 5 evaluar redondeo + 10 se puros 0's.
  wire [FSIZE + 10:0] Result = {Sm, {FSIZE+1{1'b0}}} / Rm;
  wire [FSIZE + 2:0] Faux = Result[FSIZE+2: 0];

  wire Debe = Faux[FSIZE + 2];
  wire ShiftCondition = !Debe && !Faux[FSIZE + 1];

  wire [EBS:0] shifts = (ShiftCondition) ? first_one_div(Faux) : {EBS+1{1'b0}};  
  wire [FSIZE:0] Fm_out = (Debe) ? Faux[FSIZE+1:1] : Faux[FSIZE:0];
  wire[EBS:0] ExpOut_temp = (Debe) ? (ExpIn) : (ExpIn - shifts);
  assign FauxWithoutRound = (Debe) ? Fm_out : (Fm_out >> shifts);

  RoundNearestEven #(.MBS(MBS), .EBS(EBS), .BS(BS), .FSIZE(FSIZE)) rounder(
    .ms(FauxWithoutRound),
    .exp(ExpOut_temp),
    .ms_round(Fm),
    .exp_round(ExpOut)
  );

  // ------------ Flag Section -------------
  wire [MBS+1:0] remainder  = {Sm, {FSIZE+1{1'b0}}} % Rm;
  wire        rem_nz     = |remainder;

  wire lost_pre_bit      = (Debe) ? Faux[0] : 1'b0;
  wire [FSIZE + 2:0] low_mask   = (1 << shifts) - 1;

  wire        lost_shift_bits = (!Debe && (shifts!=0)) ? (|(Faux & low_mask)) : 1'b0;

  wire guard_bit    = FauxWithoutRound[4];
  wire tail_bits_nz = |FauxWithoutRound[3:0];

  assign inexact   = guard_bit | tail_bits_nz | lost_pre_bit | lost_shift_bits | rem_nz;
  assign overflow  = (ExpOut == {EBS+1{1'b1}});
  assign underflow = (ExpOut == {EBS+1{1'b0}}) & inexact;

endmodule


module DivHP #(parameter MBS=9, parameter EBS=4, parameter BS=15) (S, R, F, 
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
  wire sign = s1 ^ s2;

  wire is_zero_dividend = (e1 == {EBS+1{1'b0}}) && (m1 == {EBS+1{1'b0}});
  wire is_zero_divisor  = (e2 == {EBS+1{1'b0}}) && (m2 == {EBS+1{1'b0}});

  wire [7:0] bias = (EBS == 4) ? 8'd15 : 8'd127;
       
  // Suma de exponentes en el producto. FALTA CAMBIAR ESTE 15 POR BIAS

  wire [EBS:0] exp_to_use = e1 - e2 + bias;
    
  wire [MBS+1:0] param_m1 = {1'b1, m1};
  wire [MBS+1:0] param_m2 = {1'b1, m2};
  
  wire [MBS:0] m_final;
  wire [EBS:0] exp_final;
  wire of_core, uf_core, ix_core;


  Division #(.MBS(MBS), .EBS(EBS), .BS(BS)) 
  div(param_m1, param_m2, exp_to_use, m_final, exp_final, 
      of_core, uf_core, ix_core);
  
  assign F[BS] = (is_zero_dividend && !is_zero_divisor) ? 1'b0 : sign;
  assign F[BS-1: BS-EBS-1] = (is_zero_dividend && !is_zero_divisor) ? {EBS+1{1'b0}} : exp_final;
  assign F[MBS: 0] = (is_zero_dividend && !is_zero_divisor) ? {MBS+1{1'b0}} : m_final;
  
  // ------------------- Flags ---------------------
  is_invalid_op #(.MBS(MBS), .EBS(EBS), .BS(BS)) flag4(
    .Exp1(e1), .Exp2(e2), .Man1(m1), .Man2(m2), .InvalidOp(inv_op)
  );

  assign overflow  = (is_zero_dividend && !is_zero_divisor) ? 1'b0 : of_core;
  assign underflow = (is_zero_dividend && !is_zero_divisor) ? 1'b0 : uf_core;
  assign inexact   = (is_zero_dividend && !is_zero_divisor) ? 1'b0 : ix_core;

endmodule