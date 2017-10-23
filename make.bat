@ECHO off
@SET LIT_VERSION=3.5.4

IF NOT "x%1" == "x" GOTO :%1

:luver
IF NOT EXIST lit.exe CALL make.bat lit
ECHO "Building luver"
lit.exe make
if %errorlevel% neq 0 goto error
GOTO :end

:lit
ECHO "Building lit"
PowerShell -NoProfile -ExecutionPolicy unrestricted -Command "iex ((new-object net.webclient).DownloadString('https://github.com/luvit/lit/raw/%LIT_VERSION%/get-lit.ps1'))"
GOTO :end

:test
IF NOT EXIST luver.exe CALL make.bat luver
ECHO "Testing luver"
luver.exe tests\run.lua
if %errorlevel% neq 0 goto error
GOTO :end

:clean
IF EXIST luver.exe DEL /F /Q luver.exe
IF EXIST lit.exe DEL /F /Q lit.exe

:error
exit /b %errorlevel%

:end
