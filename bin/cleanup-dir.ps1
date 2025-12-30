param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [int]$Days = 30
)

# Validate that the path exists
if (-not (Test-Path -LiteralPath $Path)) {
    Write-Error "Path '$Path' does not exist."
    exit 1
}

$cutoff = (Get-Date).AddDays(-$Days)

# 1) Delete files (including Hidden/System) older than cutoff
Get-ChildItem -LiteralPath $Path -File -Recurse -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt $cutoff } |
    ForEach-Object {
        try {
            Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop
        } catch { }
    }

# 2) Repeatedly delete empty directories older than cutoff (by CreationTime)
do {
    $dirsDeleted = $false

    Get-ChildItem -LiteralPath $Path -Directory -Recurse -Force -ErrorAction SilentlyContinue -Attributes !ReparsePoint |
        Where-Object {
            ($_.GetFileSystemInfos().Count -eq 0) -and
            ($_.CreationTime -lt $cutoff)
        } |
        ForEach-Object {
            try {
                Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop
                $dirsDeleted = $true
            } catch { }
        }
} while ($dirsDeleted)
