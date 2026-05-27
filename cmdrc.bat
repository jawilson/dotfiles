@echo off
:: for /F will launch a new instance of cmd so we create a guard to prevent an infnite loop
where fnm >nul 2>nul && if not defined FNM_AUTORUN_GUARD (
    set "FNM_AUTORUN_GUARD=AutorunGuard"
    FOR /f "tokens=*" %%z IN ('fnm env --use-on-cd') DO CALL %%z
)
