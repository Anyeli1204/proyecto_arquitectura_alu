`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.10.2025 01:06:49
// Design Name: 
// Module Name: tb_redondeo_extras
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
module tb_RoundNearestEven_more;

  // DUT
  reg  [14:0] ms;
  reg  [4:0]  exp;
  wire [9:0]  ms_round;
  wire [4:0]  exp_round;

  RoundNearestEven dut(.ms(ms), .exp(exp), .ms_round(ms_round), .exp_round(exp_round));

  // ===== Modelo de referencia (dentro del TB) =====
  // ms[14:5] = top10, ms[4] = guard, ms[3:0] = resto
  function [10:0] rne_ref; // [10]=carry, [9:0]=frac
    input [9:0] top10;
    input       guard;
    input [3:0] rest4;
    reg         lsb;
    reg         inc;
    reg  [10:0] tmp;
    begin
      lsb = top10[0];
      inc = guard & ( (|rest4) | lsb ); // RNE: >1/2 o tie con LSB=1
      tmp = {1'b0, top10} + inc;
      rne_ref = tmp; // [10]=carry, [9:0]=frac
    end
  endfunction

  task do_case(
    input [9:0] top10, input guard, input [3:0] rest4, input [4:0] exp_in,
    input [127:0] name
  );
    reg [10:0] ref;
    reg [14:0] ms_loc;
    begin
      ms_loc = {top10, guard, rest4};
      ms     = ms_loc;
      exp    = exp_in;
      #1;
      ref = rne_ref(top10, guard, rest4);

      $display("%s  ms=%b  exp=%b  -> ms_round=%b exp_round=%b  %s",
        name, ms_loc, exp_in, ms_round, exp_round,
        ((ms_round === ref[9:0]) && (exp_round === (exp_in + ref[10])))
          ? "OK" : "MISMATCH");

      if (!((ms_round === ref[9:0]) && (exp_round === (exp_in + ref[10])))) begin
        $display("  EXPECT frac=%b carry=%b exp_out=%b",
                 ref[9:0], ref[10], exp_in + ref[10]);
      end
    end
  endtask

  integer i;

  initial begin
    $display("===== Directed tests (casos cl�sicos) =====");

    // A) guard=0 ? nunca incrementa (trunca)
    do_case(10'b1010101010, 1'b0, 4'b0000, 5'b01101, "A1 guard=0 rest=0 lsb=0 ? trunc");
    do_case(10'b1001000001, 1'b0, 4'b0100, 5'b01111, "A2 guard=0 rest>0 lsb=1 ? trunc");

    // B) empate (guard=1, rest=0) ? redondea al par (seg�n LSB)
    do_case(10'b0000000010, 1'b1, 4'b0000, 5'b01111, "B1 tie, lsb=0 ? keep (even)");
    do_case(10'b0000000001, 1'b1, 4'b0000, 5'b01111, "B2 tie, lsb=1 ? +1  (odd?even)");
    do_case(10'b1111111111, 1'b1, 4'b0000, 5'b01111, "B3 tie, all1 + carry ? frac=0 exp+1");

    // C) > 1/2 (guard=1, rest>0) ? siempre incrementa
    do_case(10'b0000000010, 1'b1, 4'b0001, 5'b10000, "C1 >1/2, lsb=0 ? +1");
    do_case(10'b0000000011, 1'b1, 4'b0010, 5'b10000, "C2 >1/2, lsb=1 ? +1");
    do_case(10'b1111111111, 1'b1, 4'b1111, 5'b01110, "C3 >1/2, all1 + carry ? frac=0 exp+1");

    // D) casos cero/top10 peque�os
    do_case(10'b0000000000, 1'b1, 4'b0000, 5'b01101, "D1 top10=0, tie lsb=0 ? keep");
    do_case(10'b0000000000, 1'b1, 4'b0001, 5'b01101, "D2 top10=0, >1/2 ? +1 (frac=1)");

    // E) borde de carry parcial (no all-ones)
    do_case(10'b0111111111, 1'b1, 4'b0000, 5'b10001, "E1 tie, lsb=1 ? +1 sin carry global");
    do_case(10'b0111111111, 1'b1, 4'b0001, 5'b10001, "E2 >1/2 ? +1, puede cascada parcial");

    $display("===== Random fuzz (200 casos) =====");
   for (i = 0; i < 200; i = i + 1) begin : fuzz_blk
  // Declaraciones AL INICIO del bloque nombrado
  reg [9:0] top10;
  reg       guard;
  reg [3:0] rest4;
  reg [4:0] exp_in;

  // Luego ya usas las vars
  top10 = $urandom;
  guard = $urandom;
  rest4 = $urandom;
  exp_in= $urandom;

  do_case(top10, guard, rest4, exp_in, {"RND#", i[31:0]});
end

    $finish;
  end
endmodule

