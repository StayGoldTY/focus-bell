param(
  [string]$Source = "build/web",
  [string]$Output = ".vercel/output"
)

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$sourcePath = (Resolve-Path (Join-Path $repoRoot $Source)).Path
$outputPath = Join-Path $repoRoot $Output

if (-not (Test-Path $sourcePath)) {
  throw "Source directory not found: $sourcePath"
}

$resolvedRepoRoot = (Resolve-Path $repoRoot).Path
if (Test-Path $outputPath) {
  $resolvedOutputPath = (Resolve-Path $outputPath).Path
  if ($resolvedOutputPath -notlike "$resolvedRepoRoot*") {
    throw "Refusing to clear unexpected output path: $resolvedOutputPath"
  }
  Remove-Item -LiteralPath $resolvedOutputPath -Recurse -Force
}

$staticPath = Join-Path $outputPath "static"
New-Item -ItemType Directory -Path $staticPath -Force | Out-Null

Get-ChildItem -LiteralPath $sourcePath -Force | ForEach-Object {
  Copy-Item -LiteralPath $_.FullName -Destination $staticPath -Recurse -Force
}

$configPath = Join-Path $outputPath "config.json"
$configJson = @{ version = 3 } | ConvertTo-Json -Compress
[System.IO.File]::WriteAllText(
  $configPath,
  $configJson,
  [System.Text.UTF8Encoding]::new($false)
)

Write-Output "Prepared Vercel output at $outputPath"
