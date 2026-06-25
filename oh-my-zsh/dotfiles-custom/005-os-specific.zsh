if (( IS_WINDOWS_NATIVE || IS_WSL )); then
  if powershell.exe -Command "if(-Not (Get-Command Get-StoredCredential -errorAction SilentlyContinue)) { exit 1; }" &> /dev/null; then
    alias get-cred-password='f () { powershell.exe -Command "\$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR((Get-StoredCredential -Target LegacyGeneric:target=$1).Password); [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(\$BSTR); [Runtime.InteropServices.Marshal]::ZeroFreeBSTR(\$BSTR)" | dos2unix  }; f'
  else
    alias get-cred-password='echo "Get-StoredCredential not found, run 'Install-Module CredentialManager' in an elevated PowerShell session to install it"'
  fi
else
  case "$OSTYPE" in
    darwin*)
      alias get-cred-password='security find-generic-password -w -a $LOGNAME -s'
      ;;
    *)
      alias get-cred-password='echo "Unsupported OS"'
      ;;
  esac
fi

notify() {
  if (( IS_WINDOWS_NATIVE || IS_WSL )); then
    local notify_message="$1"
    local notify_script="${DOTFILES_DIR:-$HOME/.dotfiles}/bin/notify-click-focus.ps1"
    local notify_message_ps="${notify_message//\'/\'\'}"
    if [[ -f "$notify_script" ]]; then
      local notify_script_win="$notify_script"
      if (( IS_WSL )); then
        notify_script_win="$(wslpath -w "$notify_script")"
      elif command -v cygpath >/dev/null 2>&1; then
        notify_script_win="$(cygpath -w "$notify_script")"
      fi
      local notify_script_win_ps="${notify_script_win//\'/\'\'}"
      powershell.exe -NoProfile -NonInteractive -Command "\$env:NOTIFY_MESSAGE = '$notify_message_ps'; Invoke-Expression (Get-Content -Raw -LiteralPath '$notify_script_win_ps')" 2>/dev/null &!
    else
      powershell.exe -NoProfile -NonInteractive -Command "Add-Type -AssemblyName System.Windows.Forms; \$notifyIcon = New-Object System.Windows.Forms.NotifyIcon; \$notifyIcon.Icon = [System.Drawing.SystemIcons]::Information; \$notifyIcon.Visible = \$true; \$notifyIcon.ShowBalloonTip(5000, 'Shell Notify', '$notify_message_ps', [System.Windows.Forms.ToolTipIcon]::Info)" 2>/dev/null &!
    fi
  else
    notify-send "$1"
  fi
}
