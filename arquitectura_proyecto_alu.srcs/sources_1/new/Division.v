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
  output wire [9:0] Fm;
  output wire [4:0] ExpOut;
  
  function [4:0] first_one_div;
  input [11:0] bits;
  integer idx;
  reg found;
  
  begin
    found = 0;
    first_one_div = 5'b00000; 
    
    for (idx = 10; idx >= 0 && !found; idx = idx - 1) begin
      if (bits[idx]) begin
        first_one_div = (11 - idx);
        found = 1;
      end
    end

  end
  
endfunction
  
  wire [21:0] Result = {Sm, 11'b0} / Rm;
  wire [12:0] Faux = Result[12:0];

  wire Debe = Faux[12];
  wire ShiftCondition = !Debe && !Faux[11];
  
  wire [4:0] shifts = (ShiftCondition) ? first_one_div(Faux) : 5'b00000;  
  
  wire [9:0] Fm_out = (Debe) ? Faux[11:2] : Result[10:1];

  assign ExpOut = (Debe) ? (ExpIn ) : (ExpIn - shifts);
  
  assign Fm = (Debe) ? Fm_out : (Fm_out >> shifts);
  
  /*
  initial begin
    $monitor("result: %b, faux: %b, Fout: %b, ExpIn: %b, ExpOut: %b, SC: %b", Result, Faux, Fm, ExpIn, ExpOut, ShiftCondition);
  
  end
  */
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
