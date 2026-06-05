#Requires -RunAsAdministrator

# Disable progress bars, which are super slow especially Invoke-WebRequest
# which updates the progress bar for each byte
$ProgressPreference = 'SilentlyContinue'

$git_req = '2.0'
$python_req = '3.10'

Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

function Get-MSYS2 {
  # Handle some default paths first. This also works if a user installed a
  # system-wide instance of msys64 in these locations, and in that case the
  # shortcuts won't be found by the code in the rest of this function.
  if (Test-Path "C:\msys64") {
    return "C:\msys64"
  }
  if (Test-Path "D:\msys64") {
    return "D:\msys64"
  }

  $Shortcuts = Get-ChildItem -Recurse "$env:AppData\Microsoft\Windows\Start Menu" -Include *.lnk
  $Shell = New-Object -ComObject WScript.Shell
  foreach ($Shortcut in $Shortcuts) {
    $WD = $Shell.CreateShortcut($Shortcut).WorkingDirectory
    if ($WD -clike "*msys64") {
      return $WD
    }
  }
}

function Is-Installed($Name) {
  $Shortcuts = Get-ChildItem -Recurse "$env:AppData\Microsoft\Windows\Start Menu" -Include *.lnk
  $Shell = New-Object -ComObject WScript.Shell
  foreach ($Shortcut in $Shortcuts) {
    if ($Shortcut -clike "*\$Name.lnk") {
      return $true
    }
    $WD = $Shell.CreateShortcut($Shortcut).TargetPath
    if ($WD -clike "*\$Name.exe") {
      return $true
    }
  }
  return $false
}

function Is-Newer ($Name, $Version) {
  $ErrorActionPreference = 'SilentlyContinue'
  $have = (Get-Command $Name)
  $ErrorActionPreference = 'Continue'
  if (!$have) {
    return $false
  }
  if ($have.Version -ge $Version) {
    return $true
  }

  $have_version = $have.Version.ToString()
  $confirm = Read-Host "$Name version $have_version is too old (need $Version), install a newer version with Choco? [Y/n] "
  if ($confirm -eq 'n') {
    Write-Host "Please upgrade $Name manually before running Cerbero"
    return $true
  }
  return $false
}

$choco_psm = "$env:ProgramData\chocolatey\helpers\chocolateyProfile.psm1"
if (Test-Path $choco_psm) {
  Import-Module $choco_psm
  Update-SessionEnvironment
  Write-Host "Found Chocolatey, upgrading it first"
  choco upgrade -y chocolatey
} else {
  Write-Host "Installing Chocolatey"
  Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
  Import-Module $choco_psm
  Update-SessionEnvironment
}

if (!(Is-Newer 'git' $git_req)) {
  Write-Host "git >= $git_req not found, installing..."
  choco install -y git --params "/NoAutoCrlf /NoCredentialManager /NoShellHereIntegration /NoGuiHereIntegration /NoShellIntegration"
}

if (!(Is-Newer 'py' $python_req)) {
  Write-Host "Python >= $python_req not found, installing..."
  choco install -y python3
}

# https://github.com/chocolatey/choco/issues/3524
if ((Get-Command "wmic.exe" -ErrorAction SilentlyContinue) -eq $null) {
  Write-Host "Windows Management Instrumentation Command-line not found, installing..."
  DISM /Online /Add-Capability /CapabilityName:WMIC~~~~
}

$MSYS2_Dir = (Get-MSYS2)
if (!$MSYS2_Dir) {
  Write-Host "MSYS2 not found, installing..."
  choco install msys2 --params "/InstallDir:C:\msys64"
  $MSYS2_Dir = "C:\msys64"
}

function Enable-MsysNativeSymlinks {
  $Path = "$MSYS2_Dir\msys2_shell.cmd"
  if (!(Test-Path $Path)) {
    return
  }

  $Content = Get-Content $Path
  $Updated = $false
  $Content = $Content | ForEach-Object {
    if ($_ -match '^\s*rem\s+set MSYS=winsymlinks:nativestrict\s*$') {
      $Updated = $true
      ($_ -replace '^\s*rem\s+', '')
    } else {
      $_
    }
  }

  if ($Updated) {
    Set-Content -Path $Path -Value $Content
  }
}
Enable-MsysNativeSymlinks

& $MSYS2_Dir\usr\bin\bash -lc 'pacman -Qq winpty &>/dev/null'
if (!$?) {
  & $MSYS2_Dir\usr\bin\bash -lc 'pacman --noconfirm -S --needed winpty'
}

if ((Get-Command "scoop" -ErrorAction SilentlyContinue) -eq $null) {
  Write-Host "Scoop not found, installing..."
  $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  $args = if ($isAdmin) { "-RunAsAdmin" } else { "" }
  iex "& {$(irm get.scoop.sh)} $args"
}
