# 🚀 Quick Start Guide - SecureAI

Get up and running in 5 minutes!

## Prerequisites
- Python 3.8+ installed
- Internet connection
- Gmail account (for OTP emails)
- Google Gemini API key

## Step 1: Setup Environment

### Windows
```bash
cd code
setup.bat
```

### Linux/Mac
```bash
cd code
chmod +x setup.sh
./setup.sh
```

## Step 2: Configure API Keys

Edit the `.env` file with your credentials:

```env
# Get from: https://makersuite.google.com/app/apikey
GOOGLE_API_KEY=your-gemini-api-key-here

# Gmail App Password (enable 2FA first)
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-16-char-app-password
```

## Step 3: Start the Server

```bash
# Activate virtual environment first
# Windows:
venv\Scripts\activate

# Linux/Mac:
source venv/bin/activate

# Run server
python manage.py runserver
```

## Step 4: Access the Application

Open your browser and visit:
```
http://127.0.0.1:8000/
```

## Default Credentials

### Admin Login
- URL: http://127.0.0.1:8000/admin-login/
- Username: `admin`
- Password: `admin`

### User Registration
- URL: http://127.0.0.1:8000/register/
- Register a new account
- Wait for admin approval
- Login at: http://127.0.0.1:8000/user-login/

## Features to Try

1. **SMS Spam Detection**
   - Navigate to: User Dashboard → SMS Spam Detection
   - Enter a message to check if it's spam

2. **QR Code Scanner**
   - Navigate to: User Dashboard → QR Code Scanner
   - Upload a QR code image
   - Get AI-powered threat analysis

3. **Behavior Analysis**
   - Navigate to: User Dashboard → Behavior Analysis
   - Enter login hour (0-23) and IP score (0.0-1.0)
   - Get anomaly prediction

4. **Train ML Models**
   - Navigate to: User Dashboard → Train ML Models
   - View confusion matrices and model performance

## Troubleshooting

### Port Already in Use
```bash
# Use a different port
python manage.py runserver 8080
```

### Module Not Found
```bash
pip install -r Req.txt
```

### Database Errors
```bash
# Reset database
del db.sqlite3  # Windows
rm db.sqlite3   # Linux/Mac

python manage.py migrate
```

### Email Not Sending
1. Enable 2-Factor Authentication on Gmail
2. Generate App Password: https://myaccount.google.com/apppasswords
3. Use the 16-character password in .env

## Need Help?

- Check README.md for detailed documentation
- Review error messages in terminal
- Ensure all dependencies are installed
- Verify API keys are correct

## Next Steps

1. Explore all features
2. Train custom ML models
3. Test with different data
4. Customize UI themes
5. Add more security features

---

**Happy Coding! 🎉**
