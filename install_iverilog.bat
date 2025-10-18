@echo off
echo ========================================
echo Instalador de Icarus Verilog para Windows
echo ========================================
echo.

REM Verificar si Icarus Verilog ya está instalado
where iverilog >nul 2>nul
if %errorlevel% == 0 (
    echo Icarus Verilog ya está instalado:
    iverilog -V
    echo.
    echo ¿Deseas reinstalar? (s/n)
    set /p reinstall=
    if /i not "%reinstall%"=="s" goto :end
)

echo Descargando Icarus Verilog...
echo.

REM Crear directorio temporal
if not exist temp mkdir temp
cd temp

REM Descargar Icarus Verilog usando PowerShell
echo Descargando desde GitHub...
powershell -Command "& {Invoke-WebRequest -Uri 'https://github.com/steveicarus/iverilog/releases/download/v12_0/iverilog-12.0-x64.exe' -OutFile 'iverilog-installer.exe'}"

if not exist iverilog-installer.exe (
    echo Error: No se pudo descargar Icarus Verilog
    echo Por favor, descarga manualmente desde:
    echo https://github.com/steveicarus/iverilog/releases
    pause
    goto :cleanup
)

echo.
echo Ejecutando instalador...
echo IMPORTANTE: Durante la instalación, asegúrate de:
echo 1. Marcar "Add to PATH" 
echo 2. Instalar en C:\iverilog (recomendado)
echo.
pause

iverilog-installer.exe

echo.
echo Verificando instalación...
where iverilog >nul 2>nul
if %errorlevel% == 0 (
    echo ¡Instalación exitosa!
    iverilog -V
    echo.
    echo Ahora puedes usar el Makefile para compilar y simular tu proyecto.
) else (
    echo Error: Icarus Verilog no se instaló correctamente
    echo Por favor, verifica que se agregó al PATH del sistema
)

:cleanup
cd ..
rmdir /s /q temp

:end
echo.
echo Presiona cualquier tecla para continuar...
pause >nul
