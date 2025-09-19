.PHONY: dist clean

# Makefile for LuaTk
TCLTK_DIR ?= tcltk
LUA_DIR ?= lua
OUTPUT_NAME = luatk

# Platform detection and paths
ifeq ($(OS),Windows_NT)
    SO_EXT = dll
    EXE_EXT = .exe
    # Use bundled libraries
    CFLAGS = -std=c99 -Wall -Wextra -O2 \
             -I$(TCLTK_DIR)/include \
             -I$(LUA_DIR)/include
    LDFLAGS = -L$(TCLTK_DIR)/lib -L$(LUA_DIR)/lib \
              -ltcl90 -ltcl9tk90 -llua \
              -shared "-Wl,--export-all-symbols"
else
    SO_EXT = so
    EXE_EXT =
    # Use system libraries
    CFLAGS = -std=c99 -Wall -Wextra -O2 -fPIC \
             $(shell pkg-config --cflags tcl tk lua 2>/dev/null || echo "-I/usr/include/tcl -I/usr/include/lua5.4")
    LDFLAGS = $(shell pkg-config --libs tcl tk lua 2>/dev/null || echo "-ltcl -ltk -llua5.4") \
              -shared
endif

CC = gcc
SOURCES = luatk.c
OUTPUT = $(OUTPUT_NAME).$(SO_EXT)

# Build luatk module
$(OUTPUT): $(SOURCES)
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

# Distribution target
dist: $(OUTPUT)
ifeq ($(OS),Windows_NT)
	@echo Creating Windows distribution...
	@if not exist dist mkdir dist
	@if not exist dist\lib mkdir dist\lib
	@if not exist dist\lib\tcl9 mkdir dist\lib\tcl9
	@if not exist dist\lib\tcl9.0 mkdir dist\lib\tcl9.0
	@if not exist dist\lib\tk9.0 mkdir dist\lib\tk9.0
	@if not exist dist\samples mkdir dist\samples
	@copy $(OUTPUT) dist\ >nul
	@copy $(TCLTK_DIR)\bin\*.dll dist\ >nul 2>nul
	@copy $(LUA_DIR)\bin\*.dll dist\ >nul 2>nul
	@copy $(LUA_DIR)\bin\lua$(EXE_EXT) dist\ >nul
	@xcopy $(TCLTK_DIR)\lib\tcl9 dist\lib\tcl9\ /E /I /Y /Q >nul 2>nul
	@xcopy $(TCLTK_DIR)\lib\tcl9.0 dist\lib\tcl9.0\ /E /I /Y /Q >nul 2>nul
	@xcopy $(TCLTK_DIR)\lib\tk9.0 dist\lib\tk9.0\ /E /I /Y /Q >nul 2>nul
	@copy samples\*.lua dist\samples\ >nul 2>nul
	@echo @echo off> dist\run-luatk.bat
	@echo REM LuaTk Launcher - Sets up environment and runs Lua scripts>> dist\run-luatk.bat
	@echo set TCL_LIBRARY=%%~dp0lib\tcl9.0>> dist\run-luatk.bat
	@echo set TK_LIBRARY=%%~dp0lib\tk9.0>> dist\run-luatk.bat
	@echo set LUA_CPATH=%%~dp0?.dll;%%LUA_CPATH%%>> dist\run-luatk.bat
	@echo.>> dist\run-luatk.bat
	@echo if "%%1"=="" ^(>> dist\run-luatk.bat
	@echo     echo Usage: run-luatk.bat script.lua>> dist\run-luatk.bat
	@echo     echo Example: run-luatk.bat test.lua>> dist\run-luatk.bat
	@echo     pause>> dist\run-luatk.bat
	@echo     exit /b 1>> dist\run-luatk.bat
	@echo ^)>> dist\run-luatk.bat
	@echo.>> dist\run-luatk.bat
	@echo if not exist "%%1" ^(>> dist\run-luatk.bat
	@echo     echo Error: Script '%%1' not found>> dist\run-luatk.bat
	@echo     pause>> dist\run-luatk.bat
	@echo     exit /b 1>> dist\run-luatk.bat
	@echo ^)>> dist\run-luatk.bat
	@echo.>> dist\run-luatk.bat
	@echo echo Running: %%1>> dist\run-luatk.bat
	@echo %%~dp0lua.exe "%%1">> dist\run-luatk.bat
	@echo @echo off> dist\run-sample1.bat
	@echo set TCL_LIBRARY=%%~dp0lib\tcl9.0>> dist\run-sample1.bat
	@echo set TK_LIBRARY=%%~dp0lib\tk9.0>> dist\run-sample1.bat
	@echo set LUA_CPATH=%%~dp0?.dll;%%LUA_CPATH%%>> dist\run-sample1.bat
	@echo %%~dp0lua.exe samples\sample_1.lua>> dist\run-sample1.bat
	@echo @echo off> dist\run-sample2.bat
	@echo set TCL_LIBRARY=%%~dp0lib\tcl9.0>> dist\run-sample2.bat
	@echo set TK_LIBRARY=%%~dp0lib\tk9.0>> dist\run-sample2.bat
	@echo set LUA_CPATH=%%~dp0?.dll;%%LUA_CPATH%%>> dist\run-sample2.bat
	@echo %%~dp0lua.exe samples\sample_2.lua>> dist\run-sample2.bat
	@echo LuaTk Distribution> dist\README.txt
	@echo ==================>> dist\README.txt
	@echo.>> dist\README.txt
	@echo Self-contained Windows distribution with all dependencies.>> dist\README.txt
	@echo.>> dist\README.txt
	@echo Usage:>> dist\README.txt
	@echo   run-sample1.bat - Simple test>> dist\README.txt
	@echo   run-sample2.bat - Comprehensive demo>> dist\README.txt
	@echo   run-luatk.bat script.lua - Run custom script>> dist\README.txt
	@del $(OUTPUT) >nul 2>nul
	@echo Windows distribution complete: dist/
