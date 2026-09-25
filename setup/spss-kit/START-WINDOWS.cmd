@echo off
setlocal
set "KIT_ROOT=%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%KIT_ROOT%CONFIGURE-WINDOWS.ps1" -Root "%KIT_ROOT%"
if errorlevel 1 (
  echo The SPSS kit could not be prepared. No chapter file was opened.
  pause
  exit /b 1
)
echo Opening the setup check in SPSS. Choose Run All in the syntax window.
start "" "%KIT_ROOT%spss\00-CHECK-SETUP.sps"
if errorlevel 1 (
  echo Open spss\00-CHECK-SETUP.sps from inside SPSS and choose Run All.
  pause
)
