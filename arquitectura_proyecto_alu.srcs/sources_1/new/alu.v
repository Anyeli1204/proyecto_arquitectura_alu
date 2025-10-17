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
  output reg [15:0] y,
  output reg [3:0] ALUFlags
);
  wire [15:0] add_y, sub_y, mul_y, div_y;
  Suma16Bits U_ADD(.S(a), .R(b),                 .F(add_y));
  Suma16Bits U_SUB(.S(a), .R({~b[15], b[14:0]}), .F(sub_y)); // a + (-b)
  wire ov_mul, un_mul, iv_mul, ix_mul;
  ProductHP  U_MUL(
    .S(a), .R(b), .F(mul_y),
    .overflow(ov_mul), .underflow(un_mul),
    .inv_op(iv_mul), .inexact(ix_mul)
  );  DivHP      U_DIV(.S(a), .R(b),                 .F(div_y));
  function is_zero_fp;
    input [15:0] val;
    begin
      is_zero_fp = (val[14:0] == 15'b0);
    end
  endfunction
  always @(*) begin
    y        = 16'h0000;
    ALUFlags = 4'b0000; // {N,Z,C,V}
    case (op)
      2'b00: begin // ADD
        y = add_y;
        ALUFlags[3] = y[15];           // N
        ALUFlags[2] = is_zero_fp(y);   // Z
        ALUFlags[1] = 1'b0;            // C (no implementado aún)
        ALUFlags[0] = 1'b0;            // V (no implementado aún)
      end

      2'b01: begin // SUB
        y = sub_y;
        ALUFlags[3] = y[15];
        ALUFlags[2] = is_zero_fp(y);
        ALUFlags[1] = 1'b0;
        ALUFlags[0] = 1'b0;
      end

      2'b10: begin // MUL (AQUÍ sí activamos flags)
        y = mul_y;
        ALUFlags[3] = y[15];            // N
        ALUFlags[2] = is_zero_fp(y);    // Z
        ALUFlags[1] = ix_mul;           // C := inexact (tu helper is_inexact)
        ALUFlags[0] = (ov_mul | iv_mul);// V := overflow (y opcionalmente inválida)
      end

      2'b11: begin // DIV
        y = div_y;
        ALUFlags[3] = y[15];
        ALUFlags[2] = is_zero_fp(y);
        ALUFlags[1] = 1'b0;
        ALUFlags[0] = 1'b0;
      end

      default: begin
        y = 16'h0000;
        ALUFlags = 4'b0000;
      end
    endcase
  end
endmodule
