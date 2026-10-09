# Guarda las claves de Cloudflare en tu usuario de Windows (no quedan en ningun archivo).
param([switch]$SinPausa)

$cuenta = (Read-Host "   Pega tu Account ID de Cloudflare y pulsa Enter").Trim()
$seguro = Read-Host "   Pega tu API token de Cloudflare y pulsa Enter (no se vera)" -AsSecureString
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($seguro)
try {
    $token = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr).Trim()
} finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
}

if ([string]::IsNullOrWhiteSpace($cuenta) -or [string]::IsNullOrWhiteSpace($token)) {
    Write-Host "   Falta alguno de los dos datos. No he cambiado nada." -ForegroundColor Yellow
} elseif ($cuenta -notmatch "^[0-9a-fA-F]{32}$") {
    Write-Host "   El Account ID debe tener 32 letras y numeros (0-9, a-f). No he cambiado nada." -ForegroundColor Yellow
} else {
    [Environment]::SetEnvironmentVariable("CLOUDFLARE_ACCOUNT_ID", $cuenta, "User")
    [Environment]::SetEnvironmentVariable("CLOUDFLARE_API_TOKEN", $token, "User")
    $final = $token.Substring([Math]::Max(0, $token.Length - 4))
    Write-Host "   Guardadas (el token acaba en ...$final). Cierra y vuelve a abrir Claude para que las vea." -ForegroundColor Green
}

if (-not $SinPausa) { Read-Host "Pulsa Enter para cerrar" }
