$envFile = Join-Path $PSScriptRoot ".env"

if (-not (Test-Path $envFile)) {
    Write-Error ".env file not found at: $envFile"
    exit 1
}

Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith('#')) {
        $parts = $line.Split('=', 2)
        if ($parts.Count -eq 2) {
            $key   = $parts[0].Trim()
            $value = $parts[1].Trim().Trim('"').Trim("'")
            [System.Environment]::SetEnvironmentVariable($key, $value, 'Process')
        }
    }
}

Write-Host "AWS credentials loaded from .env"
Write-Host "  AWS_ACCESS_KEY_ID     = $($env:AWS_ACCESS_KEY_ID.Substring(0,4))****"
Write-Host "  AWS_SECRET_ACCESS_KEY = ********"
if ($env:AWS_DEFAULT_REGION) {
    Write-Host "  AWS_DEFAULT_REGION    = $env:AWS_DEFAULT_REGION"
}
