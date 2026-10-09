#!/bin/bash

echo "========================================"
echo "SecureAI Setup Script"
echo "========================================"
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python 3 is not installed"
    echo "Please install Python 3.8 or higher"
    exit 1
fi

echo "[1/6] Creating virtual environment..."
python3 -m venv venv
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create virtual environment"
    exit 1
fi

echo "[2/6] Activating virtual environment..."
source venv/bin/activate

echo "[3/6] Upgrading pip..."
python -m pip install --upgrade pip

echo "[4/6] Installing dependencies..."
pip install -r Req.txt
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install dependencies"
    exit 1
fi

echo "[5/6] Creating .env file from template..."
if [ ! -f .env ]; then
    cp .env.example .env
    echo ".env file created. Please edit it with your credentials."
else
    echo ".env file already exists. Skipping..."
fi

echo "[6/6] Running database migrations..."
python manage.py makemigrations
python manage.py migrate

echo ""
echo "========================================"
echo "Setup completed successfully!"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Edit .env file with your API keys and credentials"
echo "2. Run: python manage.py runserver"
echo "3. Visit: http://127.0.1:8000/"
echo ""
echo "Default admin credentials: admin/admin"
echo ""
