:: ECHO OFF

REG DELETE HKEY_CURRENT_USER\Software\Policies\Google\Chrome /f
REG DELETE HKEY_LOCAL_MACHINE\Software\Policies\Google\Chrome /f
REG DELETE HKEY_LOCAL_MACHINE\Software\Policies\Google\Update /f
REG DELETE HKEY_LOCAL_MACHINE\Software\Wow6432Node\Policies\Google\Chrome /f
REG DELETE HKEY_LOCAL_MACHINE\Software\WOW6432Node\Google\Update\ClientState\{430FD4D0-B729-4F61-AA34-91526481799D} /f
