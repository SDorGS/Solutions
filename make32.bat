@echo off
setlocal enabledelayedexpansion

:: Prompt user to input the ASM file name or path
echo Please enter the full path of the ASM file (including extension) or just the filename:
set /p filename=

:: Remove any surrounding quotes from the filename
set filename=%filename:"=%

:: Add .asm extension if not present
if not "%filename:~-4%"==".asm" set filename=%filename%.asm

echo Using ASM file: %filename%

:: Set INCLUDE and LIB directories
set INCLUDE_DIR=C:\masm32
set LIB_DIR=C:\masm32\lib

:: Determine the full path of the ASM file
if "%filename:~1,1%"==":" (
    set fullpath=%filename%
) else (
    set fullpath=%cd%\%filename%
)

:: Extract the directory of the ASM file
for %%i in ("%fullpath%") do set asm_directory=%%~dpi

:: Check if the file exists
if not exist "%fullpath%" (
    echo [ERROR] ASM file "%fullpath%" not found. Exiting.
    exit /b
)

:: Update INCLUDE directive in the ASM file
powershell -Command "(Get-Content '%fullpath%') -replace 'INCLUDE Irvine32.inc', 'INCLUDE C:\\masm32\\Irvine32.inc' | Set-Content '%fullpath%'"
if %errorlevel% neq 0 (
    echo [ERROR] Failed to update INCLUDE directive. Exiting.
    exit /b
)

:: Extract the filename without extension
for %%A in ("%fullpath%") do set asm_name=%%~nA

:: Assemble the ASM file into an object file
echo Assembling the ASM file...
"C:\masm32\bin\ml.exe" /c /coff "%fullpath%"
if %errorlevel% neq 0 (
    echo [ERROR] Error assembling %filename%. Exiting.
    exit /b
)

:: Ensure the object file exists
if not exist "%cd%\%asm_name%.obj" (
    echo [ERROR] Object file not found. Exiting.
    exit /b
)

:: Copy the object file to the ASM directory if different
if /i not "%cd%\%asm_name%.obj"=="%asm_directory%%asm_name%.obj" (
    echo Copying the object file...
    copy "%cd%\%asm_name%.obj" "%asm_directory%%asm_name%.obj"
    if %errorlevel% neq 0 (
        echo [ERROR] Error copying the object file. Exiting.
        exit /b
    )
) else (
    echo Object file is already in the target directory. Skipping copy.
)

:: Prompt user for custom libraries (optional)
set lib_files=
echo Enter custom library files to link (separate multiple with spaces, press Enter to skip):
set /p lib_files=

:: Normalize library files: Add .lib extension if missing and handle paths
set processed_libs=
for %%L in (%lib_files%) do (
    if "%%~xL"==".lib" (
        set processed_libs=!processed_libs! "%%L"
    ) else (
        if exist "%asm_directory%%%L.lib" (
            set processed_libs=!processed_libs! "%asm_directory%%%L.lib"
        ) else (
            set processed_libs=!processed_libs! "%%L.lib"
        )
    )
)

:: Link the object file into an executable
echo Linking the object file into an executable...
link /subsystem:console "%asm_directory%%asm_name%.obj" /LIBPATH:%LIB_DIR% !processed_libs! /OUT:"%asm_directory%%asm_name%.exe"
if %errorlevel% neq 0 (
    echo [ERROR] Error linking the object file. Exiting.
    exit /b
)

echo Assembling and linking complete.
echo Executable created: %asm_directory%%asm_name%.exe
pause
