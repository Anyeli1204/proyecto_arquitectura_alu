# Makefile para proyecto de ALU en Verilog
# Configurado para usar Icarus Verilog

# Directorios
SRC_DIR = arquitectura_proyecto_alu.srcs/sources_1/new
SIM_DIR = arquitectura_proyecto_alu.srcs/sim_1/new
BUILD_DIR = build

# Archivos fuente
SOURCES = $(SRC_DIR)/alu.v \
          $(SRC_DIR)/SumaResta.v \
          $(SRC_DIR)/Multiplicacion.v \
          $(SRC_DIR)/Division.v \
          $(SRC_DIR)/RoundNearestEven.v

# Testbenches disponibles
TESTBENCHES = tb_alu tb_alu_bin tb_flags tb_redondeo tb_redondeo_extras \
              tb_Suma16Bits_flags_bin tb_SumaResta tb_SumaRestaFlags

# Compilador y flags
IVERILOG = iverilog
VVP = vvp
IVERILOG_FLAGS = -g2012 -Wall -Wno-timescale

# Crear directorio de build si no existe
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Regla por defecto
all: help

# Ayuda
help:
	@echo "Comandos disponibles:"
	@echo "  make compile-<testbench>  - Compilar un testbench específico"
	@echo "  make run-<testbench>      - Compilar y ejecutar un testbench"
	@echo "  make clean                - Limpiar archivos generados"
	@echo "  make list-tb              - Listar testbenches disponibles"
	@echo ""
	@echo "Testbenches disponibles:"
	@for tb in $(TESTBENCHES); do echo "  - $$tb"; done

# Listar testbenches
list-tb:
	@echo "Testbenches disponibles:"
	@for tb in $(TESTBENCHES); do echo "  - $$tb"; done

# Compilar testbench específico
compile-%: $(BUILD_DIR)
	@TB_NAME=$*; \
	if [ -f "$(SIM_DIR)/tb_$$TB_NAME.v" ]; then \
		echo "Compilando testbench: $$TB_NAME"; \
		$(IVERILOG) $(IVERILOG_FLAGS) -o $(BUILD_DIR)/$$TB_NAME.vvp \
			$(SOURCES) $(SIM_DIR)/tb_$$TB_NAME.v; \
		echo "Compilación completada: $(BUILD_DIR)/$$TB_NAME.vvp"; \
	else \
		echo "Error: No se encontró el testbench tb_$$TB_NAME.v"; \
		echo "Testbenches disponibles:"; \
		ls $(SIM_DIR)/tb_*.v | sed 's/.*\///g' | sed 's/tb_//g' | sed 's/\.v//g' | sed 's/^/  - /g'; \
	fi

# Ejecutar testbench específico
run-%: compile-%
	@TB_NAME=$*; \
	echo "Ejecutando testbench: $$TB_NAME"; \
	$(VVP) $(BUILD_DIR)/$$TB_NAME.vvp

# Compilar y ejecutar todos los testbenches
test-all: $(BUILD_DIR)
	@echo "Ejecutando todos los testbenches..."
	@for tb in $(TESTBENCHES); do \
		if [ -f "$(SIM_DIR)/tb_$$tb.v" ]; then \
			echo ""; \
			echo "=== Ejecutando $$tb ==="; \
			$(IVERILOG) $(IVERILOG_FLAGS) -o $(BUILD_DIR)/$$tb.vvp \
				$(SOURCES) $(SIM_DIR)/tb_$$tb.v && \
			$(VVP) $(BUILD_DIR)/$$tb.vvp; \
		fi; \
	done

# Limpiar archivos generados
clean:
	@echo "Limpiando archivos generados..."
	rm -rf $(BUILD_DIR)
	@echo "Limpieza completada"

# Verificar que Icarus Verilog esté instalado
check-iverilog:
	@if command -v iverilog >/dev/null 2>&1; then \
		echo "Icarus Verilog encontrado: $$(iverilog -V 2>&1 | head -1)"; \
	else \
		echo "Error: Icarus Verilog no está instalado"; \
		echo "Instala Icarus Verilog desde: http://iverilog.icarus.com/"; \
		exit 1; \
	fi

.PHONY: all help list-tb compile-% run-% test-all clean check-iverilog