else
	@echo Creating Linux distribution...
	@mkdir -p dist/samples
	@cp $(OUTPUT) dist/
	@cp samples/*.lua dist/samples/ 2>/dev/null || true
	@echo '#!/bin/bash' > dist/run-luatk.sh
	@echo 'export LUA_CPATH="$$(dirname "$$0")/?.so:$$LUA_CPATH"' >> dist/run-luatk.sh
	@echo 'if [ -z "$$1" ]; then' >> dist/run-luatk.sh
	@echo '    echo "Usage: ./run-luatk.sh script.lua"' >> dist/run-luatk.sh
	@echo '    exit 1' >> dist/run-luatk.sh
	@echo 'fi' >> dist/run-luatk.sh
	@echo 'lua "$$1"' >> dist/run-luatk.sh
	@chmod +x dist/run-luatk.sh
	@echo '#!/bin/bash' > dist/run-sample1.sh
	@echo 'export LUA_CPATH="$$(dirname "$$0")/?.so:$$LUA_CPATH"' >> dist/run-sample1.sh
	@echo 'lua samples/sample_1.lua' >> dist/run-sample1.sh
	@chmod +x dist/run-sample1.sh
	@echo '#!/bin/bash' > dist/run-sample2.sh
	@echo 'export LUA_CPATH="$$(dirname "$$0")/?.so:$$LUA_CPATH"' >> dist/run-sample2.sh
	@echo 'lua samples/sample_2.lua' >> dist/run-sample2.sh
	@chmod +x dist/run-sample2.sh
	@echo 'LuaTk Distribution for Linux' > dist/README.txt
	@echo '============================' >> dist/README.txt
	@echo '' >> dist/README.txt
	@echo 'Prerequisites:' >> dist/README.txt
	@echo '  sudo apt install tcl-dev tk-dev lua5.4-dev  # Ubuntu/Debian' >> dist/README.txt
	@echo '  sudo dnf install tcl-devel tk-devel lua-devel  # Fedora' >> dist/README.txt
	@echo '' >> dist/README.txt
	@echo 'Usage:' >> dist/README.txt
	@echo '  ./run-sample1.sh     - Simple test' >> dist/README.txt
	@echo '  ./run-sample2.sh     - Comprehensive demo' >> dist/README.txt
	@echo '  ./run-luatk.sh script.lua - Run custom script' >> dist/README.txt
	@echo '' >> dist/README.txt
	@echo 'Note: Uses system-installed Tcl/Tk and Lua libraries.' >> dist/README.txt
	@rm -f $(OUTPUT)
	@echo Linux distribution complete: dist/
	@echo ""
	@echo "Install dependencies first:"
	@echo "  sudo apt install tcl-dev tk-dev lua5.4-dev"
endif

clean:
ifeq ($(OS),Windows_NT)
	@if exist $(OUTPUT) del $(OUTPUT)
	@if exist dist rmdir /S /Q dist
else
	@rm -f $(OUTPUT) *.o
	@rm -rf dist
endif