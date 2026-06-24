# 📚 Instructions for Students

## ✅ What You Need Before Starting

1. **Python 3.8 or higher** installed on your computer
   - Check: Open terminal/cmd and type `python --version`
   - Download from: https://www.python.org/downloads/

2. **Internet connection** (for downloading packages)

3. **Gmail account** (for OTP email feature)

4. **Google Gemini API key** (free)
   - Get it from: https://makersuite.google.com/app/apikey

## 🚀 Quick Setup (5 Minutes)

### For Windows Users:
```bash
1. Extract the code folder
2. Open Command Prompt in the code folder
3. Run: setup.bat
4. Edit .env file with your API keys
5. Run: python manage.py runserver
6. Open browser: http://127.0.0.1:8000/
```

### For Mac/Linux Users:
```bash
1. Extract the code folder
2. Open Terminal in the code folder
3. Run: chmod +x setup.sh
4. Run: ./setup.sh
5. Edit .env file with your API keys
6. Run: python manage.py runserver
7. Open browser: http://127.0.0.1:8000/
```

## 🔑 Getting API Keys

### Google Gemini API (Required):
1. Visit: https://makersuite.google.com/app/apikey
2. Sign in with Google account
3. Click "Create API Key"
4. Copy the key
5. Paste in .env file: `GOOGLE_API_KEY=your-key-here`

### Gmail App Password (For OTP emails):
1. Enable 2-Factor Authentication on Gmail
2. Visit: https://myaccount.google.com/apppasswords
3. Generate app password for "Mail"
4. Copy 16-character password
5. Paste in .env file

## 📖 Read These Files:
- **QUICKSTART.md** - Fast setup guide
- **README.md** - Complete documentation
- **FIXES_SUMMARY.md** - What was fixed

## ✅ The Project Will Work If:
- Python 3.10.11 is installed
- All dependencies install correctly (setup script does this)
- You add your API keys to .env file
- Port 8000 is not in use

## 🎯 Default Login:
- Admin: username=`admin`, password=`admin`
- Users: Register first, then admin approves

## 💡 Need Help?
Check QUICKSTART.md or README.md for troubleshooting!
