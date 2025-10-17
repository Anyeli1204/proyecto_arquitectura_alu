`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.10.2025 18:19:17
// Design Name: 
// Module Name: tb_alu_bin
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
module tb_alu_bin;
  // DUT
  reg  [15:0] a, b;
  reg  [1:0]  op;
  wire [15:0] y;

  alu DUT(.a(a), .b(b), .op(op), .y(y));

  // ====== Constantes HALF en BINARIO ======
  // sign | exponent(5) | fraction(10)
  localparam HALF_0_0 = 16'b0000000000000000; // 0.0
  localparam HALF_1_0 = 16'b0011110000000000; // 1.0
  localparam HALF_2_0 = 16'b0100000000000000; // 2.0
  localparam HALF_3_0 = 16'b0100001000000000; // 3.0
  localparam HALF_0_5 = 16'b0011100000000000; // 0.5
  localparam HALF_1_5 = 16'b0011111000000000; // 1.5
  localparam HALF_2_5 = 16'b0100000100000000; // 2.5
  localparam HALF_5_0 = 16'b0100010100000000; // 5.0
  localparam HALF_NEG2 = 16'b1100000000000000; // -2.0 (opcional de prueba)

  // Tarea helper con EXPECT en binario
  task run(input [1:0] op_i,
           input [15:0] a_i, input [15:0] b_i,
           input [15:0] expect, input [127:0] name);
    begin
      op = op_i; a = a_i; b = b_i;
      #5; // pequeño delay
      $display("%s  op=%b  a=%b  b=%b  => y=%b (hex=%h)  %s",
               name, op, a, b, y, y,
               (expect !== 16'hxxxx && y !== expect) ? "MISMATCH" : "OK");
    end
  endtask

  initial begin
    // 1) 1.0 + 1.0 = 2.0
    run(2'b00, HALF_1_0, HALF_1_0, HALF_2_0, "ADD 1+1");

    // 2) 3.0 - 2.0 = 1.0
    run(2'b01, HALF_3_0, HALF_2_0, HALF_1_0, "SUB 3-2");

    // 3) 3.0 * 0.5 = 1.5
    run(2'b10, HALF_3_0, HALF_0_5, HALF_1_5, "MUL 3*0.5");

    // 4) 5.0 / 2.0 = 2.5
    run(2'b11, HALF_5_0, HALF_2_0, HALF_2_5, "DIV 5/2");

    // 5) Casos extra opcionales:
    //    0.0 + 0.0 = 0.0
    run(2'b00, HALF_0_0, HALF_0_0, HALF_0_0, "ADD 0+0");

    //    (-2.0) + 1.0 = -1.0  (si quieres probar signo; EXPECT no verificado aquí)
    run(2'b00, HALF_NEG2, HALF_1_0, 16'hxxxx, "ADD -2+1 (sin check)");

    $finish;
  end
endmodule

