`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.10.2025 19:36:16
// Design Name: 
// Module Name: RoundNearestEven
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

module RoundNearestEven(ms, exp, ms_round, exp_round);
  input  [14:0] ms;
  input  [4:0]  exp;
  output [9:0]  ms_round;
  output [4:0]  exp_round;
  function is_necesary_round;
    input [4:0] bits;
    integer idx;
    begin
      is_necesary_round = 1'b0;
      for (idx = 4; idx >= 0 && !is_necesary_round; idx = idx-1)
        if (bits[idx]) is_necesary_round = 1'b1;
    end
  endfunction
  wire guard   = ms[4];
  wire boolean = is_necesary_round({1'b0, ms[3:0]});  // OR de (round|sticky)
  wire is_even = ~ms[5]; // LSB de los 10 bits guardados
  wire [10:0] temp = ms[14:5] + ((guard && (boolean || !is_even)) ? 1 : 0);
  assign ms_round  = temp[9:0];
  assign exp_round = exp + temp[10];
endmodule