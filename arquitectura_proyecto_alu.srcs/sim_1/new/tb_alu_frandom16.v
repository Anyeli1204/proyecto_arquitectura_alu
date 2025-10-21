`timescale 1ns/1ps

module tb_alu_frandom16;

  // =====================================
  // Señales para la ALU
  // =====================================
  reg  [15:0] a, b;
  reg  [1:0]  op;
  wire [15:0] y;
  wire [4:0]  ALUFlags;
  reg  [15:0] expected_y;
  reg  [4:0]  expected_flags;

  // =====================================
  // Variables para leer cadenas del .mem
  // =====================================
  reg [8*16-1:0] a_str;      // 16 caracteres
  reg [8*16-1:0] b_str;      // 16 caracteres
  reg [8*2-1:0]  op_str;     // 2 caracteres "00", "01", etc.
  reg [8*16-1:0] y_str;      // 16 caracteres
  reg [8*5-1:0]  flags_str;  // 5 caracteres

  integer fd_inputs, fd_outputs;
  integer total, correct, incorrect;

  // =====================================
  // Instancia del DUT (ALU 16 bits)
  // =====================================
  alu #( .system(16) ) DUT (
    .a(a),
    .b(b),
    .op(op),
    .y(y),
    .ALUFlags(ALUFlags)
  );

  // =====================================
  // Testbench principal
  // =====================================
  initial begin
    total = 0;
    correct = 0;
    incorrect = 0;

    // Abrir archivos
    fd_inputs  = $fopen("C:/Users/RODRIGO/alu/arquitectura_proyecto_alu.srcs/gen_random/data/tb_vectors_16.mem", "r");
    fd_outputs = $fopen("C:/Users/RODRIGO/alu/arquitectura_proyecto_alu.srcs/gen_random/output/tb_expected_output16.mem", "r");

    if (fd_inputs == 0 || fd_outputs == 0) begin
      $display("❌ ERROR: No se pudieron abrir los archivos de test.");
      $finish;
    end

    $display("🔹 INICIO DE TESTBENCH DE ALU FLOAT 16 bits\n");

    // Leer línea a línea
    while (!$feof(fd_inputs) && !$feof(fd_outputs)) begin
      total = total + 1;

      // Leer cadena tal cual del archivo
      $fscanf(fd_inputs, "%s %s %s\n", a_str, b_str, op_str);
      $fscanf(fd_outputs, "%s %s\n", y_str, flags_str);

      // Mostrar las cadenas tal cual están en el .mem
      $display("Caso %0d: a_str=%s, b_str=%s, op_str=%s | y_str=%s, flags_str=%s", 
                total, a_str, b_str, op_str, y_str, flags_str);

      // Convertir cadenas binarias a bits para la ALU
      $sscanf(a_str, "%b", a);
      $sscanf(b_str, "%b", b);
      $sscanf(op_str, "%b", op);
      $sscanf(y_str, "%b", expected_y);
      $sscanf(flags_str, "%b", expected_flags);

      #10; // esperar resultado de la ALU

      // Comparar resultado
      if (y === expected_y && ALUFlags === expected_flags) begin
        correct = correct + 1;
      end else begin
        incorrect = incorrect + 1;
        $display("❌ Mismatch en caso %0d:", total);
        $display("   Esperado: y=%b, flags=%b", expected_y, expected_flags);
        $display("   Obtenido: y=%b, flags=%b\n", y, ALUFlags);
      end
    end

    // Cerrar archivos
    $fclose(fd_inputs);
    $fclose(fd_outputs);

    // Resumen
    $display("\n🔸 RESULTADOS TOTALES");
    $display("Casos totales: %0d", total);
    $display("✅ Correctos:   %0d", correct);
    $display("❌ Incorrectos: %0d", incorrect);
    $display("🎯 Precisión:   %.2f %%", (correct * 100.0) / total);

    $finish;
  end

endmodule
