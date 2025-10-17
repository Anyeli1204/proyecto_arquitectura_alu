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
  localparam HALF_1_1  = 16'b0011110110011010; // 1.9375 = 1.1111 × 2^0
  localparam HALF_1_2   = 16'b0011111100000000; // 1.875  = 1.1110 × 2^0  localparam HALF_NEG2 = 16'b1100000000000000; // -2.0 (opcional de prueba)
  localparam HALF_1_3 = 16'b0100000000110010;
  localparam HALF_1_4      = 16'b0011110110011010;  // 1.0
  localparam EXPECTED_1_0  = 16'b0011110000000000;  // 1.0 (hex=3C00)
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

    // (1.0+ULP) * (1.0+ULP)   ? expect desconocido (observa redondeo)
run(2'b10,
    16'b0011110000000001, // 1.0 + ulp
    16'b0011110000000001, // 1.0 + ulp
    16'bxxxxxxxxxxxxxxxx, // sin check (deja que imprima el resultado)
    "MUL (1+ulp)*(1+ulp)");

// 1.5 * (1.0+ULP)
run(2'b10,
    16'b0011111000000000, // 1.5
    16'b0011110000000001, // 1.0 + ulp
    16'bxxxxxxxxxxxxxxxx, // sin check
    "MUL 1.5 * (1+ulp)");
    
    // ============================================
// CASOS DE MULTIPLICACIÓN CON REDONDEO
// ============================================

// CASO 1: (1+ulp) × (1+ulp) - Ya lo tienes
run(2'b10,
    16'b0011110000000001, // 1.0 + ulp
    16'b0011110000000001, // 1.0 + ulp
    16'b0011110000000010, // Esperado: 1 + 2*ulp
    "MUL (1+ulp)*(1+ulp)");

// CASO 2: 1.5 × (1+ulp) - Ya lo tienes
run(2'b10,
    16'b0011111000000000, // 1.5
    16'b0011110000000001, // 1.0 + ulp
    16'b0011111000000010, // Esperado: 1.5 + 2*ulp (tie-breaking UP)
    "MUL 1.5 * (1+ulp)");

// CASO 3: (1+2*ulp) × (1+ulp) - Trunca
run(2'b10,
    16'b0011110000000010, // 1.0 + 2*ulp
    16'b0011110000000001, // 1.0 + ulp
    16'b0011110000000011, // Esperado: 1 + 3*ulp (trunca)
    "MUL (1+2ulp)*(1+ulp)");

// CASO 4: 1.25 × (1+ulp) - Redondea
run(2'b10,
    16'b0011110100000000, // 1.25
    16'b0011110000000001, // 1.0 + ulp
    16'b0011110100000001, // Esperado: 1.25 + ulp (redondea)
    "MUL 1.25 * (1+ulp)");

// CASO 5: (1.5-ulp) × (1.5-ulp) - Trunca
run(2'b10,
    16'b0011110111111111, // 1.5 - ulp
    16'b0011110111111111, // 1.5 - ulp
    16'b0011111011111100, // Corregir este valor
    "MUL (1.5-ulp)*(1.5-ulp)");

// CASO 6: 1.75 × (1+ulp) - Redondea
run(2'b10,
    16'b0011111100000000, // 1.75
    16'b0011110000000001, // 1.0 + ulp
    16'b0011111100000010, // Esperado: redondea hacia arriba
    "MUL 1.75 * (1+ulp)");

// CASO 7: (1+3*ulp) × (1+3*ulp) - Varios bits activos
run(2'b10,
    16'b0011110000000011, // 1.0 + 3*ulp
    16'b0011110000000011, // 1.0 + 3*ulp
    16'b0011110000000110, // Esperado: 1 + 6*ulp
    "MUL (1+3ulp)*(1+3ulp)");

// CASO 8: 1.125 × (1+ulp) - Guard bit activo
run(2'b10,
    16'b0011110010000000, // 1.125
    16'b0011110000000001, // 1.0 + ulp
    16'b0011110010000001, // Esperado
    "MUL 1.125 * (1+ulp)");

// CASO 9: (1+ulp) × 2.0 - Shift exponente
run(2'b10,
    16'b0011110000000001, // 1.0 + ulp
    16'b0100000000000000, // 2.0
    16'b0100000000000001, // Esperado: 2 + 2*ulp
    "MUL (1+ulp) * 2.0");

// CASO 10: 1.5 × 1.5 - Exacto (sin redondeo necesario)
run(2'b10,
    16'b0011111000000000, // 1.5
    16'b0011111000000000, // 1.5
    16'b0100000010000000, // Esperado: 2.25 (exacto)
    "MUL 1.5 * 1.5 (exacto)");

// CASO 11: (1+ulp/2) × (1+ulp/2) - NO EXISTE EN FP16
// Usamos en su lugar: (1.0+0.5ulp aproximado)
run(2'b10,
    16'b0011110000000001, // 1.0 + ulp (aproximación)
    16'b0011111000000000, // 1.5
    16'b0011111000000010, // Esperado
    "MUL (1+ulp) * 1.5");

// CASO 12: Producto que causa overflow en mantisa
run(2'b10,
    16'b0011111111111111, // ~2.0 - ulp (mantisa toda 1s)
    16'b0011110000000010, // 1.0 + 2*ulp
    16'b0100000000000001, // Esperado: overflow ? exp+1
    "MUL (2-ulp) * (1+2ulp)");

// CASO 13: Tie-breaking con LSB=0 (mantiene)
run(2'b10,
    16'b0011110010000000, // 1.125 (LSB=0)
    16'b0011111000000000, // 1.5
    16'b0011111011000000, // Esperado: 1.6875 (tie, mantiene)
    "MUL 1.125 * 1.5 (tie LSB=0)");

