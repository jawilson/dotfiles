if (Get-Command mise -ErrorAction SilentlyContinue) {
    mise activate pwsh --shims | Out-String | Invoke-Expression
}
