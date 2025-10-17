`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.10.2025 16:42:49
// Design Name: 
// Module Name: tb_alu
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
module tb_fp16_alu_basic;
  reg  [15:0] a, b;
  reg  [1:0]  op;
  wire [15:0] y;

  alu DUT(.a(a), .b(b), .op(op), .y(y));

  // half útiles: 1.0=0x3C00, 2.0=0x4000, 3.0=0x4200, 5.0=0x4500, 0.5=0x3800
  task show(input [127:0] msg);
    begin #1 $display("%s  op=%b a=%h b=%h => y=%h", msg, op, a, b, y); end
  endtask

  initial begin
    // ADD: 1.0 + 1.0 = 2.0
    op=2'b00; a=16'h3C00; b=16'h3C00; #5; show("ADD");

    // SUB: 3.0 - 2.0 = 1.0
    op=2'b01; a=16'h4200; b=16'h4000; #5; show("SUB");

    // MUL: 3.0 * 0.5 = 1.5 (?0x3E00)
    op=2'b10; a=16'h4200; b=16'h3800; #5; show("MUL");

    // DIV: 5.0 / 2.0 = 2.5 (?0x4200 -> 2.5 ? 0x4200? OJO según tu divisor)
    op=2'b11; a=16'h4500; b=16'h4000; #5; show("DIV");

    $finish;
  end
endmodule

