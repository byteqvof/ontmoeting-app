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

try {
  $configJson = Get-Content $Config -Raw | ConvertFrom-Json
  if ($configJson.TOCH_ENABLE_PUSH -ne $true) {
    Write-Warning "TOCH_ENABLE_PUSH staat niet aan in $Config; de app registreert dan geen FCM-token."
  } else {
    $hasAndroidAppId = [string]::IsNullOrWhiteSpace($configJson.FIREBASE_ANDROID_APP_ID) -eq $false
    $hasIosAppId = [string]::IsNullOrWhiteSpace($configJson.FIREBASE_IOS_APP_ID) -eq $false
    $hasLegacyAppId = [string]::IsNullOrWhiteSpace($configJson.FIREBASE_APP_ID) -eq $false
    $hasSharedFirebaseConfig = (
      [string]::IsNullOrWhiteSpace($configJson.FIREBASE_PROJECT_ID) -eq $false -and
      [string]::IsNullOrWhiteSpace($configJson.FIREBASE_MESSAGING_SENDER_ID) -eq $false -and
      [string]::IsNullOrWhiteSpace($configJson.FIREBASE_API_KEY) -eq $false
    )

    if (-not $hasSharedFirebaseConfig -or (-not $hasAndroidAppId -and -not $hasIosAppId -and -not $hasLegacyAppId)) {
      Write-Warning "Push staat aan, maar Firebase config in $Config is niet compleet."
    }
  }
} catch {
  Write-Warning "Kon $Config niet controleren als JSON: $($_.Exception.Message)"
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
