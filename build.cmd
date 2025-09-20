@echo off
echo Building LuaTk...

REM Compile LuaTk DLL
gcc -std=c99 -Wall -Wextra -O2 ^
    -Itcltk\include -Ilua\include ^
    -o luatk.dll luatk.c ^
    -Ltcltk\lib -Llua\lib ^
    -ltcl90 -ltcl9tk90 -llua ^
    -shared -Wl,--export-all-symbols

if errorlevel 1 (
    echo Build failed!
    exit /b 1
)

echo Creating dist folder...
mkdir dist 2>nul
mkdir dist\lib 2>nul

echo Copying LuaTk module and DLLs...
copy luatk.dll dist\ >nul
copy tcltk\bin\*.dll dist\ >nul
copy lua\bin\*.dll dist\ >nul

echo Copying Lua executable...
copy lua\bin\lua.exe dist\ >nul

echo Copying Tcl/Tk libraries...
@REM xcopy tcltk\lib\tcl9 dist\lib\tcl9\ /E /I /Y /Q 2>nul
xcopy tcltk\lib\tcl9.0 dist\lib\tcl9.0\ /E /I /Y /Q >nul
xcopy tcltk\lib\tk9.0 dist\lib\tk9.0\ /E /I /Y /Q >nul

echo Copying sample scripts...
mkdir dist\samples 2>nul
copy samples\sample*.lua dist\samples\ >nul 2>nul

echo Creating launcher script...
(
echo @echo off
echo REM LuaTk Launcher - Sets up environment and runs Lua scripts
echo set TCL_LIBRARY=%%~dp0lib\tcl9.0
echo set TK_LIBRARY=%%~dp0lib\tk9.0
echo set LUA_CPATH=%%~dp0?.dll;%%LUA_CPATH%%
echo.
echo if "%%1"=="" (
echo     echo Usage: run-luatk.bat script.lua
echo     echo Example: run-luatk.bat test.lua
echo     pause
echo     exit /b 1
echo ^)
echo.
echo if not exist "%%1" (
echo     echo Error: Script '%%1' not found
echo     pause
echo     exit /b 1
echo ^)
echo.
echo echo Running: %%1
echo %%~dp0lua.exe "%%1"
) > dist\run-luatk.bat

echo Creating direct test launchers...
(
echo @echo off
echo set TCL_LIBRARY=%%~dp0lib\tcl9.0
echo set TK_LIBRARY=%%~dp0lib\tk9.0
echo set LUA_CPATH=%%~dp0?.dll;%%LUA_CPATH%%
echo %%~dp0lua.exe samples\sample_1.lua
) > dist\run-sample1.bat

echo Creating README...
(
echo LuaTk Distribution
echo ==================
echo.
echo This folder contains a complete LuaTk environment:
echo.
echo Files:
echo   lua.exe              - Lua interpreter
echo   luatk.dll            - LuaTk module
echo   *.dll                - Required DLLs (Tcl/Tk, Lua)
echo   lib/tcl9.0/          - Tcl library scripts
echo   lib/tk9.0/           - Tk library scripts
echo   samples/             - Example scripts
echo.
echo Sample Scripts:
echo   samples/sample_1.lua - Simple test
echo.
echo Usage:
echo   run-luatk.bat script.lua    - Run any Lua script with LuaTk
echo   run-sample1.bat              - Run simple sample
echo.
echo Examples:
echo   run-luatk.bat samples\sample_1.lua
echo   run-luatk.bat your-app.lua
echo.
echo Requirements:
echo   None - This is a self-contained distribution
echo.
echo Note: All scripts set up the necessary environment variables
echo automatically. No system installation required.
) > dist\README.txt

echo Cleaning up build artifacts...
del luatk.dll >nul 2>nul

echo.
echo ========================================
echo Build Complete!
echo ========================================
echo.
echo Distribution created in: dist\
echo.
echo Quick Test:
echo   cd dist
echo   run-sample1.bat
echo.
echo Custom Scripts:
echo   cd dist
echo   run-luatk.bat your-script.lua
echo.
echo All files are self-contained in the dist folder.
echo You can copy this folder to any Windows machine.
echo ========================================