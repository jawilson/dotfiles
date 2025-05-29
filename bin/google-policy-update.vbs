Dim WshShell
Set WshShell = CreateObject("WScript.Shell")

Dim success
success = True

Dim regKeys
regKeys = Array( _
  "HKEY_CURRENT_USER\Software\Google\Chrome", _
  "HKEY_CURRENT_USER\Software\Policies\Google\Chrome", _
  "HKEY_LOCAL_MACHINE\Software\Google\Chrome", _
  "HKEY_LOCAL_MACHINE\Software\Policies\Google\Chrome", _
  "HKEY_LOCAL_MACHINE\Software\Policies\Google\Update", _
  "HKEY_LOCAL_MACHINE\Software\WOW6432Node\Google\Enrollment", _
  "HKEY_LOCAL_MACHINE\Software\WOW6432Node\Google\Update\ClientState\{430FD4D0-B729-4F61-AA34-91526481799D}" _
)

For Each key In regKeys
  If RegistryKeyExists(key) Then
    Dim result
    result = WshShell.Run("reg delete " & key & " /f", 0, true)
    If result <> 0 Then
      success = False
    End If
  End If
Next

Function RegistryKeyExists(keyPath)
  On Error Resume Next
  WshShell.RegRead keyPath & "\"
  If Err.Number = 0 Then
    RegistryKeyExists = True
  Else
    RegistryKeyExists = False
  End If
  On Error GoTo 0
End Function

If Not success Then
  WScript.Quit(1)
End If
