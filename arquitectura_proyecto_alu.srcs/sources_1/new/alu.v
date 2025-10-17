`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.10.2025 15:27:41
// Design Name: 
// Module Name: alu
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

module alu(
  input  [15:0] a,
  input  [15:0] b,
  input  [1:0]  op,
  output reg [15:0] y
);
  wire [15:0] add_y, sub_y, mul_y, div_y;
  Suma16Bits U_ADD(.S(a), .R(b),                 .F(add_y));
  Suma16Bits U_SUB(.S(a), .R({~b[15], b[14:0]}), .F(sub_y)); // a + (-b)
  ProductHP  U_MUL(.S(a), .R(b),                 .F(mul_y));
  DivHP      U_DIV(.S(a), .R(b),                 .F(div_y));

  always @(*) begin
    case (op)
      2'b00: y = add_y; 
      2'b01: y = sub_y; 
      2'b10: y = mul_y; 
      2'b11: y = div_y; 
      default: y = 16'h0000;
    endcase
  end
endmodule

