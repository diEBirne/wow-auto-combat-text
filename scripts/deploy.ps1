# Deploy Auto Combat Text from this repository to a local WoW AddOns folder.
#
# Usage:
#   .\scripts\deploy.ps1
#   .\scripts\deploy.ps1 -WoWAddOnsPath "D:\Other\Path\Interface\AddOns"
#   .\scripts\deploy.ps1 -WhatIf
#
# Optional environment variable:
#   $env:WOW_ADDONS_PATH = "D:\Battle.net\World of Warcraft\_retail_\Interface\AddOns"

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$WoWAddOnsPath = ""
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $RepoRoot "AutoCombatText"
$AddOnName = "AutoCombatText"

$DefaultWoWAddOnsPaths = @(
    "D:\Battle.net\World of Warcraft\_retail_\Interface\AddOns",
    "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns",
    "C:\Program Files\World of Warcraft\_retail_\Interface\AddOns"
)

function Write-Step {
    param([string]$Message)
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Resolve-WoWAddOnsPath {
    param([string]$RequestedPath)

    if ($RequestedPath) {
        return $RequestedPath
    }

    if ($env:WOW_ADDONS_PATH) {
        return $env:WOW_ADDONS_PATH
    }

    foreach ($candidate in $DefaultWoWAddOnsPaths) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    return $DefaultWoWAddOnsPaths[0]
}

$WoWAddOnsPath = Resolve-WoWAddOnsPath -RequestedPath $WoWAddOnsPath
$Destination = Join-Path $WoWAddOnsPath $AddOnName

if (-not (Test-Path -LiteralPath $Source)) {
    throw "Source folder not found: $Source"
}

if (-not (Test-Path -LiteralPath $WoWAddOnsPath)) {
    throw @"
WoW AddOns folder not found: $WoWAddOnsPath

Adjust the path with -WoWAddOnsPath or set `$env:WOW_ADDONS_PATH.
Checked defaults:
  $($DefaultWoWAddOnsPaths -join "`n  ")
"@
}

Write-Step "Repository: $RepoRoot"
Write-Step "Source:      $Source"
Write-Step "Destination: $Destination"

if ($WhatIfPreference) {
    Write-Step "WhatIf: would mirror $AddOnName to WoW AddOns folder"
    Get-ChildItem -LiteralPath $Source -Recurse -File | ForEach-Object {
        $relativePath = $_.FullName.Substring($Source.Length).TrimStart("\")
        Write-Host "  copy $relativePath"
    }
    exit 0
}

if (-not (Test-Path -LiteralPath $Destination)) {
    Write-Step "Creating destination folder"
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
}

Write-Step "Syncing files (mirror)"

# /MIR keeps the WoW folder identical to the repo addon folder.
# Exit codes 0-7 are success for robocopy; >= 8 indicates an error.
$robocopyArgs = @(
    $Source,
    $Destination,
    "/MIR",
    "/NFL",
    "/NDL",
    "/NJH",
    "/NJS",
    "/NP",
    "/R:2",
    "/W:1"
)

& robocopy @robocopyArgs | Out-Null
$robocopyExitCode = $LASTEXITCODE

if ($robocopyExitCode -ge 8) {
    throw "Robocopy failed with exit code $robocopyExitCode"
}

$fileCount = (Get-ChildItem -LiteralPath $Destination -Recurse -File).Count
Write-Host ""
Write-Host "Deploy complete." -ForegroundColor Green
Write-Host "  Files in destination: $fileCount"
Write-Host "  Next step in WoW: /reload or /act status"

exit 0
