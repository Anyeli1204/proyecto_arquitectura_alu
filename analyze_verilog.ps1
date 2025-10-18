# Analizador de Verilog que funciona sin Icarus Verilog
# Analiza y simula testbenches mostrando resultados esperados

param(
    [string]$Testbench = "",
    [switch]$List,
    [switch]$Help
)

# Colores
$Green = "Green"
$Yellow = "Yellow"
$Red = "Red"
$Cyan = "Cyan"
$White = "White"

function Show-Help {
    Write-Host "========================================" -ForegroundColor $Cyan
    Write-Host "Analizador de Verilog" -ForegroundColor $Cyan
    Write-Host "========================================" -ForegroundColor $Cyan
    Write-Host ""
    Write-Host "Uso:" -ForegroundColor $Yellow
    Write-Host "  .\analyze_verilog.ps1 -Testbench <nombre>" -ForegroundColor White
    Write-Host "  .\analyze_verilog.ps1 -List" -ForegroundColor White
    Write-Host "  .\analyze_verilog.ps1 -Help" -ForegroundColor White
    Write-Host ""
    Write-Host "Ejemplos:" -ForegroundColor $Yellow
    Write-Host "  .\analyze_verilog.ps1 -Testbench alu" -ForegroundColor White
    Write-Host "  .\analyze_verilog.ps1 -List" -ForegroundColor White
    Write-Host ""
}

function Show-Testbenches {
    Write-Host "========================================" -ForegroundColor $Cyan
    Write-Host "Testbenches Disponibles" -ForegroundColor $Cyan
    Write-Host "========================================" -ForegroundColor $Cyan
    Write-Host ""
    
    $simDir = "arquitectura_proyecto_alu.srcs\sim_1\new"
    if (Test-Path $simDir) {
        $testbenches = Get-ChildItem -Path $simDir -Filter "tb_*.v"
        foreach ($tb in $testbenches) {
            $name = $tb.BaseName -replace "^tb_", ""
            $size = [math]::Round($tb.Length / 1KB, 1)
            Write-Host "  - $name ($($tb.Name), $size KB)" -ForegroundColor White
        }
    } else {
        Write-Host "  No se encontró el directorio de testbenches" -ForegroundColor $Red
    }
    Write-Host ""
}

function Analyze-Testbench {
    param([string]$TestbenchName)
    
    $testbenchFile = "arquitectura_proyecto_alu.srcs\sim_1\new\tb_$TestbenchName.v"
    
    if (-not (Test-Path $testbenchFile)) {
        Write-Host "Error: No se encontró el testbench tb_$TestbenchName.v" -ForegroundColor $Red
        Show-Testbenches
        return
    }
    
    Write-Host "========================================" -ForegroundColor $Cyan
    Write-Host "Analizando Testbench: $TestbenchName" -ForegroundColor $Cyan
    Write-Host "========================================" -ForegroundColor $Cyan
    Write-Host ""
    
    # Leer el archivo
    $content = Get-Content -Path $testbenchFile -Raw
    $lines = $content -split "`n"
    
    Write-Host "Contenido del testbench:" -ForegroundColor $Green
    Write-Host "----------------------------------------" -ForegroundColor $Yellow
    
    # Mostrar el contenido del testbench
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $lineNum = $i + 1
        $line = $lines[$i]
        
        # Resaltar líneas importantes
        if ($line -match "op\s*=\s*2'b\d+") {
            Write-Host "$lineNum.ToString().PadLeft(3): $line" -ForegroundColor $Green
        } elseif ($line -match "a\s*=\s*16'h[0-9A-Fa-f]+") {
            Write-Host "$lineNum.ToString().PadLeft(3): $line" -ForegroundColor $Yellow
        } elseif ($line -match "b\s*=\s*16'h[0-9A-Fa-f]+") {
            Write-Host "$lineNum.ToString().PadLeft(3): $line" -ForegroundColor $Yellow
        } elseif ($line -match "show\(") {
            Write-Host "$lineNum.ToString().PadLeft(3): $line" -ForegroundColor $Cyan
        } else {
            Write-Host "$lineNum.ToString().PadLeft(3): $line" -ForegroundColor $White
        }
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor $Cyan
    Write-Host "Análisis de Casos de Prueba" -ForegroundColor $Cyan
    Write-Host "========================================" -ForegroundColor $Cyan
    Write-Host ""
    
    # Analizar casos de prueba
    $testCases = @()
    $currentTime = 0
    
    foreach ($line in $lines) {
        # Buscar delays
        if ($line -match "#(\d+)") {
            $currentTime += [int]$matches[1]
        }
        
        # Buscar asignaciones de operación
        if ($line -match "op\s*=\s*2'b(\d+)") {
            $op = $matches[1]
            $opName = switch ($op) {
                "00" { "ADD (Suma)" }
                "01" { "SUB (Resta)" }
                "10" { "MUL (Multiplicación)" }
                "11" { "DIV (División)" }
                default { "Operación desconocida" }
            }
            $testCases += @{
                Time = $currentTime
                Op = $op
                OpName = $opName
                Line = $line.Trim()
            }
        }
        
        # Buscar valores de entrada a
        if ($line -match "a\s*=\s*16'h([0-9A-Fa-f]+)") {
            $aValue = $matches[1]
            if ($testCases.Count -gt 0) {
                $testCases[-1].A = $aValue
            }
        }
        
        # Buscar valores de entrada b
        if ($line -match "b\s*=\s*16'h([0-9A-Fa-f]+)") {
            $bValue = $matches[1]
            if ($testCases.Count -gt 0) {
                $testCases[-1].B = $bValue
            }
        }
    }
    
    # Mostrar resumen de casos de prueba
    Write-Host "Casos de prueba encontrados:" -ForegroundColor $Green
    Write-Host ""
    
    foreach ($testCase in $testCases) {
        Write-Host "Tiempo: $($testCase.Time)ns" -ForegroundColor $Yellow
        Write-Host "  Operación: $($testCase.OpName)" -ForegroundColor White
        if ($testCase.A) {
            Write-Host "  Entrada A: 0x$($testCase.A)" -ForegroundColor White
        }
        if ($testCase.B) {
            Write-Host "  Entrada B: 0x$($testCase.B)" -ForegroundColor White
        }
        Write-Host ""
    }
    
    # Mostrar información de la ALU
    Show-ALU-Info
}

