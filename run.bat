@echo off

SET masm="C:\masm32\lib"
SET dir="D:\coal\Rapid-Roll"
SET lib=%dir%\lib
SET inc=%dir%\include

SET filename=%1
SET filenameObj=%filename:asm=obj%
SET fileExe=%filename:.asm=%
@REM SET ext=%filename:~-3%

ml /nologo /c /coff /WX /Cp /I%inc% %filename% 
if %errorlevel%==0 ml /nologo /c /coff /WX /Cp /I%inc% %lib%\Libs.asm
if %errorlevel%==0 link /nologo /SUBSYSTEM:CONSOLE %filenameObj% Libs.obj %masm%\kernel32.lib %masm%\user32.lib %masm%\irvine32.lib
if %errorlevel%==0 start %fileExe%