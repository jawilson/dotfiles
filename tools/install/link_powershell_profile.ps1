param(
    [Parameter(Mandatory = $true)]
    [string]$ProfileSource
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ProfileSource)) {
    throw "PowerShell profile source path was not provided."
}

function Normalize-Path {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $null
    }

    $candidate = $Path.Trim()
    if ($candidate.StartsWith('\\??\\')) {
        $candidate = $candidate.Substring(4)
    }

    try {
        $resolved = Resolve-Path -LiteralPath $candidate -ErrorAction Stop |
            Select-Object -First 1 -ExpandProperty ProviderPath
        return $resolved.TrimEnd('\\')
    }
    catch {
        return ([System.IO.Path]::GetFullPath($candidate)).TrimEnd('\\')
    }
}

function Test-IsIntendedProfileLink {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,
        [Parameter(Mandatory = $true)]
        [string]$SourcePath
    )

    $existing = Get-Item -LiteralPath $TargetPath -Force

    # Handle symbolic links where Target metadata is available.
    $linkType = if ($existing.PSObject.Properties.Match('LinkType').Count -gt 0) { $existing.LinkType } else { $null }
    $linkTarget = if ($existing.PSObject.Properties.Match('Target').Count -gt 0) { $existing.Target } else { $null }
    if ($linkTarget -is [System.Array]) {
        $linkTarget = $linkTarget | Select-Object -First 1
    }

    if ($linkType -eq 'SymbolicLink' -and $linkTarget) {
        $normalizedLinkTarget = Normalize-Path -Path $linkTarget
        if ($normalizedLinkTarget -and $normalizedLinkTarget -ieq $SourcePath) {
            return $true
        }
    }

    # Handle hard links (common fallback on Windows PowerShell) via fsutil output.
    if (Get-Command fsutil.exe -ErrorAction SilentlyContinue) {
        $hardLinks = & fsutil.exe hardlink list $TargetPath 2>$null
        if ($LASTEXITCODE -eq 0 -and $hardLinks) {
            $targetRoot = [System.IO.Path]::GetPathRoot($TargetPath)
            foreach ($entry in $hardLinks) {
                if ([string]::IsNullOrWhiteSpace($entry)) {
                    continue
                }

                $candidate = $entry.Trim()
                if ($candidate.StartsWith('\\??\\')) {
                    $candidate = $candidate.Substring(4)
                }
                if ($candidate -match '^[\\/](?![\\/])' -and $targetRoot) {
                    $candidate = Join-Path $targetRoot $candidate.TrimStart('\', '/')
                }

                $normalizedCandidate = Normalize-Path -Path $candidate
                if ($normalizedCandidate -and $normalizedCandidate -ieq $SourcePath) {
                    return $true
                }
            }
        }
    }

    return $false
}

$NormalizedSource = Normalize-Path -Path $ProfileSource

$Target = $PROFILE
$TargetDirectory = Split-Path -Parent $Target

New-Item -ItemType Directory -Path $TargetDirectory -Force | Out-Null

if (Test-Path -LiteralPath $Target) {
    if (Test-IsIntendedProfileLink -TargetPath $Target -SourcePath $NormalizedSource) {
        return
    }

    $Backup = "$Target.bak"
    Write-Host "PowerShell profile already exists at $Target; backing it up to $Backup."
    Move-Item -LiteralPath $Target -Destination $Backup -Force
}

try {
    New-Item -ItemType SymbolicLink -Path $Target -Target $ProfileSource -Force | Out-Null
}
catch {
    New-Item -ItemType HardLink -Path $Target -Target $ProfileSource -Force | Out-Null
}
