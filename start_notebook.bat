@echo off
setlocal EnableDelayedExpansion

rem ─── CONFIG ───────────────────────────────────────────────────────
set "CONTAINER_NAME=scala-notebook"
rem bind the *folder this script is in* (no trailing back-slash)
set "HOST_NOTEBOOK_DIR=%~dp0"
set "HOST_NOTEBOOK_DIR=%HOST_NOTEBOOK_DIR:~0,-1%"
set "CONTAINER_NOTEBOOK_DIR=/home/jovyan/work"
rem ──────────────────────────────────────────────────────────────────

echo [+] Host folder  : "%HOST_NOTEBOOK_DIR%"
echo [+] Container dir: "%CONTAINER_NOTEBOOK_DIR%"

rem 1. remove any old container so the bind-mount is always correct
docker rm -f %CONTAINER_NAME% >nul 2>&1

rem 2. create a fresh container with the bind-mount
docker run -d --name %CONTAINER_NAME% ^
    -v "%HOST_NOTEBOOK_DIR%:%CONTAINER_NOTEBOOK_DIR%" ^
    -p 8888:8888 almondsh/almond

rem 3. poll Jupyter for its token (up to 120 s)
echo [+] Waiting for Jupyter to report itself …

set "JUPYTER_URL="

for /L %%S in (1,1,120) do (
    for /f "usebackq delims=" %%T in (`
        powershell -NoLogo -NoProfile -Command ^
          "$srv = docker exec --user jovyan %CONTAINER_NAME% jupyter server list --json 2>`$null | ConvertFrom-Json;" ^
          "if ($srv) { $srv.token }"
    `) do (
        set "JUPYTER_URL=http://127.0.0.1:8888/lab?token=%%T"
        goto :OPEN
    )
    timeout /t 1 >nul
)

echo [-] ERROR: Jupyter never answered after 120 s
goto :EOF


:OPEN
echo [+] Opening !JUPYTER_URL!
start "" chrome "!JUPYTER_URL!"
goto :EOF
