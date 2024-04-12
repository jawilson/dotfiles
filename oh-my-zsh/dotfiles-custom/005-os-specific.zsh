if [[ "$OSTYPE" == "msys" || -e "/proc/sys/fs/binfmt_misc/WSLInterop" ]]; then
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
      alias get-password='echo "Unsupported OS"'
      ;;
  esac
fi
