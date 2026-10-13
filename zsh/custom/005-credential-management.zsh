# Bitwarden handler
_get-cred-password-bitwarden() {
  bw get password "$1" 2>/dev/null
}

# 1Password handler
_get-cred-password-1password() {
  op read "op://default/$1/password" 2>/dev/null
}

# Windows/WSL handler
_get-cred-password-windows() {
  powershell.exe -Command "\$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR((Get-StoredCredential -Target LegacyGeneric:target=$1).Password); [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(\$BSTR); [Runtime.InteropServices.Marshal]::ZeroFreeBSTR(\$BSTR)" | dos2unix
}

# macOS Keychain handler
_get-cred-password-keychain() {
  security find-generic-password -w -a "$LOGNAME" -s "$1" 2>/dev/null
}

# Initialize handler on first call
get-cred-password() {
  local credential_name="$1"
  
  if [[ -z "$credential_name" ]]; then
    echo "Usage: get-cred-password <credential-name>"
    return 1
  fi

  if (( IS_WINDOWS_NATIVE || IS_WSL )); then
    if powershell.exe -Command "if(-Not (Get-Command Get-StoredCredential -errorAction SilentlyContinue)) { exit 1; }" &> /dev/null; then
      eval "get-cred-password() { _get-cred-password-windows \"\$@\"; }"
      _get-cred-password-windows "$credential_name"
      return $?
    else
      echo "Error: No credential tool found. Install Bitwarden, 1Password CLI, or CredentialManager PowerShell module." >&2
      return 1
    fi
  else
    case "$OSTYPE" in
      darwin*)
        eval "get-cred-password() { _get-cred-password-keychain \"\$@\"; }"
        _get-cred-password-keychain "$credential_name"
        return $?
        ;;
      linux*)
        echo "Error: No credential tool found. Install Bitwarden or 1Password CLI for credential management." >&2
        return 1
        ;;
      *)
        echo "Error: Unsupported OS and no credential tool available." >&2
        return 1
        ;;
    esac
  fi
}
