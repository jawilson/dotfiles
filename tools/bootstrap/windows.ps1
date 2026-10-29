# Imperative Windows setup, run as the `bootstrap` task from mise.windows.toml.
# Designed to be rerun: installs check first; the cmd AutoRun value is simply set again.
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

# ~/src, as [bootstrap.directories] creates on the other platforms.
New-Item -ItemType Directory -Force -Path (Join-Path $env:USERPROFILE 'src') | Out-Null

# MSYS2: use %USERPROFILE% as HOME (where mise links the dotfiles), and install zsh.
function Get-MSYS2 {
  if (Test-Path "C:\msys64\usr\bin\bash.exe") { return "C:\msys64" }
  if (Test-Path "D:\msys64\usr\bin\bash.exe") { return "D:\msys64" }

  $shortcuts = Get-ChildItem -Recurse "$env:AppData\Microsoft\Windows\Start Menu" -Include *.lnk
  $shell = New-Object -ComObject WScript.Shell
  foreach ($shortcut in $shortcuts) {
    $workingDirectory = $shell.CreateShortcut($shortcut).WorkingDirectory
    if ($workingDirectory -clike "*\msys64") { return $workingDirectory }
  }
}

$msys = Get-MSYS2
if (-not $msys -or -not (Test-Path (Join-Path $msys 'usr\bin\bash.exe'))) {
  Write-Host "MSYS2 not found, installing via winget..."
  winget install --id MSYS2.MSYS2 -e --accept-source-agreements --accept-package-agreements
  $msys = Get-MSYS2
}
if (-not $msys -or -not (Test-Path (Join-Path $msys 'usr\bin\bash.exe'))) {
  throw "MSYS2 not found after installation; please install MSYS2 at C:\msys64."
}

$msysLauncher = Join-Path $msys 'msys2_shell.cmd'
if (Test-Path $msysLauncher) {
  $launcherContent = Get-Content $msysLauncher
  $updated = $false
  $launcherContent = $launcherContent | ForEach-Object {
    if ($_ -match '^\s*rem\s+set MSYS=winsymlinks:nativestrict\s*$') {
      $updated = $true
      ($_ -replace '^\s*rem\s+', '')
    } else {
      $_
    }
  }
  if ($updated) {
    Set-Content -Path $msysLauncher -Value $launcherContent
  }
}
$nsswitch = Join-Path $msys 'etc\nsswitch.conf'
$content = @(Get-Content $nsswitch)
if ($content -notcontains 'db_home: windows') {
  $content = @($content | Where-Object { $_ -notmatch '^db_home:' }) + 'db_home: windows'
  Set-Content -Path $nsswitch -Value $content
}
& (Join-Path $msys 'usr\bin\bash.exe') -lc 'pacman --noconfirm -S --needed zsh winpty tree gnupg curl'  # the shell runs in MSYS2
if ($LASTEXITCODE -ne 0) { throw "MSYS2 package installation failed (exit $LASTEXITCODE); fix the pacman error above and rerun mise bootstrap." }

# PowerShell profiles link to config\powershell\Microsoft.PowerShell_profile.ps1.
$profileSource = Join-Path $repo 'config\powershell\Microsoft.PowerShell_profile.ps1'
$linker = Join-Path $repo 'tools\install\link_powershell_profile.ps1'
foreach ($shell in 'powershell.exe', 'pwsh.exe') {
  if (Get-Command $shell -ErrorAction SilentlyContinue) {
    & $shell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $linker -ProfileSource $profileSource
    if ($LASTEXITCODE -ne 0) { throw "Linking the $shell profile failed (exit $LASTEXITCODE)." }
  }
}

# cmd.exe runs ~/.cmdrc.bat at startup.
reg.exe add 'HKCU\Software\Microsoft\Command Processor' /v AutoRun /t REG_SZ /d "$env:USERPROFILE\.cmdrc.bat" /f | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Setting the cmd AutoRun value failed (exit $LASTEXITCODE)." }

# oh-my-pi (omp): prebuilt binary in %LOCALAPPDATA%\omp; the installer adds that folder to the user PATH.
$ompExe = "$env:LOCALAPPDATA\omp\omp.exe"
if (-not (Get-Command omp -ErrorAction SilentlyContinue) -and -not (Test-Path -LiteralPath $ompExe -PathType Leaf)) {
  & ([scriptblock]::Create((Invoke-RestMethod https://omp.sh/install.ps1))) -Binary
  if (-not (Test-Path -LiteralPath $ompExe -PathType Leaf)) { throw "omp installation did not produce $ompExe." }
}
