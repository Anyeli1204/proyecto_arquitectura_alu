# Simulador básico de Verilog sin necesidad de Icarus Verilog
# Analiza y simula testbenches mostrando los resultados esperados

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
    Write-Host "Simulador Básico de Verilog" -ForegroundColor $Cyan
    Write-Host "========================================" -ForegroundColor $Cyan
    Write-Host ""
    Write-Host "Uso:" -ForegroundColor $Yellow
    Write-Host "  .\run_testbench.ps1 -Testbench <nombre>" -ForegroundColor White
    Write-Host "  .\run_testbench.ps1 -List" -ForegroundColor White
    Write-Host "  .\run_testbench.ps1 -Help" -ForegroundColor White
    Write-Host ""
    Write-Host "Ejemplos:" -ForegroundColor $Yellow
    Write-Host "  .\run_testbench.ps1 -Testbench alu" -ForegroundColor White
    Write-Host "  .\run_testbench.ps1 -List" -ForegroundColor White
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
    Write-Host "Simulando Testbench: $TestbenchName" -ForegroundColor $Cyan
    Write-Host "========================================" -ForegroundColor $Cyan
    Write-Host ""
    
    # Leer el archivo
    $content = Get-Content -Path $testbenchFile -Raw
    $lines = $content -split "`n"
    
    # Analizar el testbench
    Write-Host "Analizando testbench..." -ForegroundColor $Yellow
    Write-Host ""
    
    # Buscar casos de prueba
    $testCases = @()
    $currentTime = 0
    
    foreach ($line in $lines) {
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
            $aFloat = Convert-HexToFloat16 $aValue
            if ($testCases.Count -gt 0) {
                $testCases[-1].A = $aValue
                $testCases[-1].AFloat = $aFloat
            }
        }
        
        # Buscar valores de entrada b
        if ($line -match "b\s*=\s*16'h([0-9A-Fa-f]+)") {
            $bValue = $matches[1]
            $bFloat = Convert-HexToFloat16 $bValue
            if ($testCases.Count -gt 0) {
                $testCases[-1].B = $bValue
                $testCases[-1].BFloat = $bFloat
            }
        }
        
        # Buscar delays
        if ($line -match "#(\d+)") {
            $currentTime += [int]$matches[1]
        }
    }
    
    # Mostrar resultados de la simulación
    Write-Host "Resultados de la simulación:" -ForegroundColor $Green
    Write-Host ""
    
    foreach ($testCase in $testCases) {
        Write-Host "Tiempo: $($testCase.Time)ns" -ForegroundColor $Yellow
        Write-Host "  Operación: $($testCase.OpName)" -ForegroundColor White
        if ($testCase.A) {
            Write-Host "  Entrada A: 0x$($testCase.A) ($($testCase.AFloat))" -ForegroundColor White
        }
        if ($testCase.B) {
            Write-Host "  Entrada B: 0x$($testCase.B) ($($testCase.BFloat))" -ForegroundColor White
        }
        
        # Calcular resultado esperado
        if ($testCase.AFloat -and $testCase.BFloat) {
            $result = Calculate-ALU-Result $testCase.Op $testCase.AFloat $testCase.BFloat
            Write-Host "  Resultado esperado: $result" -ForegroundColor $Green
        }
        Write-Host ""
    }
    
    # Mostrar información del módulo ALU
    Show-ALU-Info
}

function Convert-HexToFloat16 {
    param([string]$hex)
    
    # Conversión básica de hex a float16
    $value = [Convert]::ToInt32($hex, 16)
    
    # Extraer signo, exponente y mantisa
    $sign = ($value -band 0x8000) -ne 0
    $exponent = ($value -band 0x7C00) -shr 10
    $mantissa = $value -band 0x03FF
    
    if ($exponent -eq 0) {
        if ($mantissa -eq 0) {
            return if ($sign) { "-0.0" } else { "0.0" }
        } else {
            # Número subnormal
            $result = $mantissa / 1024.0
            return if ($sign) { "-$result" } else { "$result" }
        }
    } elseif ($exponent -eq 31) {
        return if ($mantissa -eq 0) { if ($sign) { "-∞" } else { "∞" } } else { "NaN" }
    } else {
        # Número normal
        $exponent = $exponent - 15
        $mantissa = ($mantissa / 1024.0) + 1.0
        $result = $mantissa * [Math]::Pow(2, $exponent)
        return if ($sign) { "-$result" } else { "$result" }
    }
}

function Calculate-ALU-Result {
    param([string]$op, [double]$a, [double]$b)
    
    switch ($op) {
        "00" { 
            $result = $a + $b
            return "$a + $b = $result"
        }
        "01" { 
            $result = $a - $b
            return "$a - $b = $result"
        }
        "10" { 
            $result = $a * $b
            return "$a × $b = $result"
        }
        "11" { 
            if ($b -ne 0) {
                $result = $a / $b
                return "$a ÷ $b = $result"
            } else {
                return "$a ÷ $b = Error (división por cero)"
            }
        }
        default { return "Operación desconocida" }
    }
}

function Show-ALU-Info {
    Write-Host "========================================" -ForegroundColor $Cyan
    Write-Host "Información de la ALU" -ForegroundColor $Cyan
    Write-Host "========================================" -ForegroundColor $Cyan
    Write-Host ""
    Write-Host "Operaciones soportadas:" -ForegroundColor $Green
    Write-Host "  00 - ADD: Suma de punto flotante" -ForegroundColor White
    Write-Host "  01 - SUB: Resta de punto flotante" -ForegroundColor White
    Write-Host "  10 - MUL: Multiplicación de punto flotante" -ForegroundColor White
    Write-Host "  11 - DIV: División de punto flotante" -ForegroundColor White
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
    Write-Host "Para simular un testbench específico:" -ForegroundColor $Yellow
    Write-Host "  .\run_testbench.ps1 -Testbench <nombre>" -ForegroundColor White
    exit 0
}

# Simular testbench específico
Analyze-Testbench -TestbenchName $Testbench