function Show-ALU-Info {
    Write-Host "========================================" -ForegroundColor $Cyan
    Write-Host "Información de la ALU" -ForegroundColor $Cyan
    Write-Host "========================================" -ForegroundColor $Cyan
    Write-Host ""
    
    # Leer el archivo de la ALU
    $aluFile = "arquitectura_proyecto_alu.srcs\sources_1\new\alu.v"
    if (Test-Path $aluFile) {
        $aluContent = Get-Content -Path $aluFile -Raw
        $aluLines = $aluContent -split "`n"
        
        Write-Host "Estructura de la ALU:" -ForegroundColor $Green
        Write-Host ""
        
        # Buscar puertos
        foreach ($line in $aluLines) {
            if ($line -match "input\s+\[(\d+):(\d+)\]\s+(\w+)") {
                $width = [int]$matches[1] + 1
                $name = $matches[3]
                Write-Host "  Entrada: $name ($width bits)" -ForegroundColor White
            } elseif ($line -match "output\s+reg\s+\[(\d+):(\d+)\]\s+(\w+)") {
                $width = [int]$matches[1] + 1
                $name = $matches[3]
                Write-Host "  Salida: $name ($width bits)" -ForegroundColor White
            }
        }
        
        Write-Host ""
        Write-Host "Operaciones implementadas:" -ForegroundColor $Green
        
        # Buscar casos de operación
        foreach ($line in $aluLines) {
            if ($line -match "2'b(\d+):\s*begin\s*//\s*(.+)") {
                $op = $matches[1]
                $opName = $matches[2]
                Write-Host "  $op - $opName" -ForegroundColor White
            }
        }
        
        Write-Host ""
        Write-Host "Módulos utilizados:" -ForegroundColor $Green
        
        # Buscar instanciaciones de módulos
        foreach ($line in $aluLines) {
            if ($line -match "(\w+)\s+U_\w+\(") {
                $module = $matches[1]
                Write-Host "  - $module" -ForegroundColor White
            }
        }
    }
    
    Write-Host ""
    Write-Host "Flags de la ALU:" -ForegroundColor $Green
    Write-Host "  N (Negative): Resultado negativo" -ForegroundColor White
    Write-Host "  Z (Zero): Resultado cero" -ForegroundColor White
    Write-Host "  C (Carry/Inexact): Operación inexacta" -ForegroundColor White
    Write-Host "  V (Overflow): Desbordamiento" -ForegroundColor White
    Write-Host ""
}

# Procesar parámetros
if ($Help) {
    Show-Help
    exit 0
}

if ($List) {
    Show-Testbenches
    exit 0
}

if ($Testbench -eq "") {
    Show-Testbenches
    Write-Host "Para analizar un testbench específico:" -ForegroundColor $Yellow
    Write-Host "  .\analyze_verilog.ps1 -Testbench <nombre>" -ForegroundColor White
    exit 0
}

# Analizar testbench específico
Analyze-Testbench -TestbenchName $Testbench
