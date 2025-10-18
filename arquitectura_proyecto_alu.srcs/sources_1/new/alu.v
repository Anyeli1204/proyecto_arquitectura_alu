module alu(
  input  [15:0] a,
  input  [15:0] b,
  input  [1:0]  op,
  output reg [15:0] y,
  output reg [3:0]  ALUFlags
);
  // ----------------- ADD / SUB / MUL / DIV -----------------
  wire [15:0] add_y, sub_y, mul_y, div_y;

  wire ov_add, un_add, ix_add;
  Suma16Bits U_ADD(
    .S(a), .R(b), .F(add_y),
    .overflow(ov_add), .underflow(un_add), .inexact(ix_add)
  );

  wire ov_sub, un_sub, ix_sub;
  Suma16Bits U_SUB(
    .S(a), .R({~b[15], b[14:0]}), .F(sub_y),
    .overflow(ov_sub), .underflow(un_sub), .inexact(ix_sub)
  );

  wire ov_mul, un_mul, iv_mul, ix_mul;
  ProductHP  U_MUL(
    .S(a), .R(b), .F(mul_y),
    .overflow(ov_mul), .underflow(un_mul),
    .inv_op(iv_mul), .inexact(ix_mul)
  );

  wire ov_div, un_div, iv_div, ix_div;
  DivHP U_DIV(
    .S(a), .R(b), .F(div_y),
    .overflow(ov_div), .underflow(un_div),
    .inv_op(iv_div), .inexact(ix_div)
  );

  // ----------------- helpers -----------------
  function is_zero_fp;
    input [15:0] val;
    begin
      is_zero_fp = (val[14:0] == 15'b0);
    end
  endfunction

  // ----------------- mux + flags -----------------
  always @(*) begin
    y        = 16'h0000;
    ALUFlags = 4'b0000; // {N,Z,C,V}
    case (op)
      2'b00: begin // ADD
        y = add_y;
        ALUFlags[3] = y[15];                 // N
        ALUFlags[2] = is_zero_fp(y);         // Z
        ALUFlags[1] = ix_add;                // C := inexact
        ALUFlags[0] = ov_add;     // V := overflow | invalid
      end
      2'b01: begin // SUB
        y = sub_y;
        ALUFlags[3] = y[15];
        ALUFlags[2] = is_zero_fp(y);
        ALUFlags[1] = ix_sub;
        ALUFlags[0] = ov_sub;
      end
      2'b10: begin // MUL
        y = mul_y;
        ALUFlags[3] = y[15];
        ALUFlags[2] = is_zero_fp(y);
        ALUFlags[1] = ix_mul;
        ALUFlags[0] = ov_mul;
      end
      2'b11: begin // DIV
        y = div_y;
        ALUFlags[3] = y[15];
        ALUFlags[2] = is_zero_fp(y);
        ALUFlags[1] = ix_div;
        ALUFlags[0] = ov_div;
      end
      default: begin
        y = 16'h0000;
        ALUFlags = 4'b0000;
      end
    endcase
  end
endmodule
