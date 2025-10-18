# Script para simular archivos Verilog en Windows
# Funciona con Icarus Verilog o como alternativa, muestra la estructura del proyecto

param(
    [string]$Testbench = "",
    [switch]$List,
    [switch]$Help
)

# Colores para output
$Green = "Green"
$Yellow = "Yellow"
$Red = "Red"
$Cyan = "Cyan"

function Show-Help {
    Write-Host "========================================" -ForegroundColor $Cyan
    Write-Host "Simulador de Verilog para Windows" -ForegroundColor $Cyan
    Write-Host "========================================" -ForegroundColor $Cyan
    Write-Host ""
    Write-Host "Uso:" -ForegroundColor $Yellow
    Write-Host "  .\simulate_verilog.ps1 -Testbench <nombre>" -ForegroundColor White
    Write-Host "  .\simulate_verilog.ps1 -List" -ForegroundColor White
    Write-Host "  .\simulate_verilog.ps1 -Help" -ForegroundColor White
    Write-Host ""
    Write-Host "Ejemplos:" -ForegroundColor $Yellow
    Write-Host "  .\simulate_verilog.ps1 -Testbench alu" -ForegroundColor White
    Write-Host "  .\simulate_verilog.ps1 -List" -ForegroundColor White
    Write-Host ""
}

function Show-Testbenches {
    Write-Host "Testbenches disponibles:" -ForegroundColor $Green
    Write-Host ""
    
    $simDir = "arquitectura_proyecto_alu.srcs\sim_1\new"
    if (Test-Path $simDir) {
        $testbenches = Get-ChildItem -Path $simDir -Filter "tb_*.v" | ForEach-Object { $_.BaseName }
        foreach ($tb in $testbenches) {
            $name = $tb -replace "^tb_", ""
            Write-Host "  - $name" -ForegroundColor White
        }
    } else {
        Write-Host "  No se encontró el directorio de testbenches" -ForegroundColor $Red
    }
    Write-Host ""
}

function Check-Iverilog {
    try {
        $version = & iverilog -V 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Icarus Verilog encontrado:" -ForegroundColor $Green
            Write-Host $version -ForegroundColor $Yellow
            return $true
        }
    } catch {
        Write-Host "Icarus Verilog no está instalado" -ForegroundColor $Red
        Write-Host ""
        Write-Host "Para instalar Icarus Verilog:" -ForegroundColor $Yellow
        Write-Host "1. Ve a: https://github.com/steveicarus/iverilog/releases" -ForegroundColor White
        Write-Host "2. Descarga la versión más reciente para Windows" -ForegroundColor White
        Write-Host "3. Ejecuta el instalador y asegúrate de agregar al PATH" -ForegroundColor White
        Write-Host ""
        return $false
    }
    return $false
}

function Simulate-Testbench {
    param([string]$TestbenchName)
    
    Write-Host "Simulando testbench: $TestbenchName" -ForegroundColor $Green
    Write-Host ""
    
    # Verificar que Icarus Verilog esté instalado
    if (-not (Check-Iverilog)) {
        Write-Host "No se puede simular sin Icarus Verilog" -ForegroundColor $Red
        return
    }
    
    # Crear directorio de build si no existe
    if (-not (Test-Path "build")) {
        New-Item -ItemType Directory -Path "build" | Out-Null
    }
    
    # Archivos fuente
    $sources = @(
        "arquitectura_proyecto_alu.srcs\sources_1\new\alu.v",
        "arquitectura_proyecto_alu.srcs\sources_1\new\SumaResta.v",
        "arquitectura_proyecto_alu.srcs\sources_1\new\Multiplicacion.v",
        "arquitectura_proyecto_alu.srcs\sources_1\new\Division.v",
        "arquitectura_proyecto_alu.srcs\sources_1\new\RoundNearestEven.v"
    )
    
    # Testbench
    $testbenchFile = "arquitectura_proyecto_alu.srcs\sim_1\new\tb_$TestbenchName.v"
    
    if (-not (Test-Path $testbenchFile)) {
        Write-Host "Error: No se encontró el testbench tb_$TestbenchName.v" -ForegroundColor $Red
        Show-Testbenches
        return
    }
    
    # Verificar que todos los archivos fuente existan
    $missingFiles = @()
    foreach ($source in $sources) {
        if (-not (Test-Path $source)) {
            $missingFiles += $source
        }
    }
    
    if ($missingFiles.Count -gt 0) {
        Write-Host "Archivos fuente faltantes:" -ForegroundColor $Red
        foreach ($file in $missingFiles) {
            Write-Host "  - $file" -ForegroundColor $Red
        }
        return
    }
    
    # Compilar
    Write-Host "Compilando..." -ForegroundColor $Yellow
    $outputFile = "build\$TestbenchName.vvp"
    
    $compileArgs = @("-g2012", "-Wall", "-o", $outputFile) + $sources + $testbenchFile
    
    try {
        & iverilog $compileArgs
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Compilación exitosa!" -ForegroundColor $Green
            Write-Host ""
            
            # Ejecutar simulación
            Write-Host "Ejecutando simulación..." -ForegroundColor $Yellow
            & vvp $outputFile
        } else {
            Write-Host "Error en la compilación" -ForegroundColor $Red
        }
    } catch {
        Write-Host "Error ejecutando iverilog: $($_.Exception.Message)" -ForegroundColor $Red
    }
}

function Show-Project-Info {
    Write-Host "========================================" -ForegroundColor $Cyan
    Write-Host "Información del Proyecto ALU" -ForegroundColor $Cyan
    Write-Host "========================================" -ForegroundColor $Cyan
    Write-Host ""
    
    # Mostrar archivos fuente
    Write-Host "Archivos fuente:" -ForegroundColor $Green
    $srcDir = "arquitectura_proyecto_alu.srcs\sources_1\new"
    if (Test-Path $srcDir) {
        Get-ChildItem -Path $srcDir -Filter "*.v" | ForEach-Object {
            Write-Host "  - $($_.Name)" -ForegroundColor White
        }
    }
    Write-Host ""
    
    # Mostrar testbenches
    Show-Testbenches
    
    # Mostrar operaciones de la ALU
    Write-Host "Operaciones de la ALU:" -ForegroundColor $Green
    Write-Host "  00 - ADD (Suma)" -ForegroundColor White
    Write-Host "  01 - SUB (Resta)" -ForegroundColor White
    Write-Host "  10 - MUL (Multiplicación)" -ForegroundColor White
    Write-Host "  11 - DIV (División)" -ForegroundColor White
    Write-Host ""
}

# Procesar parámetros
if ($Help) {
    Show-Help
    exit 0
}

if ($List) {
    Show-Project-Info
    exit 0
}

if ($Testbench -eq "") {
    Show-Project-Info
    Write-Host "Para simular un testbench específico, usa:" -ForegroundColor $Yellow
    Write-Host "  .\simulate_verilog.ps1 -Testbench <nombre>" -ForegroundColor White
    exit 0
}

# Simular testbench específico
Simulate-Testbench -TestbenchName $Testbench
