@echo off
cd ../../

:: Build the client
taskkill /IM "FlatClient.exe" /F
godot.windows.opt.tools.64.exe --export-debug "Client Flat - Windows Desktop" export/client/flat/windows/FlatClient.exe

:: Build the server
taskkill /IM "Server.exe" /F
godot.windows.opt.tools.64.exe --export-debug "Server - Windows Desktop" export/server/Server.exe

:: Run a server with connected clients
cd extras/scripts
start cmd /k run_all.bat