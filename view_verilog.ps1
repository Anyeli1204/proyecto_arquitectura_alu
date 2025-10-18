# Script para visualizar y analizar archivos Verilog
# Útil para entender el código sin necesidad de simulación

param(
    [string]$File = "",
    [string]$Testbench = "",
    [switch]$List,
    [switch]$Help
)

# Colores para output
$Green = "Green"
$Yellow = "Yellow"
$Red = "Red"
$Cyan = "Cyan"
$White = "White"

function Show-Help {
    Write-Host "========================================" -ForegroundColor $Cyan
    Write-Host "Visualizador de Archivos Verilog" -ForegroundColor $Cyan
    Write-Host "========================================" -ForegroundColor $Cyan
    Write-Host ""
    Write-Host "Uso:" -ForegroundColor $Yellow
    Write-Host "  .\view_verilog.ps1 -File <archivo>" -ForegroundColor White
    Write-Host "  .\view_verilog.ps1 -Testbench <nombre>" -ForegroundColor White
    Write-Host "  .\view_verilog.ps1 -List" -ForegroundColor White
    Write-Host "  .\view_verilog.ps1 -Help" -ForegroundColor White
    Write-Host ""
    Write-Host "Ejemplos:" -ForegroundColor $Yellow
    Write-Host "  .\view_verilog.ps1 -File alu.v" -ForegroundColor White
    Write-Host "  .\view_verilog.ps1 -Testbench alu" -ForegroundColor White
    Write-Host "  .\view_verilog.ps1 -List" -ForegroundColor White
    Write-Host ""
}

function Show-File-List {
    Write-Host "========================================" -ForegroundColor $Cyan
    Write-Host "Archivos del Proyecto ALU" -ForegroundColor $Cyan
    Write-Host "========================================" -ForegroundColor $Cyan
    Write-Host ""
    
    # Archivos fuente
    Write-Host "📁 Archivos fuente (módulos):" -ForegroundColor $Green
    $srcDir = "arquitectura_proyecto_alu.srcs\sources_1\new"
    if (Test-Path $srcDir) {
        Get-ChildItem -Path $srcDir -Filter "*.v" | ForEach-Object {
            $size = [math]::Round($_.Length / 1KB, 1)
            Write-Host "  📄 $($_.Name) ($size KB)" -ForegroundColor White
        }
    }
    Write-Host ""
    
    # Testbenches
    Write-Host "🧪 Testbenches (simulaciones):" -ForegroundColor $Green
    $simDir = "arquitectura_proyecto_alu.srcs\sim_1\new"
    if (Test-Path $simDir) {
        Get-ChildItem -Path $simDir -Filter "tb_*.v" | ForEach-Object {
            $size = [math]::Round($_.Length / 1KB, 1)
            $name = $_.BaseName -replace "^tb_", ""
            Write-Host "  🧪 $($_.Name) ($size KB) - $name" -ForegroundColor White
        }
    }
    Write-Host ""
}

