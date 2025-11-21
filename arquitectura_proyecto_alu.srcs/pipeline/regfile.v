module regfile(input  clk, 
               input  we3, 
               input  [ 4:0] a1, a2, a3, 
               input  [31:0] wd3, 
               output [31:0] rd1, rd2); 

  reg [31:0] rf[0:31];  // Arreglo con índice explícito [0:31]
  
  // Inicializar todos los registros a 0 explícitamente
  integer i;
  initial begin
    for (i = 0; i < 32; i = i + 1) begin
      rf[i] = 32'b0;
    end
  end

  // write third port on rising edge of clock (A3/WD3/WE3)
  // registro 0 está hardwired a 0, no se puede escribir
  always @(posedge clk) begin 
    if (we3 == 1'b1 && a3 != 5'b0) begin
      $display("[REGFILE WRITE] Ciclo: %0t | rf[%0d] <= %h | we3=%b | ANTES: rf[%0d]=%h", 
               $time, a3, wd3, we3, a3, rf[a3]);
      rf[a3] <= wd3;
      // Verificar inmediatamente después (aunque en Verilog la asignación <= es al final del timestep)
      $display("[REGFILE WRITE] Ciclo: %0t | DESPUES del <=, rf[%0d] todavía muestra: %h (espera al siguiente ciclo)", 
               $time, a3, rf[a3]);
    end
  end
  
  // Verificar el valor DESPUÉS del flanco de reloj (cuando ya debería estar actualizado)
  always @(posedge clk) begin
    #1; // Pequeño delay para verificar después del flanco
    if (rf[2] != 32'b0 || rf[5] != 32'b0 || rf[6] != 32'b0) begin
      $display("[REGFILE CHECK] Ciclo: %0t | rf[2]=%h, rf[5]=%h, rf[6]=%h", 
               $time, rf[2], rf[5], rf[6]);
    end
  end
  
  // read two ports combinationally (A1/RD1, A2/RD2)
  // register 0 hardwired to 0
  // Lectura directa con assign
  assign rd1 = (a1 == 5'b0) ? 32'b0 : rf[a1];
  assign rd2 = (a2 == 5'b0) ? 32'b0 : rf[a2];
  
  // Debug de lectura - solo mostrar cuando a1 o a2 cambian
  reg [4:0] a1_prev, a2_prev;
  
  always @(posedge clk) begin
    if (a1 != a1_prev && a1 != 5'b0 && a1 <= 5'd31) begin
      $display("[REGFILE READ] Ciclo: %0t | rd1 = rf[%0d] = %h", $time, a1, rd1);
    end
    if (a2 != a2_prev && a2 != 5'b0 && a2 <= 5'd31) begin
      $display("[REGFILE READ] Ciclo: %0t | rd2 = rf[%0d] = %h", $time, a2, rd2);
    end
    a1_prev <= a1;
    a2_prev <= a2;
  end
endmodule