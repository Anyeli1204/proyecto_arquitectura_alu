# Proyecto ALU en Verilog - Configuración para Cursor

Este proyecto contiene una ALU (Unidad Aritmético-Lógica) implementada en Verilog con soporte para operaciones de punto flotante de 16 bits.

## 📁 Estructura del Proyecto

```
arquitectura_proyecto_alu/
├── arquitectura_proyecto_alu.srcs/
│   ├── sources_1/new/          # Módulos fuente
│   │   ├── alu.v              # Módulo principal de la ALU
│   │   ├── SumaResta.v        # Módulo de suma/resta
│   │   ├── Multiplicacion.v   # Módulo de multiplicación
│   │   ├── Division.v         # Módulo de división
│   │   └── RoundNearestEven.v # Módulo de redondeo
│   └── sim_1/new/             # Testbenches
│       ├── tb_alu.v           # Testbench principal de ALU
│       ├── tb_alu_bin.v       # Testbench ALU binario
│       ├── tb_flags.v         # Testbench de flags
│       └── ...                # Otros testbenches
├── Makefile                   # Script de compilación y simulación
├── install_iverilog.bat       # Instalador de Icarus Verilog (Windows)
├── install_iverilog.ps1       # Instalador de Icarus Verilog (PowerShell)
└── .vscode/                   # Configuración de Cursor/VS Code
    ├── settings.json          # Configuración del editor
    └── tasks.json             # Tareas de compilación
```

## 🚀 Instalación y Configuración

### 1. Instalar Icarus Verilog

#### Opción A: Instalación Automática (Windows)

```bash
# Ejecutar como administrador
.\install_iverilog.ps1
```

#### Opción B: Instalación Manual

1. Descargar Icarus Verilog desde: https://github.com/steveicarus/iverilog/releases
2. Instalar y asegurarse de agregar al PATH del sistema
3. Verificar instalación:

```bash
iverilog -V
```

### 2. Verificar Instalación

```bash
make check-iverilog
```

## 🛠️ Uso del Proyecto

### Comandos Básicos

```bash
# Ver ayuda
make help

# Listar testbenches disponibles
make list-tb

# Compilar un testbench específico
make compile-alu

# Ejecutar un testbench específico
make run-alu

# Ejecutar todos los testbenches
make test-all

# Limpiar archivos generados
make clean
```

### Testbenches Disponibles

- `tb_alu` - Testbench principal de la ALU
- `tb_alu_bin` - Testbench ALU con operaciones binarias
- `tb_flags` - Testbench de flags de la ALU
- `tb_redondeo` - Testbench de redondeo
- `tb_redondeo_extras` - Testbench de redondeo extendido
- `tb_Suma16Bits_flags_bin` - Testbench de suma de 16 bits
- `tb_SumaResta` - Testbench de suma/resta
- `tb_SumaRestaFlags` - Testbench de suma/resta con flags

### Uso en Cursor/VS Code

1. **Usar las tareas integradas:**

   - `Ctrl+Shift+P` → "Tasks: Run Task"
   - Seleccionar la tarea deseada

2. **Compilar y ejecutar desde terminal:**
   ```bash
   # Terminal integrado (Ctrl+`)
   make run-alu
   ```

## 🔧 Configuración del Editor

El proyecto incluye configuración para:

- **Syntax highlighting** para Verilog
- **Linting** con Icarus Verilog
- **Formatting** automático
- **Tareas** predefinidas para compilación y simulación

## 📊 Operaciones Soportadas

La ALU soporta las siguientes operaciones:

| Código | Operación | Descripción                      |
| ------ | --------- | -------------------------------- |
| `00`   | ADD       | Suma de punto flotante           |
| `01`   | SUB       | Resta de punto flotante          |
| `10`   | MUL       | Multiplicación de punto flotante |
| `11`   | DIV       | División de punto flotante       |

### Flags de la ALU

- **N (Negative)**: Resultado negativo
- **Z (Zero)**: Resultado cero
- **C (Carry/Inexact)**: Operación inexacta
- **V (Overflow)**: Desbordamiento

## 🐛 Solución de Problemas

### Error: "iverilog no se reconoce como comando"

- Verificar que Icarus Verilog esté instalado
- Verificar que esté en el PATH del sistema
- Reiniciar la terminal/editor

### Error de compilación

- Verificar que todos los archivos fuente estén presentes
- Revisar la sintaxis de Verilog
- Usar `make clean` antes de recompilar

### Problemas de simulación

- Verificar que el testbench esté correctamente escrito
- Revisar los tiempos de simulación (`#` delays)
- Usar `$display` para debug

## 📚 Recursos Adicionales

- [Documentación de Icarus Verilog](http://iverilog.icarus.com/)
- [Tutorial de Verilog](https://www.verilog.com/)
- [IEEE 754 Standard](https://ieeexplore.ieee.org/document/8766229) (Punto flotante)

## 🤝 Contribuir

Para contribuir al proyecto:

1. Fork el repositorio
2. Crear una rama para tu feature
3. Hacer commit de los cambios
4. Crear un Pull Request

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Ver el archivo LICENSE para más detalles.
