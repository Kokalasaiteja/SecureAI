# Social Engineering Attack Prevention System using AI

### 🌐 Live Demo: [https://secureai-7wgj.onrender.com](https://secureai-7wgj.onrender.com)

### 📽 Demo Video Watch the complete working demo here: [SecureAI.mp4](https://www.linkedin.com/posts/sai-teja-kokala-245a12299_ai-cybersecurity-machinelearning-ugcPost-7476167691737714688-QWWw)

An intelligent Django-based security analytics platform designed to analyze social engineering vectors, execute anomaly tracking models, detect malicious communication patterns, and manage interactive admin controls.

## Critical Dependency Warning
> **IMPORTANT:** Running a generic `pip install -r Req.txt` will downgrade essential serialization engines and cause thread-loop failures within the ML training views. Always execute the manual setups below after a generic environment synchronization.

### Required Manual Installations (Core Fixes)

```bash
# 1. Restore serialization engine translation layer for LangChain
pip install --upgrade proto-plus --no-deps --force-reinstall

# 2. Re-establish tracking compatibility for Protocol Buffers
pip install "protobuf>=6.31.1,<8.0.0" --no-deps --force-reinstall
```

### Setup & Local Execution Pipeline

1. **Activate Environment Context:**
```powershell
(Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned) ; (& .\venv310\Scripts\Activate.ps1)
```

2. **Launch Development Application:**
```powershell
python manage.py runserver
```

---

## 🚀 Features

### 1. **📩 SMS Spam Detector**
- **Logic**: Natural Language Processing (NLP) tokenization and contextual sequence analysis.
- **Model**: Google Gemini 2.5 Flash AI model.
- **Training Data**: Pre-trained on vast datasets of global SMS communications, encompassing both legitimate messages and known smishing/spam attempts.
- **Functionality**: Real-time classification of SMS messages as **Spam** or **Ham** (not spam), returning a one-line explanation along with the classification.

**How to test (examples):**
- **Example 1 (Spam)**: "Congratulations! You won a free gift. Click to claim now"  
  Expected: **Spam**
- **Example 2 (Ham)**: "Hi! Are we still meeting for dinner tonight?"  
  Expected: **Ham**

### 2. **🔗 QR Code Threat Scanner**
- **Logic**: Image processing to decode QR matrices followed by rigorous URL threat extraction and analysis.
- **Algorithm & Models**: OpenCV for robust QR decoding (handles rotation and blur); LangChain combined with Google Gemini 2.5 Flash for URL threat classification.
- **Training Data**: Analyzes patterns derived from known phishing URLs, safe domain registries, and malicious link structures.
- **Functionality**: Scans QR codes and classifies the hidden URLs as Safe, Phishing, or Malicious.

**How to test (examples):**
- **Example 1 (Safe)**: A QR code linking to a restaurant's digital menu (`https://www.example-restaurant.com/menu`).  
  Expected: **Safe**
- **Example 2 (Phishing)**: A QR code routing to a deceptive banking login page (`http://secure-login-chase-update.com`).  
  Expected: **Phishing / Malicious**

### 3. **📧 Email Phishing Analyzer**
- **Logic**: Textual analysis focusing on psychological triggers associated with social engineering, such as manufactured urgency, false authority, and deceptive phrasing.
- **Model**: Google Gemini 2.5 Flash.
- **Training Data**: Generalized knowledge base encompassing historical phishing templates, scam emails, and standard corporate/personal communications.
- **Functionality**: Evaluates the contents of any suspicious email and returns a strict classification (Safe, Suspicious, Phishing) along with bulleted explanations and identified red flags.

**How to test (examples):**
- **Example 1 (Phishing)**: "Dear customer, your account will be locked in 24 hours. Click here to verify."  
  Expected: **Phishing**
- **Example 2 (Suspicious)**: "Hi team, please find attached the meeting notes from yesterday's sync. Let me know if you have any questions."  
  Expected: **Suspicious**
- **Example 3 (Safe)**: "Hi John, could we reschedule our 1-on-1 meeting to tomorrow at 2 PM? Let me know if that works for you."  
  Expected: **Safe**

