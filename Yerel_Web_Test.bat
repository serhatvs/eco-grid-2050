@echo off
chcp 65001 >nul
echo ========================================================
echo  Eco-Grid: 2050 - Yerel Web Test Sunucusu
echo ========================================================
echo.
echo Tarayicilar guvenlik kisitlamalari (CORS) nedeniyle
echo WebAssembly dosyalarini dogrudan cift tikla (file://) calistirmaz.
echo Bu betik yerel bir HTTP sunucusu acarak oyunu tarayicinizda baslatir.
echo.
echo Sunucu adresi: http://localhost:8080/index.html
echo Oyundan cikmak istediginizde bu pencereyi kapatabilirsiniz.
echo.

start "" "http://localhost:8080/index.html"
python -m http.server 8080 -d "%~dp0"
if errorlevel 1 (
    echo Python bulunamadi, PowerShell yerel sunucu deneniyor...
    powershell -ExecutionPolicy Bypass -Command "Start-Process 'http://localhost:8080/index.html'; python -m http.server 8080"
)
pause
