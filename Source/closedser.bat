@echo off
title Server Advanced Stopper - Forced Focus
setlocal

echo [1] Forcing MsgServer focus and sending kickoutall...

:: Single line PowerShell to restore window, focus it, and type
powershell -ExecutionPolicy Bypass -Command "$p=Get-Process MsgServer -ErrorAction SilentlyContinue; if($p){ $ws=New-Object -ComObject WScript.Shell; $sig='[DllImport(\"user32.dll\")] public static extern bool ShowWindow(IntPtr h, int n); [DllImport(\"user32.dll\")] public static extern bool SetForegroundWindow(IntPtr h);'; $t=Add-Type -MemberDefinition $sig -Name W -Namespace Win32 -PassThru; $h=$p.MainWindowHandle; $t::ShowWindow($h, 9); $t::SetForegroundWindow($h); Start-Sleep -m 800; $ws.SendKeys('kickoutall{ENTER}'); echo '-> Forced focus and command sent!' } else { echo '-> MsgServer not found!' }"

echo.
echo [2] Waiting for player disconnection...
timeout /t 2 >nul

echo [3] Closing servers gracefully (Standard Shutdown)...
taskkill /im MsgServer.exe /t 2>nul
taskkill /im NpcServer.exe /t 2>nul

echo Waiting 5 seconds for database commit...
timeout /t 5 /nobreak

echo [4] Final check (Force closing remaining processes)...
taskkill /f /im NpcServer.exe /t 2>nul
taskkill /f /im MsgServer.exe /t 2>nul

echo.
echo [OK] All processes terminated successfully.
exit