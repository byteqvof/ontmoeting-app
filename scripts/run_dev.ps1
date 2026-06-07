param(
  [string]$Device = "",
  [string]$Config = "config/dev.local.json"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

if (-not (Test-Path $Config)) {
  $Config = "config/dev.example.json"
  Write-Host "Geen config/dev.local.json gevonden; gebruik config/dev.example.json."
  Write-Host "Maak config/dev.local.json voor Firebase/PostHog/Sentry of project-specifieke waarden."
}

$argsList = @(
  "flutter",
  "run",
  "--dart-define-from-file=$Config"
)

if ($Device.Trim().Length -gt 0) {
  $argsList += @("-d", $Device)
}

& fvm @argsList
