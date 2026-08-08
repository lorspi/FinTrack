@echo off
:: ============================================================
::  iniciar-servidor.bat  -  FinTrack
::  Sirve el build de produccion (carpeta dist) con Node.js y
::  abre el navegador en http://localhost:8080
::  Uso:    iniciar-servidor.bat [puerto]
::  Ejemplo: iniciar-servidor.bat 9000
::  Requisito: Node.js instalado y accesible en el PATH.
::  Nota: esta es la copia maestra (raiz de web/). El build la
::  copia automaticamente a dist/ (ver scripts/copy-servidor-bat.mjs).
:: ============================================================
setlocal EnableExtensions
title FinTrack - Servidor local

:: Ir a la carpeta donde vive este .bat (raiz del dist)
cd /d "%~dp0"

:: Si esta la copia maestra (raiz de web/) y existe dist\index.html,
:: servir la subcarpeta dist; la copia dentro de dist se sirve a si misma.
if exist "dist\index.html" cd /d "dist"

echo ============================================================
echo   FinTrack - Servidor local del build de produccion
echo ============================================================
echo.

if not exist "index.html" (
    echo [AVISO] No se encontro index.html en esta carpeta.
    echo   Primero genera el build:  npm run build  (dentro de la carpeta web)
    echo.
)

:: Puerto por defecto, se puede cambiar con el primer argumento
set "PORT=8080"
if not "%~1"=="" set "PORT=%~1"

:: Node.js es necesario para servir los archivos
where node >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Node.js no esta instalado o no esta en el PATH.
    echo   Descargalo desde https://nodejs.org y vuelve a intentar.
    echo.
    pause
    exit /b 1
)

:: Localizar la linea donde empieza el codigo JavaScript embebido
set "JS_MARK_NAME=START_JS_CODE"
set "JS_MARK=:%JS_MARK_NAME%"
set "JS_START_LINE="
for /f "tokens=1 delims=:" %%L in ('findstr /n /c:"%JS_MARK%" "%~f0"') do (
    if not defined JS_START_LINE set "JS_START_LINE=%%L"
)
if not defined JS_START_LINE (
    echo [ERROR] No se encontro el codigo del servidor dentro del .bat.
    pause
    exit /b 1
)
set /a JS_START_LINE+=1

:: Extraer el codigo JavaScript a un archivo temporal
set "TMP_JS=%TEMP%\fintrack-server-%RANDOM%.js"
more +%JS_START_LINE% < "%~f0" > "%TMP_JS%"
if errorlevel 1 (
    echo [ERROR] No se pudo extraer el codigo del servidor.
    pause
    exit /b 1
)

echo Iniciando el servidor en http://localhost:%PORT% ...
echo Presiona Ctrl+C para detenerlo.
echo.

node "%TMP_JS%" %PORT%
set "EXIT_CODE=%ERRORLEVEL%"

del "%TMP_JS%" >nul 2>nul

if "%EXIT_CODE%"=="0" exit /b 0
echo.
echo El servidor se detuvo con un error (codigo %EXIT_CODE%).
pause
exit /b %EXIT_CODE%

:START_JS_CODE
// FinTrack - servidor local para el build de produccion (dist). Sirve archivos estaticos con fallback SPA y abre el navegador.
'use strict';
const http = require('http');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { exec } = require('child_process');
const ROOT = process.cwd();
let PORT = parseInt(process.argv[2], 10);
if (!Number.isInteger(PORT) || PORT <= 0 || PORT > 65535) PORT = 8080;
const MIME = {'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.mjs':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.json':'application/json; charset=utf-8','.svg':'image/svg+xml','.png':'image/png','.jpg':'image/jpeg','.jpeg':'image/jpeg','.gif':'image/gif','.webp':'image/webp','.ico':'image/x-icon','.woff':'font/woff','.woff2':'font/woff2','.ttf':'font/ttf','.otf':'font/otf','.txt':'text/plain; charset=utf-8','.xml':'application/xml','.map':'application/json','.webmanifest':'application/manifest+json'};
function log(msg){console.log('[FinTrack] '+msg);}
function sendFile(res, filePath, status){
  const type = MIME[path.extname(filePath).toLowerCase()] || 'application/octet-stream';
  res.writeHead(status || 200, {'Content-Type': type, 'Cache-Control': (path.extname(filePath).toLowerCase() === '.html') ? 'no-cache' : 'public, max-age=86400'});
  fs.createReadStream(filePath).on('error', function(){ res.writeHead(404); res.end('404 Not Found'); }).pipe(res);
}
function requestHandler(req, res){
  let pathname;
  try { pathname = decodeURIComponent(new URL(req.url, 'http://localhost').pathname); } catch (e) { res.writeHead(400); res.end('Bad Request'); return; }
  if (pathname.endsWith('/')) pathname += 'index.html';
  const filePath = path.normalize(path.join(ROOT, pathname));
  if (filePath !== ROOT && !filePath.startsWith(ROOT + path.sep)) { res.writeHead(403); res.end('Forbidden'); return; }
  fs.stat(filePath, function(err, stats){
    if (!err && stats.isFile()) return sendFile(res, filePath);
    if (!err && stats.isDirectory()) return sendFile(res, path.join(filePath, 'index.html'));
    if (path.extname(pathname) === '') return sendFile(res, path.join(ROOT, 'index.html'));
    res.writeHead(404, {'Content-Type': 'text/plain; charset=utf-8'});
    res.end('404 - No encontrado: '+pathname);
  });
}
function getLanIps(){
  const out = [];
  const nets = os.networkInterfaces();
  for (const name of Object.keys(nets)) { for (const net of nets[name] || []) { if (net.family === 'IPv4' && !net.internal) out.push(net.address); } }
  return out;
}
function openBrowser(url){
  const cmd = process.platform === 'win32' ? 'start "" "'+url+'"' : process.platform === 'darwin' ? 'open "'+url+'"' : 'xdg-open "'+url+'"';
  exec(cmd, function(err){ if (err) log('Abre manualmente en tu navegador: '+url); });
}
function start(port){
  const server = http.createServer(requestHandler);
  server.on('error', function(err){
    if (err.code === 'EADDRINUSE' && port < PORT + 20) { log('El puerto '+port+' esta ocupado, probando con '+(port+1)+' ...'); return start(port+1); }
    console.error('[FinTrack] Error del servidor: '+err.message);
    process.exit(1);
  });
  server.listen(port, '0.0.0.0', function(){
    const url = 'http://localhost:'+port;
    console.log('');
    console.log('================================================');
    console.log('  FinTrack en marcha!');
    console.log('  -> '+url+'   (este equipo)');
    getLanIps().forEach(function(ip){ console.log('  -> http://'+ip+':'+port+'   (celular en la misma red)'); });
    console.log('  Presiona Ctrl+C para detener el servidor.');
    console.log('================================================');
    console.log('');
    if (process.env.FINTRACK_NO_BROWSER !== '1') openBrowser(url);
  });
}
start(PORT);
