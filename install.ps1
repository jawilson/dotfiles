[CmdletBinding()]
param(
  [ValidateSet('work', 'personal')]
  [string]$Profile,
  [switch]$NoRunZsh
)

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot

# The profile selects mise.<profile>.toml; .miserc.local.toml keeps it for later runs.
$misercLocal = Join-Path $repo '.miserc.local.toml'
if (-not $Profile -and (Test-Path $misercLocal)) {
  $content = Get-Content $misercLocal -Raw
  if ($content -match 'env\s*=\s*\["([^"]+)"\]') {
    $Profile = $matches[1]
  }
}

if (-not $Profile -and [Environment]::UserInteractive) {
  $Profile = Read-Host "Profile (work or personal)"
}

if ($Profile -notin @('work', 'personal')) {
  throw "Profile must be 'work' or 'personal'."
}

Set-Content -Path $misercLocal -Value ('env = ["{0}"]' -f $Profile)

# Ensure WinGet Links directory is on PATH for this session
$wingetLinks = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links'
if ($env:Path -notlike "*$wingetLinks*") {
  $env:Path = "$wingetLinks;$env:Path"
}

# Install mise via winget if missing
if (-not (Get-Command mise -ErrorAction SilentlyContinue)) {
  Write-Host "Installing mise via winget..."
  winget install --id jdx.mise -e --accept-source-agreements --accept-package-agreements

  # Refresh PATH from registry and ensure WinGet Links is included
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
  $env:Path = "$wingetLinks;$userPath;$machinePath"

  if (-not (Get-Command mise -ErrorAction SilentlyContinue)) {
    throw "mise is unavailable after winget installation; verify WinGet installation and rerun."
  }
}

# Run mise bootstrap from repo directory
Push-Location $repo
try {
  mise trust ./mise.toml
  mise -E $Profile bootstrap --yes --force-dotfiles --skip-dirty
} finally {
  Pop-Location
}
