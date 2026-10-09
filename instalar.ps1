# Instala la skill "generar-imagen" en Claude Code y guarda las claves de Cloudflare.
$ErrorActionPreference = "Stop"
$aqui = Split-Path -Parent $MyInvocation.MyCommand.Path

function Paso($t) { Write-Host ""; Write-Host "== $t" -ForegroundColor Cyan }
function Ok($t) { Write-Host "   OK  $t" -ForegroundColor Green }
function Aviso($t) { Write-Host "   !!  $t" -ForegroundColor Yellow }

Write-Host "Generar imagenes con Claude (FLUX gratis de Cloudflare)" -ForegroundColor White

# 1. Node.js
Paso "1/3  Comprobando Node.js"
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Aviso "No tienes Node.js. Lo instalo con winget..."
    winget install --id OpenJS.NodeJS.LTS -e --accept-package-agreements --accept-source-agreements
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Aviso "No he podido instalar Node.js. Instalalo desde https://nodejs.org (version LTS) y vuelve a ejecutar INSTALAR.cmd."
        Read-Host "Pulsa Enter para cerrar"
        exit 1
    }
}
Ok ("Node " + (node --version))

# 2. Skill
Paso "2/3  Copiando la skill a Claude Code"
$destino = Join-Path $env:USERPROFILE ".claude\skills\generar-imagen"
New-Item -ItemType Directory -Force -Path $destino | Out-Null
Copy-Item -Path (Join-Path $aqui "skills\generar-imagen\*") -Destination $destino -Recurse -Force
Ok "Skill instalada en $destino"

# 3. Claves
Paso "3/3  Claves de Cloudflare"
$cuenta = [Environment]::GetEnvironmentVariable("CLOUDFLARE_ACCOUNT_ID", "User")
$token = [Environment]::GetEnvironmentVariable("CLOUDFLARE_API_TOKEN", "User")
if ($cuenta -and $token) {
    Ok "Ya tenias las claves guardadas."
    $resp = Read-Host "   Quieres cambiarlas? (s/N)"
    if ($resp -match "^[sS]") { & (Join-Path $aqui "guardar-claves.ps1") -SinPausa }
} else {
    Write-Host "   Necesitas tu Account ID y un token de Cloudflare (mira el README, paso 2)."
    & (Join-Path $aqui "guardar-claves.ps1") -SinPausa
}

# Prueba
$env:CLOUDFLARE_ACCOUNT_ID = [Environment]::GetEnvironmentVariable("CLOUDFLARE_ACCOUNT_ID", "User")
$env:CLOUDFLARE_API_TOKEN = [Environment]::GetEnvironmentVariable("CLOUDFLARE_API_TOKEN", "User")
if ($env:CLOUDFLARE_ACCOUNT_ID -and $env:CLOUDFLARE_API_TOKEN) {
    Paso "Prueba: generando una imagen en el Escritorio"
    $prueba = Join-Path ([Environment]::GetFolderPath("Desktop")) "prueba-generar-imagen.jpg"
    node (Join-Path $destino "generar.mjs") --prompt "a clear glass water bottle on a white marble counter, soft window light, minimalist product photo" --salida $prueba
    if ($LASTEXITCODE -eq 0) {
        Ok "Funciona. Mira $prueba"
        Start-Process $prueba
    } else {
        Aviso "La prueba ha fallado. Revisa el mensaje de arriba y vuelve a ejecutar 'Guardar claves Cloudflare.cmd'."
    }
} else {
    Aviso "Sin claves no podra generar imagenes. Ejecuta 'Guardar claves Cloudflare.cmd' cuando las tengas."
}

Write-Host ""
Write-Host "Listo. Cierra Claude del todo y vuelve a abrirlo. Despues pidele: 'genera una imagen de ...'" -ForegroundColor White
Read-Host "Pulsa Enter para cerrar"
