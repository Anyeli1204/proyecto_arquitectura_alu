`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.10.2025 15:23:09
// Design Name: 
// Module Name: Division
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

module Division(Sm, Rm, ExpIn, Fm, ExpOut);
  input [10:0] Sm, Rm;
  input [4:0] ExpIn;
  wire [14:0] FauxWithoutRound;

  output wire [9:0] Fm;
  output wire [4:0] ExpOut;
  
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

endmodule


// #(parameter N=8), LUEGO adaptar con parameter a 32 bits.
module DivHP (S, R, F);
  
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
  wire [4:0] exp_to_use = e1 - e2 + 5'd15;
    
  assign sign = s1 ^ s2;
  wire [10:0] param_m1 = {1'b1, m1};
  wire [10:0] param_m2 = {1'b1, m2};
  
  wire [9:0] m_final;
  wire [4:0] exp_final;
  Division div(param_m1, param_m2, exp_to_use, m_final, exp_final);
  
  assign F[15] = sign;
  assign F[14:10] = exp_final;
  assign F[9:0] = m_final;
  
endmodule
