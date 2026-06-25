param(
    [Parameter(Mandatory=$true, Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$Text
)

Import-Module BurntToast -ErrorAction SilentlyContinue
if (-not (Get-Module -Name BurntToast)) {
    Write-Error "BurntToast module is not available. Install it with: Install-Module -Name BurntToast"
    exit 1
}

# Find the window handle of the calling process
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class NotifyWin32 {
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")]
    public static extern bool IsIconic(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")]
    public static extern bool IsWindow(IntPtr hWnd);
}
"@ -ErrorAction SilentlyContinue

$SW_RESTORE = 9
$hwnd = [IntPtr]::Zero
$processId = $PID

# Start with parent of current PowerShell process
$currentProcess = Get-Process -Id $PID -ErrorAction SilentlyContinue
if ($currentProcess.Parent) {
    $processId = $currentProcess.Parent.Id
}

# Walk up the parent chain to find a process with a main window
while ($processId -gt 0) {
    $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
    if (-not $process) { break }

    if ($process.MainWindowHandle -ne [IntPtr]::Zero) {
        $hwnd = $process.MainWindowHandle
        break
    }

    $parentId = (Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $processId" -ErrorAction SilentlyContinue).ParentProcessId
    if (-not $parentId -or $parentId -eq $processId) { break }
    $processId = $parentId
}

$OnClickScript = {
    if ($hwnd -ne [IntPtr]::Zero -and [NotifyWin32]::IsWindow($hwnd)) {
        try {
            if ([NotifyWin32]::IsIconic($hwnd)) {
                [NotifyWin32]::ShowWindow($hwnd, $SW_RESTORE) | Out-Null
                Start-Sleep -Milliseconds 100
            }
            [NotifyWin32]::SetForegroundWindow($hwnd) | Out-Null
        }
        catch {
            # Silently fail
        }
    }
}

New-BurntToastNotification -Text $Text -ActivatedAction $OnClickScript
