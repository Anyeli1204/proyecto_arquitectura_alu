`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.10.2025 19:37:08
// Design Name: 
// Module Name: tb_redondeo
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


`timescale 1ns/1ps
module tb_RoundNearestEven;

  reg  [14:0] ms;
  reg  [4:0]  exp;
  wire [9:0]  ms_round;
  wire [4:0]  exp_round;

  RoundNearestEven uut(.ms(ms), .exp(exp), .ms_round(ms_round), .exp_round(exp_round));

  initial begin
    $display("----- Test RoundNearestEven (boolean && !is_even) -----");

    // TC1: sin redondeo (resto=0)
    ms  = 15'b1001000000_00000; exp = 5'b01111; #1;
    $display("TC1 ms=%b exp=%b -> ms_round=%b exp_round=%b  (esperado: =top, exp igual)", ms, exp, ms_round, exp_round);

// TC2: NO redondeo (guard=0 aunque resto!=0 y LSB=1) ? truncar
ms  = 15'b1001000001_00100;  exp = 5'b01111;  #1;
$display("TC2 ms=%b exp=%b -> ms_round=%b exp_round=%b  (esperado: =top, exp igual)",
         ms, exp, ms_round, exp_round);

    // TC3: redondeo con carry (top=1111111111 y resta!=0 y LSB=1)
ms  = 15'b1111111111_10000;  // guard=1, resto=0, lsb=1 ? inc=1
exp = 5'b01111;
#1 $display("TC3: ms=%b exp=%b -> ms_round=%b exp_round=%b (esperado: 000...0, exp+1)",
            ms, exp, ms_round, exp_round);
$display("g=%b rest=%b lsb=%b inc?=%b",
         ms[4], |ms[3:0], ms[5], (ms[4] & (|ms[3:0] | ms[5])));

    // TC4: hay resto pero LSB es par (no incrementa con tu regla)
    ms  = 15'b1010101010_00001; exp = 5'b01101; #1;
    $display("TC4 ms=%b exp=%b -> ms_round=%b exp_round=%b  (esperado: =top, exp igual)", ms, exp, ms_round, exp_round);

    // TC5: empate exacto (low=10000) con LSB par -> no incrementa (ties-to-even)
    ms  = 15'b1010101010_10000; exp = 5'b01101; #1;
    $display("TC5 ms=%b exp=%b -> ms_round=%b exp_round=%b  (esperado: =top, exp igual)", ms, exp, ms_round, exp_round);

    $finish;
  end
endmodule