function Show-File-Content {
    param([string]$FilePath, [string]$Title)
    
    if (-not (Test-Path $FilePath)) {
        Write-Host "Error: No se encontró el archivo $FilePath" -ForegroundColor $Red
        return
    }
    
    Write-Host "========================================" -ForegroundColor $Cyan
    Write-Host $Title -ForegroundColor $Cyan
    Write-Host "========================================" -ForegroundColor $Cyan
    Write-Host "Archivo: $FilePath" -ForegroundColor $Yellow
    Write-Host ""
    
    $content = Get-Content -Path $FilePath -Raw
    $lines = $content -split "`n"
    
    # Mostrar información básica
    $lineCount = $lines.Count
    $charCount = $content.Length
    Write-Host "📊 Estadísticas:" -ForegroundColor $Green
    Write-Host "  Líneas: $lineCount" -ForegroundColor White
    Write-Host "  Caracteres: $charCount" -ForegroundColor White
    Write-Host ""
    
    # Buscar módulos
    $modules = $lines | Where-Object { $_ -match "^\s*module\s+(\w+)" } | ForEach-Object {
        if ($_ -match "module\s+(\w+)") { $matches[1] }
    }
    
    if ($modules.Count -gt 0) {
        Write-Host "🔧 Módulos encontrados:" -ForegroundColor $Green
        foreach ($module in $modules) {
            Write-Host "  - $module" -ForegroundColor White
        }
        Write-Host ""
    }
    
    # Buscar puertos de entrada y salida
    $inputs = $lines | Where-Object { $_ -match "^\s*input\s+" } | ForEach-Object { $_.Trim() }
    $outputs = $lines | Where-Object { $_ -match "^\s*output\s+" } | ForEach-Object { $_.Trim() }
    
    if ($inputs.Count -gt 0) {
        Write-Host "📥 Entradas:" -ForegroundColor $Green
        foreach ($input in $inputs) {
            Write-Host "  $input" -ForegroundColor White
        }
        Write-Host ""
    }
    
    if ($outputs.Count -gt 0) {
        Write-Host "📤 Salidas:" -ForegroundColor $Green
        foreach ($output in $outputs) {
            Write-Host "  $output" -ForegroundColor White
        }
        Write-Host ""
    }
    
    # Mostrar las primeras 20 líneas del código
    Write-Host "📝 Código (primeras 20 líneas):" -ForegroundColor $Green
    Write-Host "----------------------------------------" -ForegroundColor $Yellow
    for ($i = 0; $i -lt [Math]::Min(20, $lines.Count); $i++) {
        $lineNum = $i + 1
        Write-Host "$lineNum.ToString().PadLeft(3): $($lines[$i])" -ForegroundColor White
    }
    
    if ($lines.Count -gt 20) {
        Write-Host "..." -ForegroundColor $Yellow
        Write-Host "($($lines.Count - 20) líneas más)" -ForegroundColor $Yellow
    }
    Write-Host ""
}

function Analyze-Testbench {
    param([string]$TestbenchName)
    
    $testbenchFile = "arquitectura_proyecto_alu.srcs\sim_1\new\tb_$TestbenchName.v"
    
    if (-not (Test-Path $testbenchFile)) {
        Write-Host "Error: No se encontró el testbench tb_$TestbenchName.v" -ForegroundColor $Red
        Show-File-List
        return
    }
    
    Show-File-Content -FilePath $testbenchFile -Title "Análisis del Testbench: $TestbenchName"
    
    # Análisis específico del testbench
    $content = Get-Content -Path $testbenchFile -Raw
    $lines = $content -split "`n"
    
    # Buscar casos de prueba
    $testCases = $lines | Where-Object { $_ -match "op\s*=\s*2'b\d+" }
    
    if ($testCases.Count -gt 0) {
        Write-Host "🧪 Casos de prueba encontrados:" -ForegroundColor $Green
        foreach ($testCase in $testCases) {
            $cleanLine = $testCase.Trim()
            Write-Host "  $cleanLine" -ForegroundColor White
        }
        Write-Host ""
    }
    
    # Buscar valores de entrada
    $inputs = $lines | Where-Object { $_ -match "a\s*=\s*16'h[0-9A-Fa-f]+" }
    if ($inputs.Count -gt 0) {
        Write-Host "📊 Valores de entrada 'a':" -ForegroundColor $Green
        foreach ($input in $inputs) {
            $cleanLine = $input.Trim()
            Write-Host "  $cleanLine" -ForegroundColor White
        }
        Write-Host ""
    }
}

# Procesar parámetros
if ($Help) {
    Show-Help
    exit 0
}

if ($List) {
    Show-File-List
    exit 0
}

if ($File -ne "") {
    $filePath = "arquitectura_proyecto_alu.srcs\sources_1\new\$File"
    Show-File-Content -FilePath $filePath -Title "Análisis del archivo: $File"
    exit 0
}

if ($Testbench -ne "") {
    Analyze-Testbench -TestbenchName $Testbench
    exit 0
}

# Si no se especificó nada, mostrar la lista
Show-File-List
Write-Host "Para ver el contenido de un archivo específico:" -ForegroundColor $Yellow
Write-Host "  .\view_verilog.ps1 -File alu.v" -ForegroundColor White
Write-Host "  .\view_verilog.ps1 -Testbench alu" -ForegroundColor White
