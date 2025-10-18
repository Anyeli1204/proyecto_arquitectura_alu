`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.10.2025 16:38:16
// Design Name: 
// Module Name: flags_operations
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
