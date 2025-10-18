# Script para verificar si Icarus Verilog está instalado
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Verificando Icarus Verilog" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

try {
    $version = & iverilog -V 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "¡Icarus Verilog está instalado!" -ForegroundColor Green
        Write-Host $version -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Ahora puedes ejecutar testbenches:" -ForegroundColor Green
        Write-Host "  .\simulate_verilog.ps1 -Testbench alu" -ForegroundColor White
        Write-Host ""
        
        # Probar compilación
        Write-Host "Probando compilación..." -ForegroundColor Yellow
        $testFile = "arquitectura_proyecto_alu.srcs\sim_1\new\tb_alu.v"
        if (Test-Path $testFile) {
            Write-Host "Compilando testbench alu..." -ForegroundColor Yellow
            & iverilog -g2012 -Wall -o test_alu.vvp "arquitectura_proyecto_alu.srcs\sources_1\new\alu.v" $testFile
            if ($LASTEXITCODE -eq 0) {
                Write-Host "¡Compilación exitosa!" -ForegroundColor Green
                Write-Host "Ejecutando simulación..." -ForegroundColor Yellow
                & vvp test_alu.vvp
                Remove-Item test_alu.vvp -ErrorAction SilentlyContinue
            }
            else {
                Write-Host "Error en la compilación" -ForegroundColor Red
            }
        }
    }
    else {
        Write-Host "Icarus Verilog no está instalado correctamente" -ForegroundColor Red
    }
}
catch {
    Write-Host "Icarus Verilog no está instalado" -ForegroundColor Red
    Write-Host ""
    Write-Host "Para instalar:" -ForegroundColor Yellow
    Write-Host "1. Ve a: https://github.com/steveicarus/iverilog/releases" -ForegroundColor White
    Write-Host "2. Descarga iverilog-12.0-x64.exe" -ForegroundColor White
    Write-Host "3. Ejecuta el instalador" -ForegroundColor White
    Write-Host "4. Marca 'Add to PATH'" -ForegroundColor White
    Write-Host "5. Reinicia la terminal" -ForegroundColor White
}

Write-Host ""
Write-Host "Presiona Enter para continuar..."
Read-Host
