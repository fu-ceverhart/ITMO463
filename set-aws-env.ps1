$envFile = Join-Path $PSScriptRoot ".env"

foreach ($line in Get-Content $envFile) {
    $parts = $line.Split("=")
    $key   = $parts[0]
    $value = $parts[1]

    if ($key -eq "ACCESS_KEY") { $env:AWS_ACCESS_KEY_ID     = $value }
    if ($key -eq "SECRET_KEY") { $env:AWS_SECRET_ACCESS_KEY = $value }
    if ($key -eq "REGION")     { $env:AWS_DEFAULT_REGION    = $value }
}

Write-Host "AWS credentials set."
