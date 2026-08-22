@echo off
setlocal enabledelayedexpansion
title LookUp Astrophotography AI Launcher

echo =======================================================
echo           LOOKUP AI AGENT SYSTEM LAUNCHER              
echo =======================================================
echo.

:: 1. CHECK & AUTO-INSTALL PYTHON
echo [1/4] Checking Python Installation...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] Python not found! Starting automatic installation...
    echo Downloading Python 3.11 Installer...
    powershell -Command "Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe' -OutFile '%TEMP%\python_installer.exe'"
    if exist "%TEMP%\python_installer.exe" (
        echo Installing Python 3.11 and adding to PATH...
        "%TEMP%\python_installer.exe" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
        del "%TEMP%\python_installer.exe"
        set "PATH=%ProgramFiles%\Python311;%ProgramFiles%\Python311\Scripts;%PATH%"
        echo [OK] Python successfully installed.
    ) else (
        echo [ERROR] Failed to download Python installer!
        pause
        exit /b 1
    )
) else (
    echo [OK] Python detected.
)
echo.

:: 2. CHECK & AUTO-INSTALL OLLAMA
echo [2/4] Checking Ollama Installation...
set "OLLAMA_BIN="
set "OLLAMA_DIR="

where ollama >nul 2>&1
if %errorlevel% equ 0 (
    set "OLLAMA_BIN=ollama"
) else (
    for %%I in (
        "%USERPROFILE%\.ollama\bin\ollama.exe"
        "%LOCALAPPDATA%\Programs\Ollama\ollama.exe"
        "%ProgramFiles%\Ollama\ollama.exe"
        "%ProgramFiles(x86)%\Ollama\ollama.exe"
    ) do (
        if exist "%%~I" (
            set "OLLAMA_BIN=%%~I"
            set "OLLAMA_DIR=%%~dpI"
        )
    )
)

if "%OLLAMA_BIN%"=="" (
    echo [WARNING] Ollama command not detected! Starting automatic installation...
    powershell -Command "Invoke-WebRequest -Uri 'https://ollama.com/download/OllamaSetup.exe' -OutFile '%TEMP%\OllamaSetup.exe'"
    if exist "%TEMP%\OllamaSetup.exe" (
        echo Installing Ollama...
        "%TEMP%\OllamaSetup.exe" /DIR="%LOCALAPPDATA%\Programs\Ollama" /SILENT
        del "%TEMP%\OllamaSetup.exe"
        set "OLLAMA_BIN=%LOCALAPPDATA%\Programs\Ollama\ollama.exe"
        set "OLLAMA_DIR=%LOCALAPPDATA%\Programs\Ollama"
        echo [OK] Ollama successfully installed.
    ) else (
        echo [ERROR] Failed to download Ollama setup!
        pause
        exit /b 1
    )
)

if not "%OLLAMA_DIR%"=="" (
    set "PATH=%PATH%;%OLLAMA_DIR%"
)

where curl >nul 2>&1
if %errorlevel% equ 0 (
    curl -s http://localhost:11434/api/tags >nul 2>&1
) else (
    powershell -NoProfile -Command "try { Invoke-WebRequest -Uri 'http://localhost:11434/api/tags' -UseBasicParsing -TimeoutSec 2 | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
)
if %errorlevel% neq 0 (
    echo [WARNING] Ollama not running in background. Starting Ollama...
    if /I "%OLLAMA_BIN%"=="ollama" (
        start "" ollama serve >nul 2>&1
    ) else (
        start "" "%OLLAMA_BIN%" serve >nul 2>&1
    )
    timeout /t 5 /nobreak >nul
)
echo [OK] Ollama Service active.
echo.

:: 3. PULL MODEL
echo [3/4] Checking AI Model granite3-dense...
if /I "%OLLAMA_BIN%"=="ollama" (
    ollama pull granite3-dense
) else (
    "%OLLAMA_BIN%" pull granite3-dense
)
if %errorlevel% neq 0 (
    echo [WARNING] Failed to pull granite3-dense model. Trying llama3.2...
    if /I "%OLLAMA_BIN%"=="ollama" (
        ollama pull llama3.2
    ) else (
        "%OLLAMA_BIN%" pull llama3.2
    )
)
echo [OK] AI Model ready.
echo.

:: 4. SETUP VIRTUAL ENVIRONMENT AND RUN SERVER
echo [4/4] Preparing Python Environment...
if not exist "venv" (
    echo Creating Virtual Environment...
    python -m venv venv
) else (
    echo [OK] Virtual environment already exists.
)

call venv\Scripts\activate

python -c "import importlib.util, sys; sys.exit(0 if all(importlib.util.find_spec(name) for name in ['uvicorn','fastapi','pydantic','langchain_ollama','langchain_core']) else 1)" >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing and checking dependencies...
    pip install -q -r backend/requirements.txt
) else if exist "backend\__pycache__" (
    echo [OK] Virtual environment and cache ready. Running application.
) else (
    echo Installing and checking dependencies...
    pip install -q -r backend/requirements.txt
)

echo.
echo =======================================================
echo  LOOKUP WEB SERVICE STARTED SUCCESSFULLY!             
echo =======================================================
echo  Browser will automatically open at 127.0.0.1:8000     
echo =======================================================
echo.

start "" http://127.0.0.1:8000/
python backend/main.py
if exist "venv" (
    rd /s /q "venv"
    echo [CLEANUP] Folder venv successfully deleted.
)
for /d /r "%~dp0" %%D in __pycache__ do (
    rd /s /q "%%D"
    echo [CLEANUP] Folder %%D successfully deleted.
)
pause