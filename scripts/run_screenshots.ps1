param(
  [string]$Device = "",
  [string]$Dir = "screenshots",
  [string]$Out = "report.html",
  [switch]$NoOpen
)

$ErrorActionPreference = "Stop"

function Write-Step($Message) {
  Write-Host "=> $Message" -ForegroundColor Green
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw "Flutter khong tim thay trong PATH."
}

if (-not (Get-Command dart -ErrorAction SilentlyContinue)) {
  throw "Dart khong tim thay trong PATH."
}

Write-Step "Don thu muc screenshot"
if (Test-Path -LiteralPath $Dir) {
  Remove-Item -LiteralPath $Dir -Recurse -Force
}
New-Item -ItemType Directory -Path $Dir | Out-Null

$flutterArgs = @(
  "drive",
  "--no-pub",
  "--driver=test_driver/integration_test.dart",
  "--target=integration_test/screenshot_test.dart",
  "--dart-define=SCREENSHOT_DIR=$Dir",
  "--dart-define=SCREENSHOT_SEED_DATA=true"
)

if ($Device -ne "") {
  $flutterArgs += @("-d", $Device)
}

Write-Step "Chay Flutter integration test"
$previousScreenshotDir = $env:SCREENSHOT_DIR
$env:SCREENSHOT_DIR = $Dir
& flutter @flutterArgs
$flutterExitCode = $LASTEXITCODE
if ($null -eq $previousScreenshotDir) { Remove-Item Env:SCREENSHOT_DIR -ErrorAction SilentlyContinue } else { $env:SCREENSHOT_DIR = $previousScreenshotDir }
if ($flutterExitCode -ne 0) {
  throw "Integration test that bai."
}

Write-Step "Tao HTML report"
& dart "scripts/generate_report.dart" "--dir=$Dir" "--out=$Out"
if ($LASTEXITCODE -ne 0) {
  throw "Generate report that bai."
}

Write-Host ""
Write-Host "Hoan thanh!" -ForegroundColor Green
Write-Host "Report: $Out"
Write-Host "Anh:    $Dir"

if (-not $NoOpen) {
  Start-Process -FilePath $Out
}
