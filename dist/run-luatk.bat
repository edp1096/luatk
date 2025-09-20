@echo off
REM LuaTk Launcher - Sets up environment and runs Lua scripts
set TCL_LIBRARY=%~dp0lib\tcl9.0
set TK_LIBRARY=%~dp0lib\tk9.0
set LUA_CPATH=%~dp0?.dll;%LUA_CPATH%

if "%1"=="" (
    echo Usage: run-luatk.bat script.lua
    echo Example: run-luatk.bat test.lua
    pause
    exit /b 1
)

if not exist "%1" (
    echo Error: Script '%1' not found
    pause
    exit /b 1
)

echo Running: %1
%~dp0lua.exe "%1"
