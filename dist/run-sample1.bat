@echo off
set TCL_LIBRARY=%~dp0lib\tcl9.0
set TK_LIBRARY=%~dp0lib\tk9.0
set LUA_CPATH=%~dp0?.dll;%LUA_CPATH%
%~dp0lua.exe samples\sample_1.lua
