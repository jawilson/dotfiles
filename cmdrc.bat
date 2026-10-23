@echo off
:: Put mise's shims (node, npm, ...) on PATH. The guard variable is inherited by child cmd
:: instances, so nested shells do not prepend the directory again.
if exist "%LOCALAPPDATA%\mise\shims" if not defined MISE_SHIMS_AUTORUN_GUARD (
    set "MISE_SHIMS_AUTORUN_GUARD=1"
    set "PATH=%LOCALAPPDATA%\mise\shims;%PATH%"
)
