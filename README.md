# 🛡️ SecureAI: AI-Powered Social Engineering Attack Prevention System

SecureAI is a dual-platform security analytics system designed to identify and analyze modern social engineering threats across web and Android environments. It combines Artificial Intelligence, Machine Learning, Natural Language Processing, and Computer Vision to help users recognize suspicious messages, phishing emails, malicious QR codes, compromised passwords, and unusual login behavior.

---

## 🌐 Quick Access & Live Deployments

| Resource | Description / Access |
| :--- | :--- |
| **🌐 PRODUCTION WEBSITE** | [🚀 OPEN SECUREAI LIVE WEBSITE](https://secureai-7wgj.onrender.com/) |
| **📽 Video Demonstration** | [Watch SecureAI in Action on LinkedIn](https://www.linkedin.com/posts/sai-teja-kokala-245a12299_ai-cybersecurity-machinelearning-ugcPost-7476167691737714688-QWWw) |

### 📲 Direct Android App Downloads
Choose the APK compatible with your Android device.

| APK Version | Compatibility | Size | Download |
| :--- | :--- | :--- | :--- |
| **Universal APK** ⭐ Recommended | ARMv7, ARM64, x86_64 | 54.3 MB | [⬇️ Download APK](https://secureai-7wgj.onrender.com/media/app-release.apk) |
| **ARM64 APK** | Modern 64-bit Android smartphones | 20.2 MB | [⬇️ Download APK](https://secureai-7wgj.onrender.com/media/app-arm64-v8a-release.apk) |
| **ARMv7 APK** | Older 32-bit Android smartphones | 17.7 MB | [⬇️ Download APK](https://secureai-7wgj.onrender.com/media/app-armeabi-v7a-release.apk) |
| **x86_64 APK** | Android Studio emulators and compatible ChromeOS devices | 21.7 MB | [⬇️ Download APK](https://secureai-7wgj.onrender.com/media/app-x86_64-release.apk) |

#### Which APK should you download?
- **Universal APK**: Choose this if you are unsure about your device's processor architecture.
- **ARM64 APK**: Choose this for most modern 64-bit Android smartphones.
- **ARMv7 APK**: Choose this for compatible older 32-bit Android smartphones.
- **x86_64 APK**: Intended for compatible Android emulators and x86_64 devices.

> [!NOTE]
> **Cloud Server Spin-Up Latency**: The backend is hosted on Render's free tier. After a period of inactivity, the first request may take approximately 60–75 seconds while the server wakes up. Subsequent requests are generally faster. The mobile application includes a `ServerWakeOverlay` to monitor connection readiness.

---

## 📦 Project Architecture & Subsystem Documentation

The repository contains two dedicated codebases:

```
SecureAI-main/
│
├── README.md                          # Root project documentation
│
├── SecureAI_Web/                      # Django web application and AI pipelines
│   ├── README.md                      # Web platform documentation
│   ├── manage.py
│   ├── media/                         # ML models, assets and APK downloads
│   ├── templates/                     # Web application templates
│   └── users/                         # User management and security modules
│
└── SecureAI_Mobile_app/               # Flutter Android application
    ├── README.md                      # Mobile application documentation
    ├── lib/                           # Flutter screens and application logic
    ├── android/                       # Native Android configuration
    └── screenshots/                   # Mobile application screenshots
```

### 📖 Detailed Documentation
- [**SecureAI Web Platform README**](./SecureAI_Web/README.md) — Web application architecture, setup instructions, AI pipelines, and screenshots.
- [**SecureAI Mobile Application README**](./SecureAI_Mobile_app/README.md) — Flutter architecture, Android compatibility, setup instructions, and mobile screenshots.

---

## 🚀 Running from a Fresh Repository Clone

Follow these instructions to set up the web backend and mobile application locally.

### 1. 🌐 Web Application — Django & AI Engine

> [!IMPORTANT]
> Create and activate a Python virtual environment before installing dependencies. Running Django with a system Python installation that does not contain the required packages can result in `ModuleNotFoundError: No module named 'django'`.

```bash
# Step 1: Navigate to the web application folder
cd SecureAI-main/SecureAI_Web

# Step 2: Create a virtual environment
python3 -m venv ../.venv

# Step 3: Activate the virtual environment
# macOS / Linux
source ../.venv/bin/activate
# Windows
..\.venv\Scripts\activate

# Step 4: Upgrade pip and install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Step 5: Configure environment variables
# Create a .env file or configure them in your environment.
# Never commit API keys, passwords, or secret values to GitHub.
# Example variable names:
# SECRET_KEY=your-django-secret-key
# DATABASE_URL=your-database-url
# SECUREAI_ADMIN_USERNAME=admin
# SECUREAI_ADMIN_PASSWORD=your-secure-password
# RESEND_API_KEY=your-resend-api-key
# BREVO_API_KEY=your-brevo-api-key
# BREVO_SENDER_EMAIL=your-verified-brevo-sender-email
# GOOGLE_API_KEY=your-gemini-api-key

# Step 6: Apply database migrations
python manage.py migrate

# Step 7: Start the development server
python manage.py runserver
```

Open the application at:
```
http://127.0.0.1:8000/
```

### 2. 📱 Mobile Application — Flutter Android Client

```bash
# Step 1: Navigate to the mobile application folder
cd SecureAI-main/SecureAI_Mobile_app

# Step 2: Install Flutter dependencies
flutter pub get

# Step 3: Run the application
flutter run

# Step 4: Build split release APKs (optional)
flutter build apk --split-per-abi
```

Generated APK files:
```
build/app/outputs/flutter-apk/
├── app-arm64-v8a-release.apk
├── app-armeabi-v7a-release.apk
└── app-x86_64-release.apk
```

---

## 🚀 Core Security Features

SecureAI provides threat detection and security analysis across both its web portal and Android application.

### 1. 📩 SMS Spam & Smishing Detector
- **AI Engine**: Natural Language Processing using Google Gemini 2.5 Flash.
- **Classification**: Identifies suspicious SMS messages and classifies them as Spam or Ham.
- **Analysis**: Provides explanations and identifies potential smishing tactics.

### 2. 🔗 QR Code & Quishing Threat Scanner
- **Computer Vision**: Uses OpenCV to extract QR code content and embedded URLs.
- **AI Analysis**: Uses Gemini 2.5 Flash to assess URL-related security risks.
- **Camera & Upload**: Supports live camera capture and image uploads.
- **Threat Verdict**: Classifies analyzed links as Safe, Phishing, or Malicious before users proceed to the destination.

### 3. 📧 Email Phishing Analyzer
- **AI-Powered Analysis**: Examines email content for suspicious language and potential phishing indicators.
- **Psychological Indicators**: Identifies urgency manipulation, false authority, and domain impersonation.
- **Results**: Provides a verdict, confidence information, and categorized warning indicators.

### 4. 🛡️ Password Strength & Breach Auditor
- **Password Evaluation**: Evaluates password complexity and strength.
- **Breach Checking**: Uses SHA-1 k-anonymity prefix hashing to communicate with the Have I Been Pwned database.
- **Privacy**: Avoids transmitting the plain-text password during breach checking.

### 5. 🧠 User Behavioral Anomaly Profiling
- **Machine Learning**: Uses a classifier ensemble involving Logistic Regression, Random Forest, and XGBoost.
- **Session Intelligence**: Evaluates login parameters such as `login_hour` and `ip_score` to identify unusual login behavior.
- **Interactive Training**: Includes an in-app retraining pipeline and confusion matrix visualizations.

### 6. 👥 Administrative Governance & Identity Management
- **Environment-Driven Authentication**: Administrator credentials are configured through `SECUREAI_ADMIN_USERNAME` and `SECUREAI_ADMIN_PASSWORD` environment variables rather than hardcoded credentials.
- **Secure Credential Comparison**: Uses `secrets.compare_digest` for credential comparison and fails closed when administrator credentials are not configured.
- **User Management**: Supports viewing registered users, activating or deactivating accounts, deleting accounts, and editing user details.
- **Password Security**: Uses Django's PBKDF2 password hashing through `make_password`.
- **Legacy Password Migration**: Includes a migration mechanism to upgrade legacy plaintext passwords to PBKDF2 during login.
- **Duplicate Registration Prevention**: Validates username and email uniqueness across web and mobile registration endpoints.
- **OTP Password Recovery**: Provides email-based password recovery with the following protections:
  - 60-second OTP request cooldown.
  - 5-minute OTP expiration.
  - Maximum of 3 verification attempts.
  - Verified reset authorization required before changing a password.
- **Session & CSRF Protection**: Uses session expiration, HttpOnly cookies, secure cookies in production, and HTTPS proxy configuration.
- **Database Monitoring**: Includes a database heartbeat indicator in the administration dashboard.

---

## 📱 Mobile APK Download Guide & Device Compatibility

SecureAI provides universal and architecture-specific APK packages to support different Android environments.

| APK Package | Architecture (ABI) | Intended Devices |
| :--- | :--- | :--- |
| **`app-release.apk`** | ARMv7, ARM64, x86_64 | Compatible Android phones and devices across the included architectures |
| **`app-arm64-v8a-release.apk`** | 64-bit ARM | Modern 64-bit Android smartphones |
| **`app-armeabi-v7a-release.apk`** | 32-bit ARM | Compatible older 32-bit Android smartphones |
| **`app-x86_64-release.apk`** | 64-bit x86 | Android Studio emulators and compatible x86_64 devices |

> [!TIP]
> **Recommendation**: If you do not know your device's architecture, start with the [Universal APK](https://secureai-7wgj.onrender.com/media/app-release.apk). If you know your device supports ARM64, the [ARM64 APK](https://secureai-7wgj.onrender.com/media/app-arm64-v8a-release.apk) is a smaller download.

---

## ⚙️ Automated CI/CD & APK Publishing Pipeline

SecureAI uses GitHub Actions to automate Android release builds and APK publishing.

Workflow file:  
[`.github/workflows/build-apk.yml`](./.github/workflows/build-apk.yml)

### Pipeline Capabilities
- **Triggers**: Runs when relevant files under `SecureAI_Mobile_app/` are pushed or when manually triggered through `workflow_dispatch`.
- **Build Automation**: Generates split-per-ABI APKs and a universal release APK.
- **Architecture Verification**: Checks native library inclusion in the universal APK.
- **Integrity Verification**: Generates SHA-256 checksums and records APK sizes.
- **Automated Publishing**: Copies generated APKs into `SecureAI_Web/media/` and pushes updated binaries to the repository.
- **Artifact Archiving**: Uploads separate GitHub Actions artifacts for ARM64, ARMv7, x86_64, and universal APK builds.

---

## 🛠️ Technology Stack

| Category | Technologies |
| :--- | :--- |
| **Programming Languages** | Python, Dart, HTML5, CSS, JavaScript |
| **Web Backend** | Django 5.0.9, Gunicorn, WhiteNoise |
| **Web Frontend** | HTML5, CSS, Tailwind CSS, Font Awesome 6 |
| **Mobile Development** | Flutter 3.x, Dart 3.x |
| **AI & NLP** | Google Gemini 2.5 Flash, LangChain Core |
| **Machine Learning** | Scikit-learn, XGBoost, NumPy, Pandas |
| **Computer Vision** | OpenCV, Flutter camera and image picker packages |
| **Database** | SQLite for development, Neon Serverless PostgreSQL for production |
| **Email Gateway** | Resend API, Brevo API |
| **Hosting** | Render |
| **CI/CD** | GitHub Actions |
| **Version Control** | Git and GitHub |

---

## 🔐 Environment Configuration & Security

SecureAI uses environment variables to manage sensitive configuration values.

Example variable names:
```bash
SECRET_KEY=your-django-secret-key
DATABASE_URL=your-database-url
SECUREAI_ADMIN_USERNAME=admin
SECUREAI_ADMIN_PASSWORD=your-secure-password
GOOGLE_API_KEY=your-gemini-api-key
RESEND_API_KEY=your-resend-api-key
BREVO_API_KEY=your-brevo-api-key
BREVO_SENDER_EMAIL=your-verified-email
```

### Important security practices:
- Never commit `.env` files or API keys to GitHub.
- Use strong, unique passwords for administrator accounts.
- Configure production secrets through the hosting provider's environment settings.
- Keep API keys private and rotate them if exposed.
- Use HTTPS for production communication.

---

## 👥 Author & Developer

**Kokala Sai Teja**  
Developer — SecureAI  
*Project Theme: Usage of AI in Prevention of Social Engineering Attacks.*

---

© 2026 SecureAI. All rights reserved.
