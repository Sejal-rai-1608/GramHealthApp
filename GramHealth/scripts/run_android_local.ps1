# GramHealth Local Android Development Runner
# Ensures ADB reverse is active before launching Flutter so physical device reaches host Node.js backend.

param(
    [string]$Device = "RZ8R90W57LF"
)

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "GramHealth Local Android Development Setup" -ForegroundColor Cyan
Write-Host "=================================================="

# Locate ADB binary
$adbPath = "C:\Users\shubh\AppData\Local\Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adbPath)) {
    $adbPath = (Get-Command adb -ErrorAction SilentlyContinue).Source
}
if (-not $adbPath) {
    Write-Error "ADB not found. Please ensure Android SDK platform-tools is installed."
    exit 1
}

Write-Host "`n[1/4] Checking connected devices..." -ForegroundColor Yellow
$deviceLines = & $adbPath devices | Where-Object { $_ -match "\s+device$" }

$targetDevice = $null
if ($deviceLines) {
    $connectedDevices = @()
    foreach ($line in $deviceLines) {
        $id = ($line -split "\s+")[0].Trim()
        if ($id) { $connectedDevices += $id }
    }
    
    if ($connectedDevices -contains $Device) {
        $targetDevice = $Device
    } else {
        $targetDevice = $connectedDevices[0]
        Write-Host "Notice: Requested device '$Device' not found, but connected device '$targetDevice' is available. Using '$targetDevice'." -ForegroundColor Magenta
    }
} else {
    Write-Host "WARNING: No Android device detected via USB." -ForegroundColor Red
    Write-Host "Please connect your phone, enable USB debugging, and allow the USB debugging prompt on your device." -ForegroundColor Yellow
    Write-Host "Defaulting to target device ID: $Device"
    $targetDevice = $Device
}

Write-Host "`nTarget Device: $targetDevice" -ForegroundColor Cyan

Write-Host "`n[2/4] Resetting and establishing ADB reverse for port 3000..." -ForegroundColor Yellow
& $adbPath -s $targetDevice reverse --remove-all 2>$null
& $adbPath -s $targetDevice reverse tcp:3000 tcp:3000

Write-Host "`n[3/4] Verifying ADB reverse status..." -ForegroundColor Yellow
& $adbPath -s $targetDevice reverse --list

Write-Host "`n--------------------------------------------------" -ForegroundColor Green
Write-Host "ADB reverse ready:" -ForegroundColor Green
Write-Host "phone 127.0.0.1:3000" -ForegroundColor Green
Write-Host "-> PC 127.0.0.1:3000" -ForegroundColor Green
Write-Host "--------------------------------------------------`n" -ForegroundColor Green

Write-Host "[4/4] Starting Flutter app on device $targetDevice..." -ForegroundColor Yellow
flutter run -d $targetDevice
