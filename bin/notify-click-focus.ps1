Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic

$message = $env:NOTIFY_MESSAGE
$targets = @()

if ($env:TERM_PROGRAM -eq 'vscode') {
  $targets += 'Visual Studio Code'
}

if (-not [string]::IsNullOrEmpty($env:WT_SESSION)) {
  $targets += 'Windows Terminal'
}

# Keep a fallback list so click-to-focus still works if environment detection is incomplete.
$targets += @('Windows Terminal', 'Visual Studio Code')
$targetPayload = ($targets | Select-Object -Unique) -join "`n"

$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon = [System.Drawing.SystemIcons]::Information
$notifyIcon.Visible = $true

$script:clicked = $false
$subscription = Register-ObjectEvent -InputObject $notifyIcon -EventName BalloonTipClicked -MessageData $targetPayload -Action {
  $names = $event.MessageData -split "`n"
  foreach ($name in $names) {
    try {
      if ([Microsoft.VisualBasic.Interaction]::AppActivate($name)) {
        break
      }
    } catch {
    }
  }
  $script:clicked = $true
}

$notifyIcon.ShowBalloonTip(5000, 'Shell Notify', $message, [System.Windows.Forms.ToolTipIcon]::Info)

$deadline = (Get-Date).AddSeconds(6)
while ((Get-Date) -lt $deadline -and -not $script:clicked) {
  [System.Windows.Forms.Application]::DoEvents()
  Start-Sleep -Milliseconds 100
}

if ($subscription) {
  Unregister-Event -SubscriptionId $subscription.Id -ErrorAction SilentlyContinue
  Remove-Job -Id $subscription.Id -Force -ErrorAction SilentlyContinue
}

$notifyIcon.Dispose()
