$ErrorActionPreference = 'Stop'

Write-Host 'Installing MySQL Community Server...' -ForegroundColor Cyan
winget install --id Oracle.MySQL --exact --source winget --accept-source-agreements --accept-package-agreements

Write-Host ''
Write-Host 'MySQL installation finished. Set DB_PASSWORD in backend/.env, then run:' -ForegroundColor Green
Write-Host '  npm.cmd start'
