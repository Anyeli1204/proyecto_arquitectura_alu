`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.10.2025 15:47:32
// Design Name: 
// Module Name: tb_alu_flags
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
module tb_alu_smoke;

  reg  [15:0] a, b;
  reg  [1:0]  op;
  wire [15:0] y;
  wire [3:0]  flags;   // {N,Z,C,V}

  alu DUT(.a(a), .b(b), .op(op), .y(y), .ALUFlags(flags));

  // Half-precision en BINARIO: sign | exponent(5) | fraction(10)
  localparam [15:0] HP_Z         = 16'b0_00000_0000000000; // +0
  localparam [15:0] HP_ONE       = 16'b0_01111_0000000000; //  1.0
  localparam [15:0] HP_TWO       = 16'b0_10000_0000000000; //  2.0
  localparam [15:0] HP_ONEP5     = 16'b0_01111_1000000000; //  1.5
  localparam [15:0] HP_THREE     = 16'b0_10000_1000000000; //  3.0
  localparam [15:0] HP_FIVE      = 16'b0_10001_0100000000; //  5.0
  localparam [15:0] HP_2P5       = 16'b0_10000_0100000000; //  2.5
  localparam [15:0] HP_MAXF      = 16'b0_11110_1111111111; //  max finito
  localparam [15:0] HP_INF       = 16'b0_11111_0000000000; //  +Inf
  localparam [15:0] HP_HALF_LSB1 = 16'b0_01110_0000000001; // 0.500488...

  task run(input [1:0] op_i, input [15:0] a_i, input [15:0] b_i, input [127:0] name);
    begin
      op = op_i; a = a_i; b = b_i; #5;
      $display("%s  op=%b  a=%b  b=%b  => y=%b  Flags(NZCV)=%b",
               name, op, a, b, y, flags);
    end
  endtask

  initial begin
    $display("\n===== ALU smoke test (NZCV: N=sign, Z=zero, C=inexact, V=overflow|inv) =====");

    // ADD
    run(2'b00, HP_ONE,   HP_ONE,       "ADD 1.0 + 1.0  (espera y=2.0, V=0, C=0)");
    run(2'b00, HP_ONE,   HP_HALF_LSB1, "ADD 1.0 + 0.500488 (C=inexact=1)");
    run(2'b00, HP_MAXF,  HP_MAXF,      "ADD max + max (espera overflow V=1)");

    // SUB
    run(2'b01, HP_THREE, HP_TWO,       "SUB 3.0 - 2.0 (espera y=1.0, V=0)");
    run(2'b01, HP_ONE,   HP_ONE,       "SUB 1.0 - 1.0 (y=+0.0, Z=1)");

    // MUL
    run(2'b10, HP_ONEP5, HP_ONEP5,     "MUL 1.5 * 1.5 (espera y=2.25, C?0, V=0)");

    // DIV
    run(2'b11, HP_FIVE,  HP_TWO,       "DIV 5.0 / 2.0 (espera y=2.5, C=0, V=0)");
    run(2'b11, HP_INF,   HP_INF,       "DIV Inf / Inf (inv_op->V=1 en tu mapeo)");

    $finish;
  end
endmodule

