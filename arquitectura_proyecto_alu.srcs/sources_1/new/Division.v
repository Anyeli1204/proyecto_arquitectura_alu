module Division(Sm, Rm, ExpIn, Fm, ExpOut,
                overflow, underflow, inexact);

  input  [10:0] Sm, Rm;
  input  [4:0]  ExpIn;
  wire [14:0] FauxWithoutRound;
  output [9:0]  Fm;
  output [4:0]  ExpOut;
  output overflow; 
  output underflow; 
  output inexact;
  
  function [4:0] first_one_div;
    input [16:0] bits;
    integer idx;
    reg found;
    
    begin
      found = 0;
      first_one_div = 5'b00000; 
      for (idx = 14; idx >= 0 && !found; idx = idx - 1) begin
        if (bits[idx]) begin
          first_one_div = (15 - idx);
          found = 1;
        end
      end
    end
  endfunction
  wire [24:0] Result = {Sm, 15'b0} / Rm;
  wire [16:0] Faux = Result[16:0];

  wire Debe = Faux[16];
  wire ShiftCondition = !Debe && !Faux[15];

  wire [4:0] shifts = (ShiftCondition) ? first_one_div(Faux) : 5'b00000;  
  wire [14:0] Fm_out = (Debe) ? Faux[15:1] : Faux[14:0];
  wire[4:0] ExpOut_temp = (Debe) ? (ExpIn) : (ExpIn - shifts);
  assign FauxWithoutRound = (Debe) ? Fm_out : (Fm_out >> shifts); 
  
  RoundNearestEven rounder(
    .ms(FauxWithoutRound),
    .exp(ExpOut_temp),
    .ms_round(Fm),
    .exp_round(ExpOut)
  );
  // ------------ Flag Section -------------
  wire [10:0] remainder  = {Sm, 15'b0} % Rm;
  wire        rem_nz     = |remainder;
  wire lost_pre_bit      = (Debe) ? Faux[0] : 1'b0;
  wire [16:0] low_mask   = (17'h1 << shifts) - 17'h1;
  wire        lost_shift_bits = (!Debe && (shifts!=0)) ? (|(Faux & low_mask)) : 1'b0;
  wire guard_bit    = FauxWithoutRound[4];
  wire tail_bits_nz = |FauxWithoutRound[3:0];
  assign inexact   = guard_bit | tail_bits_nz | lost_pre_bit | lost_shift_bits | rem_nz;
  assign overflow  = (ExpOut == 5'h1F);
  assign underflow = (ExpOut == 5'd0) & inexact;
endmodule

module DivHP (S, R, F, overflow, underflow, inv_op, inexact);
  input  [15:0] S, R;
  output [15:0] F;
  output overflow, underflow, inv_op, inexact;

  wire [9:0] m1 = S[9:0];
  wire [9:0] m2 = R[9:0];

  wire [4:0] e1 = S[14:10];
  wire [4:0] e2 = R[14:10];

  wire s1 = S[15];
  wire s2 = R[15];
  wire sign = s1 ^ s2;
// Suma de exponentes en el producto.
  wire is_zero_dividend = (e1 == 5'd0) && (m1 == 10'd0);
  wire is_zero_divisor  = (e2 == 5'd0) && (m2 == 10'd0);
  
  wire [4:0] exp_to_use = e1 - e2 + 5'd15;    
  wire [10:0] param_m1 = {1'b1, m1};
  wire [10:0] param_m2 = {1'b1, m2};
  
  wire [9:0] m_final;
  wire [4:0] exp_final;
  wire of_core, uf_core, ix_core;
  
  Division div(
    .Sm(param_m1), .Rm(param_m2), .ExpIn(exp_to_use),
    .Fm(m_final), .ExpOut(exp_final),
    .overflow(of_core), .underflow(uf_core), .inexact(ix_core)
  );
  
  assign F[15]    = (is_zero_dividend && !is_zero_divisor) ? 1'b0 : sign;
  assign F[14:10] = (is_zero_dividend && !is_zero_divisor) ? 5'd0 : exp_final;
  assign F[9:0]   = (is_zero_dividend && !is_zero_divisor) ? 10'd0 : m_final;
  // ------------------- Flags ---------------------
  // Invalid op (NaN, 0/0, Inf/Inf, etc.) como ya tenías:
  is_invalid_op flag4(
    .Exp1(e1), .Exp2(e2), .Man1(m1), .Man2(m2), .InvalidOp(inv_op)
  );

  assign overflow  = (is_zero_dividend && !is_zero_divisor) ? 1'b0 : of_core;
  assign underflow = (is_zero_dividend && !is_zero_divisor) ? 1'b0 : uf_core;
  assign inexact   = (is_zero_dividend && !is_zero_divisor) ? 1'b0 : ix_core;
endmodule
