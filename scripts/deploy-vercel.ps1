param(
  [switch]$Preview,
  [string]$Token
)

$flutter = "C:\flutter\bin\flutter.bat"
if (-not (Test-Path $flutter)) {
  throw "Flutter executable not found at $flutter"
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$prepareScript = Join-Path $PSScriptRoot "prepare-vercel-output.ps1"

Push-Location $repoRoot
try {
  & $flutter build web --release --base-href /
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }

  & $prepareScript
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }

  $vercelArgs = @("deploy", "--prebuilt", "--archive=tgz")
  if (-not $Preview) {
    $vercelArgs += "--prod"
  }
  if ($Token) {
    $vercelArgs += "--token"
    $vercelArgs += $Token
  }

  & vercel @vercelArgs
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}
finally {
  Pop-Location
}
