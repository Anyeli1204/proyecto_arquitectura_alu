`timescale 1ns/1ps

module tb_alu_frandom16;

  // =====================================
  // Señales
  // =====================================
  reg  [15:0] a, b;
  reg  [1:0]  op;
  wire [15:0] y;
  wire [4:0]  ALUFlags;
  reg  [15:0] expected_y;
  reg  [4:0]  expected_flags;

  // Variables auxiliares
  integer i, total, correct, incorrect;
  integer fd_inputs, fd_outputs;
  reg [255:0] a_str, b_str, op_str, y_str, flags_str;
  reg [255:0] line_in, line_out;

  // =====================================
  // Instancia del DUT (ALU en 16 bits)
  // =====================================
  alu #( .system(16) ) DUT (
    .a(a),
    .b(b),
    .op(op),
    .y(y),
    .ALUFlags(ALUFlags)
  );

  // =====================================
  // Inicialización
  // =====================================
  initial begin
    correct   = 0;
    incorrect = 0;
    total     = 0;

    // Abrir archivos
    fd_inputs  = $fopen("C:/Users/RODRIGO/alu/gen_random/data/tb_vectors_16.mem", "r");
    fd_outputs = $fopen("C:/Users/RODRIGO/alu/gen_random/output/tb_expected_output16.mem", "r");

    if (fd_inputs == 0 || fd_outputs == 0) begin
      $display("❌ ERROR: No se pudieron abrir los archivos de test.");
      $finish;
    end

    $display("==================================================");
    $display("🔹 INICIO DE TESTBENCH DE ALU FLOAT 16 bits");
    $display("==================================================\n");

    // Leer línea a línea
    while (!$feof(fd_inputs) && !$feof(fd_outputs)) begin
      total = total + 1;

      // Leer una línea del archivo de inputs
      $fscanf(fd_inputs, "%s %s %s\n", a_str, b_str, op_str);
      $fscanf(fd_outputs, "%s %s\n", y_str, flags_str);

      // Convertir cadenas binarias a valores
      a = bin_to_val(a_str);
      b = bin_to_val(b_str);
      expected_y = bin_to_val(y_str);
      expected_flags = bin5_to_val(flags_str);
      op = op_from_str(op_str);

      #10; // Esperar resultado

      if (y === expected_y && ALUFlags === expected_flags) begin
        correct = correct + 1;
      end else begin
        incorrect = incorrect + 1;
        $display("❌ Mismatch en caso %0d:", total);
        $display("   a=%b, b=%b, op=%b", a, b, op);
        $display("   Esperado: y=%b, flags=%b", expected_y, expected_flags);
        $display("   Obtenido: y=%b, flags=%b\n", y, ALUFlags);
      end
    end

    // Cerrar archivos
    $fclose(fd_inputs);
    $fclose(fd_outputs);

    // Mostrar resumen
    $display("\n==================================================");
    $display("🔸 RESULTADOS TOTALES");
    $display("==================================================");
    $display("Casos totales: %0d", total);
    $display("✅ Correctos:   %0d", correct);
    $display("❌ Incorrectos: %0d", incorrect);
    $display("🎯 Precisión:   %.2f %%", (correct * 100.0) / total);
    $display("==================================================\n");

    $finish;
  end

  // =====================================
  // FUNCIONES AUXILIARES
  // =====================================
  function [15:0] bin_to_val(input [255:0] str);
    integer j;
    reg [15:0] val;
    begin
      val = 0;
      for (j = 0; j < 16; j = j + 1) begin
        if (str[j] == "1" || str[255-j] == "1")
          val = {val[14:0], 1'b1};
        else
          val = {val[14:0], 1'b0};
      end
      bin_to_val = val;
    end
  endfunction

  function [4:0] bin5_to_val(input [255:0] str);
    integer j;
    reg [4:0] val;
    begin
      val = 0;
      for (j = 0; j < 5; j = j + 1) begin
        if (str[j] == "1" || str[255-j] == "1")
          val = {val[3:0], 1'b1};
        else
          val = {val[3:0], 1'b0};
      end
      bin5_to_val = val;
    end
  endfunction

  function [1:0] op_from_str(input [255:0] str);
    begin
      if (str == "00")      op_from_str = 2'b00; // suma
      else if (str == "01") op_from_str = 2'b01; // resta
      else if (str == "10") op_from_str = 2'b10; // multiplicación
      else if (str == "11") op_from_str = 2'b11; // división
      else                  op_from_str = 2'b00;
    end
  endfunction

endmodule
