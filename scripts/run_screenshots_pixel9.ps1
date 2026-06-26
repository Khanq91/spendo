param(
  [string]$EmulatorName = "Pixel_9_Pro",
  [string]$Dir = "screenshots",
  [string]$Out = "report.html",
  [int]$BootTimeoutSeconds = 180,
  [switch]$NoOpen
)

$ErrorActionPreference = "Stop"

function Write-Step($Message) {
  Write-Host "=> $Message" -ForegroundColor Green
}

function Get-FirstAdbEmulator {
  if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    return ""
  }

  $line = adb devices | Select-String -Pattern "^emulator-\d+\s+device$" | Select-Object -First 1
  if ($null -eq $line) {
    return ""
  }

  return ($line.ToString() -split "\s+")[0]
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw "Flutter khong tim thay trong PATH."
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$runner = Join-Path $scriptDir "run_screenshots.ps1"
if (-not (Test-Path -LiteralPath $runner)) {
  throw "Khong tim thay $runner"
}

$device = Get-FirstAdbEmulator
if ($device -ne "") {
  Write-Step "Dang co emulator online: $device"
} else {
  Write-Step "Mo emulator $EmulatorName"
  flutter emulators --launch $EmulatorName

  $deadline = (Get-Date).AddSeconds($BootTimeoutSeconds)
  do {
    Start-Sleep -Seconds 3
    $device = Get-FirstAdbEmulator

    if ($device -ne "" -and (Get-Command adb -ErrorAction SilentlyContinue)) {
      $booted = adb -s $device shell getprop sys.boot_completed 2>$null
      if (($booted -join "").Trim() -eq "1") {
        break
      }
    }
  } while ((Get-Date) -lt $deadline)

  if ($device -eq "") {
    Write-Host "Khong lay duoc adb device id, se de Flutter tu chon device." -ForegroundColor Yellow
  } else {
    Write-Step "Emulator san sang: $device"
  }
}

$args = @(
  "-Dir", $Dir,
  "-Out", $Out
)

if ($device -ne "") {
  $args += @("-Device", $device)
}

if ($NoOpen) {
  $args += "-NoOpen"
}

Write-Step "Chay screenshot pipeline"
& $runner @args
