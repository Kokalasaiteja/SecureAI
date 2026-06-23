@echo off
echo ========================================
echo SecureAI Setup Script
echo ========================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.8 or higher from https://www.python.org/
    pause
    exit /b 1
)

echo [1/6] Creating virtual environment...
python -m venv venv
if errorlevel 1 (
    echo ERROR: Failed to create virtual environment
    pause
    exit /b 1
)

echo [2/6] Activating virtual environment...
call venv\Scripts\activate.bat

echo [3/6] Upgrading pip...
python -m pip install --upgrade pip

echo [4/6] Installing dependencies...
pip install -r Req.txt
if errorlevel 1 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)

echo [5/6] Creating .env file from template...
if not exist .env (
    copy .env.example .env
    echo .env file created. Please edit it with your credentials.
) else (
    echo .env file already exists. Skipping...
)

echo [6/6] Running database migrations...
python manage.py makemigrations
python manage.py migrate

echo.
echo ========================================
echo Setup completed successfully!
echo ========================================
echo.
echo Next steps:
echo 1. Edit .env file with your API keys and credentials
echo 2. Run: python manage.py runserver
echo 3. Visit: http://127.0.0.1:8000/
echo.
echo Default admin credentials: admin/admin
echo.
pause
