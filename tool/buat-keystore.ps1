# Membuat keystore rilis Android dan android/key.properties (W4-08).
#
# Jalankan SENDIRI di terminal, dari folder proyek:
#   powershell -ExecutionPolicy Bypass -File tool\buat-keystore.ps1
#
# Sandi diketik di terminal ini dan tidak dikirim ke mana pun. Keystore
# disimpan di luar proyek (%USERPROFILE%\keystore), key.properties di
# android/ (keduanya sudah di .gitignore). Setelah selesai: CADANGKAN file
# .jks dan sandinya (password manager + penyimpanan cloud pribadi). Kalau
# hilang, versi baru app tidak bisa dipasang di atas versi lama.

$ErrorActionPreference = 'Stop'

$keytool = Join-Path $env:ProgramFiles 'Android\Android Studio\jbr\bin\keytool.exe'
if (-not (Test-Path $keytool)) {
  $found = Get-Command keytool -ErrorAction SilentlyContinue
  if (-not $found) { throw 'keytool tidak ditemukan. Pasang Android Studio atau JDK dulu.' }
  $keytool = $found.Source
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$keyProperties = Join-Path $projectRoot 'android\key.properties'
$keystoreDir = Join-Path $env:USERPROFILE 'keystore'
$keystore = Join-Path $keystoreDir 'super_app.jks'
$alias = 'super_app'

if (Test-Path $keystore) { throw "Keystore sudah ada: $keystore. Tidak ditimpa." }
if (Test-Path $keyProperties) { throw "android\key.properties sudah ada. Tidak ditimpa." }

function Read-Secret([string]$prompt) {
  $secure = Read-Host -Prompt $prompt -AsSecureString
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
  finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

$password = Read-Secret 'Sandi keystore (minimal 6 karakter)'
$again = Read-Secret 'Ulangi sandi'
if ($password -ne $again) { throw 'Sandi tidak sama.' }
if ($password.Length -lt 6) { throw 'Sandi minimal 6 karakter.' }
$name = Read-Host -Prompt 'Nama di sertifikat (misalnya Bayu)'
if ([string]::IsNullOrWhiteSpace($name)) { $name = 'Super App' }

New-Item -ItemType Directory -Force $keystoreDir | Out-Null

# Satu sandi untuk keystore dan kunci (format PKCS12 memakai sandi yang sama).
& $keytool -genkeypair -v `
  -keystore $keystore -storetype PKCS12 `
  -alias $alias -keyalg RSA -keysize 2048 -validity 10000 `
  -storepass $password -keypass $password `
  -dname "CN=$name, O=Super App, C=ID"
if ($LASTEXITCODE -ne 0) { throw 'keytool gagal membuat keystore.' }

$storeFile = $keystore -replace '\\', '/'
$content = @"
storePassword=$password
keyPassword=$password
keyAlias=$alias
storeFile=$storeFile
"@
[IO.File]::WriteAllText($keyProperties, $content)

Write-Host ''
Write-Host "Keystore : $keystore"
Write-Host "Properti : $keyProperties"
Write-Host 'CADANGKAN file .jks dan sandinya sekarang.'
