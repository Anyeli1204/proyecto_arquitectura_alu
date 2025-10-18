# Script para descargar e instalar Icarus Verilog ejecutable
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Descargando Icarus Verilog Ejecutable" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Crear directorio temporal
$tempDir = "temp_iverilog_exe"
if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir | Out-Null
Set-Location $tempDir

try {
    Write-Host "Descargando Icarus Verilog ejecutable..." -ForegroundColor Green
    
    # URL del ejecutable precompilado
    $url = "https://github.com/steveicarus/iverilog/releases/download/v12_0/iverilog-12.0-x64.exe"
    $installer = "iverilog-installer.exe"
    
    Write-Host "Descargando desde: $url" -ForegroundColor Yellow
    
    # Usar Invoke-WebRequest con parámetros para manejar mejor la descarga
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $url -OutFile $installer -UseBasicParsing -TimeoutSec 60
    
    if (Test-Path $installer) {
        $fileSize = [math]::Round((Get-Item $installer).Length / 1MB, 2)
        Write-Host "Descarga completada! Tamaño: $fileSize MB" -ForegroundColor Green
        Write-Host ""
        Write-Host "IMPORTANTE: Durante la instalación:" -ForegroundColor Yellow
        Write-Host "1. Marca 'Add to PATH'" -ForegroundColor White
        Write-Host "2. Instala en C:\iverilog (recomendado)" -ForegroundColor White
        Write-Host "3. Acepta todos los componentes" -ForegroundColor White
        Write-Host ""
        
        $continue = Read-Host "¿Deseas ejecutar el instalador ahora? (s/n)"
        if ($continue -eq "s" -or $continue -eq "S") {
            Write-Host "Ejecutando instalador..." -ForegroundColor Green
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
                } else {
                    Write-Host "Error: Icarus Verilog no se instaló correctamente" -ForegroundColor Red
                    Write-Host "Verifica que se agregó al PATH del sistema" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "Error: Icarus Verilog no se encontró en el PATH" -ForegroundColor Red
                Write-Host "Reinicia la terminal y vuelve a intentar" -ForegroundColor Yellow
            }
        } else {
            Write-Host "Instalador guardado en: $((Get-Location).Path)\$installer" -ForegroundColor Yellow
            Write-Host "Ejecuta el instalador manualmente cuando estés listo" -ForegroundColor White
        }
        
    } else {
        Write-Host "Error: No se pudo descargar el instalador" -ForegroundColor Red
        Write-Host ""
        Write-Host "Instalación manual:" -ForegroundColor Yellow
        Write-Host "1. Ve a: https://github.com/steveicarus/iverilog/releases" -ForegroundColor White
        Write-Host "2. Descarga iverilog-12.0-x64.exe" -ForegroundColor White
        Write-Host "3. Ejecuta el instalador" -ForegroundColor White
        Write-Host "4. Asegúrate de marcar 'Add to PATH'" -ForegroundColor White
    }
    
} catch {
    Write-Host "Error durante la descarga: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Instalación manual:" -ForegroundColor Yellow
    Write-Host "1. Ve a: https://github.com/steveicarus/iverilog/releases" -ForegroundColor White
    Write-Host "2. Descarga la versión más reciente para Windows" -ForegroundColor White
    Write-Host "3. Ejecuta el instalador y asegúrate de agregar al PATH" -ForegroundColor White
} finally {
    # No limpiar automáticamente para que el usuario pueda ejecutar el instalador
    Write-Host ""
    Write-Host "Directorio temporal: $((Get-Location).Path)" -ForegroundColor Yellow
    Write-Host "Presiona Enter para continuar..."
    Read-Host
}
