# Script de instalación de Icarus Verilog para Windows
# Ejecutar como administrador si es necesario

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Instalador de Icarus Verilog para Windows" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar si Icarus Verilog ya está instalado
try {
    $iverilogVersion = & iverilog -V 2>&1
    Write-Host "Icarus Verilog ya está instalado:" -ForegroundColor Green
    Write-Host $iverilogVersion -ForegroundColor Yellow
    Write-Host ""
    
    $reinstall = Read-Host "¿Deseas reinstalar? (s/n)"
    if ($reinstall -ne "s" -and $reinstall -ne "S") {
        Write-Host "Instalación cancelada." -ForegroundColor Yellow
        exit 0
    }
}
catch {
    Write-Host "Icarus Verilog no está instalado. Procediendo con la instalación..." -ForegroundColor Yellow
}

# Crear directorio temporal
$tempDir = "temp_iverilog"
if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir | Out-Null
Set-Location $tempDir

try {
    Write-Host "Descargando Icarus Verilog..." -ForegroundColor Green
    
    # URL del instalador más reciente
    $downloadUrl = "https://github.com/steveicarus/iverilog/releases/download/v12_0/iverilog-12.0-x64.exe"
    $installerFile = "iverilog-installer.exe"
    
    # Descargar usando Invoke-WebRequest
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installerFile -UseBasicParsing
    
    if (-not (Test-Path $installerFile)) {
        throw "No se pudo descargar el instalador"
    }
    
    Write-Host "Descarga completada." -ForegroundColor Green
    Write-Host ""
    Write-Host "IMPORTANTE: Durante la instalación, asegúrate de:" -ForegroundColor Yellow
    Write-Host "1. Marcar 'Add to PATH'" -ForegroundColor Yellow
    Write-Host "2. Instalar en C:\iverilog (recomendado)" -ForegroundColor Yellow
    Write-Host ""
    
    Read-Host "Presiona Enter para continuar con la instalación"
    
    # Ejecutar instalador
    Start-Process -FilePath $installerFile -Wait
    
    Write-Host ""
    Write-Host "Verificando instalación..." -ForegroundColor Green
    
    # Verificar instalación
    try {
        $version = & iverilog -V 2>&1
        Write-Host "¡Instalación exitosa!" -ForegroundColor Green
        Write-Host $version -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Ahora puedes usar el Makefile para compilar y simular tu proyecto." -ForegroundColor Green
        Write-Host ""
        Write-Host "Comandos disponibles:" -ForegroundColor Cyan
        Write-Host "  make help           - Ver ayuda" -ForegroundColor White
        Write-Host "  make list-tb        - Listar testbenches" -ForegroundColor White
        Write-Host "  make run-tb_alu     - Ejecutar testbench de ALU" -ForegroundColor White
        Write-Host "  make test-all       - Ejecutar todos los testbenches" -ForegroundColor White
    }
    catch {
        Write-Host "Error: Icarus Verilog no se instaló correctamente" -ForegroundColor Red
        Write-Host "Por favor, verifica que se agregó al PATH del sistema" -ForegroundColor Red
        Write-Host "Puedes agregarlo manualmente desde:" -ForegroundColor Yellow
        Write-Host "Panel de Control > Sistema > Configuración avanzada > Variables de entorno" -ForegroundColor Yellow
    }
    
}
catch {
    Write-Host "Error durante la instalación: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Instalación manual:" -ForegroundColor Yellow
    Write-Host "1. Ve a: https://github.com/steveicarus/iverilog/releases" -ForegroundColor White
    Write-Host "2. Descarga la versión más reciente para Windows" -ForegroundColor White
    Write-Host "3. Ejecuta el instalador y asegúrate de agregar al PATH" -ForegroundColor White
}
finally {
    # Limpiar
    Set-Location ..
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force
    }
}

Write-Host ""
Write-Host "Presiona Enter para continuar..."
Read-Host