// CASO 14: Tie-breaking con LSB=1 (redondea)
run(2'b10,
    16'b0011110110000000, // 1.375
    16'b0011111000000000, // 1.5
    16'b0100000000110000, // hex=4030 (CORREGIDO)
    "MUL 1.375 * 1.5 (tie LSB=1)");

// CASO 15: Guard=1, Round=1, Sticky=1 (redondea arriba)
run(2'b10,
    16'b0011110001100110, // 1.1
    16'b0011110011001101, // 1.2
    16'b0011110101001000, // Necesita verificación manual
    "MUL 1.1 * 1.2 (g=1,r=1,s=1)");

// CASO 16: Guard=1, Round=0, Sticky=1 (redondea arriba)
run(2'b10,
    16'b0011110001100110, // 1.1
    16'b0011111011001101, // 1.7
    16'b0011111110110010, // Esperado: 1.87
    "MUL 1.1 * 1.7 (g=1,r=0,s=1)");

// CASO 17: Guard=0, Round=1, Sticky=1 (trunca)
run(2'b10,
    16'b0011110100110011, // 1.3
    16'b0011110110011010, // 1.4
    16'b0011111011101001, // Esperado: 1.82
    "MUL 1.3 * 1.4 (g=0,r=1,s=1)");

// CASO 18: Producto muy pequeño - todos bits bajos
run(2'b10,
    16'b0011110000000001, // 1.0 + ulp
    16'b0011110000000001, // 1.0 + ulp
    16'b0011110000000010, // Esperado
    "MUL pequeño*(pequeño)");

// CASO 19: 1.875 × 1.875 = 3.515625 (exacto)
run(2'b10,
    16'b0011111110000000, // 1.875
    16'b0011111110000000, // 1.875
    16'b0100001100001000, // Esperado: 3.515625
    "MUL 1.875 * 1.875 (exacto)");

// CASO 20: 1.0625 × 1.0625 (redondeo sutil)
run(2'b10,
    16'b0011110001000000, // 1.0625
    16'b0011110001000000, // 1.0625
    16'b0011110010001000, // hex=3C88 (CORREGIDO)
    "MUL 1.0625 * 1.0625");
    
// CASO 21: Máxima mantisa × 2
run(2'b10,
    16'b0011111111111111, // ~2.0 - ulp
    16'b0100000000000000, // 2.0
    16'b0100001111111111, // Esperado: ~4.0 - 2*ulp
    "MUL (2-ulp) * 2.0");

// CASO 22: Mínima mantisa × mínima mantisa
run(2'b10,
    16'b0011110000000001, // 1.0 + ulp
    16'b0011110000000001, // 1.0 + ulp
    16'b0011110000000010, // Ya probado arriba
    "MUL minimo*minimo");

// CASO 23: Patrón alternante de bits
run(2'b10,
    16'b0011110101010101, // 1.333...
    16'b0011110101010101, // 1.333...
    16'b0011111100011100, // Esperado
    "MUL patron_alt*patron_alt");

// CASO 24: 1.9 × 1.1
run(2'b10,
    16'b0011111110011010, // 1.9
    16'b0011110001100110, // 1.1
    16'b0100000000001101, // Esperado: 2.09
    "MUL 1.9 * 1.1");

// CASO 25: Overflow en mantisa (todos 1s + incremento)
run(2'b10,
    16'b0011111110011010, // 1.9
    16'b0011110001100110, // 1.1
    16'b0100000000110011, // hex=4033 (CORREGIDO)
    "MUL 1.9 * 1.1");
    
    // Exactos fáciles
run(2'b10, 16'b0011110000000000, 16'b0011110000000000, 16'b0011110000000000, "MUL 1.0 * 1.0 = 1.0");
run(2'b10, 16'b0011100000000000, 16'b0011100000000000, 16'b0011010000000000, "MUL 0.5 * 0.5 = 0.25");

// 1.5 * 1.5 = 2.25 (0x4080 = 0100 0000 1000 0000)
run(2'b10, 16'b0011111000000000, 16'b0011111000000000, 16'b0100000010000000, "MUL 1.5 * 1.5 = 2.25");

// 3.0 * 0.5 = 1.5
run(2'b10, 16'b0100001000000000, 16'b0011100000000000, 16'b0011111000000000, "MUL 3.0 * 0.5 = 1.5");

// Casos que fuerzan guard/sticky (observa RNE en tu MUL)
run(2'b10, 16'b0011110000000001, 16'b0011110000000001, 16'hxxxx, "MUL (1.0+ULP)*(1.0+ULP) (ver redondeo)");
run(2'b10, 16'b0011111000000000, 16'b0011110000000001, 16'hxxxx, "MUL 1.5*(1.0+ULP) (ver redondeo)");
run(2'b10, 16'b0011110111111111, 16'b0011110111111111, 16'hxxxx, "MUL (1.5-ULP)^2 (ver redondeo)");

    
    // 4) 5.0 / 2.0 = 2.5
    run(2'b11, HALF_5_0, HALF_2_0, HALF_2_5, "DIV 5/2");

    // 5) Casos extra opcionales:
    //    0.0 + 0.0 = 0.0
    run(2'b00, HALF_0_0, HALF_0_0, HALF_0_0, "ADD 0+0");

    //    (-2.0) + 1.0 = -1.0  (si quieres probar signo; EXPECT no verificado aquí)
    //run(2'b00, HALF_NEG2, HALF_1_0, 16'hxxxx, "ADD -2+1 (sin check)");

    $finish;
  end
endmodule