### 4. **🛡️ Password Strength & Breach Analyzer**
- **Logic**: Combines heuristic complexity checking with secure, zero-knowledge breach verification.
- **Algorithm**: SHA-1 hashing algorithm for k-Anonymity (prefix matching).
- **Data Source**: Integrates with the "Have I Been Pwned" API database containing billions of leaked credentials.
- **Functionality**: Evaluates password strength (length, uppercase, lowercase, numbers, special characters) and ensures the password has not been exposed in known data breaches without ever transmitting it in plain text.

**How to test (examples):**
- **Example 1 (Weak & Breached)**: `password123`  
  Expected: **Weak Strength & Found in Data Breaches (Unsafe)**
- **Example 2 (Strong & Safe)**: `Tr0ub4dor&3!Secure`  
  Expected: **Strong Strength & No Known Breaches (Safe)**

### 5. **User Behavior Anomaly Detection**
- **Logic**: Statistical profiling and machine learning classification to detect atypical session parameters that may indicate account takeover.
- **Algorithms & Models**: Logistic Regression, Random Forest, and XGBoost classifiers.
- **Training Data**: Trained locally on `behavior_anomaly_dataset.csv`, learning from historical login hours and IP risk scores.
- **Classification Details**: 
  - The models evaluate two primary features: `login_hour` (the time of day the login occurs) and `ip_score` (a probabilistic risk score from 0.0 to 1.0 assigned to the user's IP based on geolocation and reputation).
  - The algorithms create a decision boundary. Combinations of a high `ip_score` (e.g., unknown or risky IP) and an atypical `login_hour` (e.g., 3:00 AM) are flagged as an **Anomaly**. Conversely, standard business hours combined with low IP scores are classified as **Normal**.
- **Functionality**: Real-time prediction of user behavior anomalies. Displays a beautiful HTML/CSS-based confusion matrix heatmap (True Positives, True Negatives, False Positives, False Negatives) for model evaluation, optimized to run without memory-heavy image rendering.

**How to test (examples):**
1. (Optional) Train models first via: **`/train-anomaly-model/`**
2. Go to: **`/predict-anomaly/`**
- **Example 1 (Normal)**: `login_hour=10`, `ip_score=0.20` → Expected **Normal**
- **Example 2 (Anomaly)**: `login_hour=2`, `ip_score=0.95` → Expected **Anomaly**

### 6. **User Management System**
- Secure user registration with admin approval
- Profile image upload
- Password reset with OTP verification
- Session management with login time tracking

### 7. **Admin Dashboard**
- User activation/deactivation controls
- User management interface
- Comprehensive user overview

## 🛠️ Technology Stack

- **Backend**: Django 5.0.9
- **Frontend**: Tailwind CSS, Font Awesome
- **AI/ML**: 
  - Google Gemini 2.5 Flash
  - LangChain
  - Scikit-learn
  - XGBoost
- **Computer Vision**: OpenCV
- **Database**: SQLite (Local Development) & Neon PostgreSQL (Production Deployment)
  > *Deployment Note*: The project uses SQLite for local testing, but it is deployed using [Neon Serverless PostgreSQL](https://console.neon.tech/app/projects/wild-lab-13182754) for persistent production data on Render. Note: while the Neon database is persistent, user-uploaded files on Render's free tier are ephemeral and may reset upon container rebuilds.

## 📋 Prerequisites

- Python 3.10.11
- pip (Python package manager)
- Virtual environment (recommended)

## 🔧 Installation

### 1. Clone the repository
```bash
git clone <repository-url>
cd code
```

### 2. Create and activate virtual environment
```bash
# Windows
python -m venv venv
venv\Scripts\activate

# Linux/Mac
python3 -m venv venv
source venv/bin/activate
```

### 3. Install dependencies
```bash
pip install -r Req.txt
```

#### 3.1 Manual Package Installations
The following packages have been commented out in `Req.txt` and may need to be installed manually if required for specific features:
```bash
pip install google-ai-generativelanguage google-generativeai googletrans==4.0.0rc1
pip install langchain langchain-core langchain-google-genai langchain-text-splitters==0.3.8
pip install TTS==0.22.0
```
*(Note: `yolov5` is a repository and should be cloned manually if needed)*

### 4. Configure environment variables
Create a `.env` file in the root project directory and add your credentials:
```env
SECRET_KEY=your-django-secret-key
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

RESEND_API_KEY=your-resend-api-key

GOOGLE_API_KEY=your-gemini-api-key
```

### 5. Run migrations
```bash
python manage.py makemigrations
python manage.py migrate
```

### 6. Create superuser (optional)
```bash
python manage.py createsuperuser
```

### 7. Run the development server
```bash
python manage.py runserver
```

Visit `http://127.0.0.1:8000/` in your browser.

## 🔑 Getting API Keys

### Google Gemini API Key
1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Create a new API key
4. Copy the key to your `.env` file

### Resend API Key (for OTP emails)
*Note: Previously, standard Gmail App Passwords were used (`EMAIL_HOST_USER` / `EMAIL_HOST_PASSWORD`). However, cloud environments like Render often block standard SMTP ports (like port 25, 465, 587) resulting in `Network is unreachable` errors. To fix this and provide beautifully formatted HTML emails, we now use the Resend API which operates securely over HTTPS port 443.*
1. Sign up or log in at [Resend](https://resend.com)
2. Navigate to API Keys and generate a new key
3. Copy the key to your `.env` file as `RESEND_API_KEY`

## 📁 Project Structure

```
code/
├── manage.py
├── db.sqlite3                       # SQLite Database (Default)
├── Req.txt                          # Local development requirements (full dependencies)
├── requirements-render.txt          # Render deployment requirements (optimized, no matplotlib/seaborn)
├── .env                             # Local environment configuration file (ignored in git)
├── .gitignore                       # Git ignore configurations
├── README.md                        # Project documentation
├── setup.bat                        # Auto-setup script for Windows
├── setup.sh                         # Auto-setup script for macOS/Linux
├── media/                           # User uploads and ML models
│   ├── models/                      # Trained ML model binaries (.pkl)
│   └── behavior_anomaly_dataset.csv # CSV file for behavioral anomaly training
├── templates/                      # HTML templates
│   ├── base.html
│   ├── home.html
│   ├── register.html
│   ├── user_login.html
│   ├── admin_login.html
│   ├── admin_dashboard.html
│   ├── forgot_password.html
│   ├── verify_otp.html
│   ├── reset_password.html
│   └── users/
│       ├── user_base.html
│       ├── user_homepage.html
│       ├── detect.html
│       ├── qr_form.html
│       ├── qr_result.html
│       ├── predict_anomaly.html
│       └── train_anomaly.html
├── users/                          # Main app codebase
│   ├── models.py
│   ├── views.py
│   ├── admin.py
│   └── migrations/
├── Usage_of_AI_in_Prevention_of_Social_Engineering_Attack/ # Main project configurations
│   ├── settings.py
│   ├── urls.py
│   ├── wsgi.py
│   └── asgi.py
└── yolov5/                          # Local YOLOv5 model configurations
```

## 🎯 Usage

### User Flow
1. **Register**: Create an account with profile image
2. **Wait for Approval**: Admin must activate your account
3. **Login**: Access the user dashboard
4. **Use Features**:
   - Detect spam messages
   - Scan QR codes for threats
   - Analyze behavioral anomalies

### Admin Flow
1. **Login**: Use credentials (default: admin/admin)
2. **Dashboard**: View all registered users
3. **Manage Users**: Activate, deactivate, or delete users

## 🔒 Security Features

- Environment-based configuration (no hardcoded secrets)
- CSRF protection enabled
- Session-based authentication
- OTP-based password reset
- Admin approval for new users
- Secure file upload handling

## 🐛 Troubleshooting

### Common Issues

**Issue**: `ModuleNotFoundError`
```bash
# Solution: Install missing packages
pip install -r Req.txt
```

**Issue**: Database errors
```bash
# Solution: Reset database
del db.sqlite3
python manage.py migrate
```

**Issue**: Static files not loading
```bash
# Solution: Collect static files
python manage.py collectstatic
```

**Issue**: Email not sending
- Verify your Resend API Key is correct
- Check your Resend dashboard for delivery logs
- Ensure RESEND_API_KEY is set in .env

## 📊 ML Model Training

To train the behavioral anomaly detection models:

1. Ensure `behavior_anomaly_dataset.csv` is in the `media/` folder
2. Navigate to: User Dashboard → Behavior Analysis → Train Models
3. View confusion matrices and classification reports

## 🎨 UI Features

- Modern glassmorphism design
- Responsive layout (mobile-friendly)
- Animated transitions and hover effects
- Gradient backgrounds
- Icon-based navigation
- 3D button effects

## 📝 API Endpoints

- `/` - Home page
- `/register/` - User registration
- `/user-login/` - User login
- `/admin-login/` - Admin login
- `/user-homepage/` - User dashboard
- `/admin-dashboard/` - Admin panel
- `/detect_spam/` - SMS spam detection
- `/scan-qr/` - QR code scanner
- `/predict-anomaly/` - Behavioral analysis
- `/train-anomaly-model/` - Train ML models
- `/forgot-password/` - Password reset
- `/verify-otp/` - OTP verification
- `/reset-password/` - New password setup

# 📸 Screenshots

<table>
  <tr>
    <td align="center">
      <b>Home Page</b><br><br>
      <img src="https://github.com/user-attachments/assets/89e4aa74-db6b-4d45-be50-f74329e3d073" width="260"/>
    </td>
    <td align="center">
      <b>Introduction Page</b><br><br>
      <img src="https://github.com/user-attachments/assets/46567a15-372e-4fff-8027-ec5c94458d51" width="260"/>
    </td>
    <td align="center">
      <b>Registration Page</b><br><br>
      <img src="https://github.com/user-attachments/assets/602ee93c-f624-4809-add5-c0fb2582c07c" width="260"/>
    </td>
    <td align="center">
      <b>User Login</b><br><br>
      <img src="https://github.com/user-attachments/assets/4e733148-1e1c-444d-be25-0445dc6ecc0a" width="260"/>
    </td>
  </tr>

  <tr>
    <td align="center">
      <b>Email OTP Verification</b><br><br>
      <img src="https://github.com/user-attachments/assets/2170618f-8a69-474e-9dc6-a390a7d61ec5" height="220"/>
    </td>
    <td align="center">
      <b>Admin Login</b><br><br>
      <img src="https://github.com/user-attachments/assets/de3a2634-2be8-4379-a08a-595f1792d838" width="260"/>
    </td>
    <td align="center">
      <b>Admin Dashboard Page</b><br><br>
      <img src="https://github.com/user-attachments/assets/6008da22-5036-4549-be07-c3216e0ca042" width="260"/>
    </td>
    <td align="center">
      <b>Admin Dashboard</b><br><br>
      <img src="https://github.com/user-attachments/assets/0f105354-041a-4325-90fb-3884aacf307b" width="260"/>
    </td>
  </tr>

  <tr>
    <td align="center">
      <b>User Dashboard</b><br><br>
      <img src="https://github.com/user-attachments/assets/27708f2a-c545-4c89-9331-1b33cf062399" width="260"/>
    </td>
    <td align="center">
      <b>SMS Detector</b><br><br>
      <img src="https://github.com/user-attachments/assets/2917c677-4f7c-418b-959a-c9ea535a0b55" width="260"/>
    </td>
    <td align="center">
      <b>QR Scanner</b><br><br>
      <img src="https://github.com/user-attachments/assets/da1bfb57-6c28-4420-89b9-2a2207a74955" width="260"/>
    </td>
    <td align="center">
      <b>Behavior Analysis</b><br><br>
      <img src="https://github.com/user-attachments/assets/d7914249-ccfa-4274-b495-619f865ad631" width="260"/>
    </td>
  </tr>

  <tr>
    <td align="center">
      <b>Anomaly Detection Training Results</b><br><br>
      <img src="https://github.com/user-attachments/assets/4276f12d-2c00-4d85-bd35-66d0226c169d" width="260"/>
    </td>
    <td align="center">
      <b>Email Phishing Analyzer</b><br><br>
      <img src="https://github.com/user-attachments/assets/608c93c5-9950-485b-b331-2b464541b1f2" width="260"/>
    </td>
    <td align="center">
      <b>Phishing Analyzer Output</b><br><br>
      <img src="https://github.com/user-attachments/assets/f53ab97a-f4da-4cc5-9fa9-84f929fca953" width="260"/>
    </td>
    <td align="center">
      <b>Password Checker</b><br><br>
      <img src="https://github.com/user-attachments/assets/ab778f6f-9d46-41e3-a5be-f0a5623dd5bd" width="260"/>
    </td>
  </tr>
</table>

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 👥 Authors

- Project Team - Usage of AI in Prevention of Social Engineering Attacks

## 🙏 Acknowledgments
- Google Gemini AI for natural language processing
- LangChain for AI orchestration
- Tailwind CSS for modern UI components
- OpenCV for QR code detection
- Scikit-learn and XGBoost for ML models

© 2026 SecureAI. All rights reserved. (SecureAI website)
