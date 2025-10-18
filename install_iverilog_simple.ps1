# Script simple para instalar Icarus Verilog
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Instalador de Icarus Verilog" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar si ya está instalado
try {
    $version = & iverilog -V 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Icarus Verilog ya está instalado:" -ForegroundColor Green
        Write-Host $version -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Puedes ejecutar testbenches con:" -ForegroundColor Green
        Write-Host "  .\simulate_verilog.ps1 -Testbench alu" -ForegroundColor White
        exit 0
    }
}
catch {
    Write-Host "Icarus Verilog no está instalado. Instalando..." -ForegroundColor Yellow
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
    
    # URL del instalador
    $url = "https://github.com/steveicarus/iverilog/releases/download/v12_0/iverilog-12.0-x64.exe"
    $installer = "iverilog-installer.exe"
    
    # Descargar
    Write-Host "Descargando desde: $url" -ForegroundColor Yellow
    Invoke-WebRequest -Uri $url -OutFile $installer -UseBasicParsing
    
    if (Test-Path $installer) {
        Write-Host "Descarga completada!" -ForegroundColor Green
        Write-Host ""
        Write-Host "IMPORTANTE: Durante la instalación:" -ForegroundColor Yellow
        Write-Host "1. Marca 'Add to PATH'" -ForegroundColor White
        Write-Host "2. Instala en C:\iverilog" -ForegroundColor White
        Write-Host ""
        
        Read-Host "Presiona Enter para ejecutar el instalador"
        
        # Ejecutar instalador
        Start-Process -FilePath $installer -Wait
        
        Write-Host ""
        Write-Host "Verificando instalación..." -ForegroundColor Green
        
        # Verificar instalación
        try {
            $version = & iverilog -V 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "¡Instalación exitosa!" -ForegroundColor Green
                Write-Host $version -ForegroundColor Yellow
                Write-Host ""
                Write-Host "Ahora puedes ejecutar testbenches:" -ForegroundColor Green
                Write-Host "  .\simulate_verilog.ps1 -Testbench alu" -ForegroundColor White
            }
            else {
                Write-Host "Error: Icarus Verilog no se instaló correctamente" -ForegroundColor Red
                Write-Host "Verifica que se agregó al PATH del sistema" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "Error: Icarus Verilog no se encontró en el PATH" -ForegroundColor Red
            Write-Host "Reinicia la terminal y vuelve a intentar" -ForegroundColor Yellow
        }
        
    }
    else {
        Write-Host "Error: No se pudo descargar el instalador" -ForegroundColor Red
        Write-Host ""
        Write-Host "Instalación manual:" -ForegroundColor Yellow
        Write-Host "1. Ve a: https://github.com/steveicarus/iverilog/releases" -ForegroundColor White
        Write-Host "2. Descarga iverilog-12.0-x64.exe" -ForegroundColor White
        Write-Host "3. Ejecuta el instalador" -ForegroundColor White
        Write-Host "4. Asegúrate de marcar 'Add to PATH'" -ForegroundColor White
    }
    
}
catch {
    Write-Host "Error durante la descarga: $($_.Exception.Message)" -ForegroundColor Red
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
