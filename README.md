# 🛡️ SecureAI: AI-Powered Social Engineering Attack Prevention System

[![Live Demo](https://img.shields.io/badge/Live%20Demo-secureai--7wgj.onrender.com-00C7B7?style=for-the-badge&logo=render&logoColor=white)](https://secureai-7wgj.onrender.com)
[![Universal APK](https://img.shields.io/badge/Download%20APK-Universal%20(All%20Devices)-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://secureai-7wgj.onrender.com/media/app-release.apk)
[![Demo Video](https://img.shields.io/badge/Watch%20Demo-LinkedIn%20Video-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/posts/sai-teja-kokala-245a12299_ai-cybersecurity-machinelearning-ugcPost-7476167691737714688-QWWw)
[![Python](https://img.shields.io/badge/Backend-Django%205.0.9%20%7C%20Python%203.10+-3776AB?style=flat&logo=python&logoColor=white)](https://www.python.org/)
[![Flutter](https://img.shields.io/badge/Mobile-Flutter%203.x%20%7C%20Dart%203.x-02569B?style=flat&logo=flutter&logoColor=white)](https://flutter.dev/)

An enterprise-grade, dual-platform security analytics framework designed to proactively detect, analyze, and neutralize modern social engineering attacks across both web and mobile environments.

---

## 🌐 Quick Access & Live Deployments

- **🌍 Production Website**: [https://secureai-7wgj.onrender.com](https://secureai-7wgj.onrender.com)
- **📽 Video Demonstration**: [Watch SecureAI in Action on LinkedIn](https://www.linkedin.com/posts/sai-teja-kokala-245a12299_ai-cybersecurity-machinelearning-ugcPost-7476167691737714688-QWWw)
- **📲 Direct Android App Downloads**:
  - **Universal Fat APK (Guaranteed for all devices)**: [`app-release.apk`](https://secureai-7wgj.onrender.com/media/app-release.apk) | Local: [`SecureAI_Web/media/app-release.apk`](./SecureAI_Web/media/app-release.apk) *(54 MB - All ABIs: ARMv7 32-bit, ARM64-v8a, x86_64 across Android 5.0 to 16)*
  - **Lightweight 64-bit APK (Modern smartphones)**: [`app-arm64-v8a-release.apk`](https://secureai-7wgj.onrender.com/media/app-arm64-v8a-release.apk) | Local: [`SecureAI_Web/media/app-arm64-v8a-release.apk`](./SecureAI_Web/media/app-arm64-v8a-release.apk) *(20.2 MB - 64-bit ARM smartphones)*
  - **32-bit Legacy APK (Older phones)**: [`app-armeabi-v7a-release.apk`](https://secureai-7wgj.onrender.com/media/app-armeabi-v7a-release.apk) | Local: [`SecureAI_Web/media/app-armeabi-v7a-release.apk`](./SecureAI_Web/media/app-armeabi-v7a-release.apk) *(17.6 MB - 32-bit ARM smartphones)*
  - **x86_64 Android Emulator APK**: [`app-x86_64-release.apk`](https://secureai-7wgj.onrender.com/media/app-x86_64-release.apk) | Local: [`SecureAI_Web/media/app-x86_64-release.apk`](./SecureAI_Web/media/app-x86_64-release.apk) *(21.6 MB - Android Studio emulators & ChromeOS)*

> [!NOTE]
> **Cloud Server Spin-Up Latency**: The cloud backend is hosted on Render's free tier. When the server is in an idle sleep state, the initial wake-up request may take approximately **60–75 seconds** (measured cold start: ~75s). Once awake, subsequent requests respond in under **1 second** (measured warm transfer: ~0.77s). The mobile app includes a built-in `ServerWakeOverlay` that monitors connection readiness.

---

## 📦 Project Architecture & In-Detail Subsystem Guides

The project repository is structured into two dedicated codebases:

```
SecureAI-main/
├── README.md                      # Root project overview (this file)
├── SecureAI_Web/                  # Full-stack Django web application & AI pipelines
│   ├── README.md                  # Detailed Web Platform Documentation & Screenshots
│   ├── manage.py                  # Django administrative script
│   ├── media/                     # Stored assets, ML models (.pkl), and APK downloads
│   │   ├── app-arm64-v8a-release.apk # 64-bit optimized APK build (20.2 MB)
│   │   ├── app-armeabi-v7a-release.apk # 32-bit legacy APK build (17.6 MB)
│   │   ├── app-x86_64-release.apk    # Emulator APK build (21.6 MB)
│   │   └── app-release.apk           # Universal all-device APK build (54.2 MB)
│   ├── templates/                 # Liquid glass HTML templates
│   └── users/                     # Security detection views and models
└── SecureAI_Mobile_app/           # Cross-platform Flutter Android mobile application
    ├── README.md                  # Detailed Mobile Application Documentation & Architecture
    ├── lib/                       # Flutter screens, liquid glass widgets, and themes
    ├── android/                   # Native Android manifest, mipmaps, and Gradle configuration
    └── screenshots/               # High-resolution mobile application walkthrough
```

### 📖 Detailed In-Depth Documentation:
- **For full Web documentation, ML training steps, setup commands, and web screenshots**:  
  👉 Read the [**SecureAI Web Platform README**](./SecureAI_Web/README.md)
- **For full Mobile documentation, Flutter architecture, supported Android ABIs, and mobile screenshots**:  
  👉 Read the [**SecureAI Mobile Application README**](./SecureAI_Mobile_app/README.md)

---

## 🚀 Running from a Fresh Repository Clone

If you just cloned or pulled this repository, follow these quick-start commands for both the web backend and mobile client:

### 1. 🌐 Web Application (Django & AI Engine)

> [!IMPORTANT]
> **Why `python3 manage.py runserver` fails with `ModuleNotFoundError: No module named 'django'`**:
> On macOS and Linux, the system global Python (`/usr/bin/python3`) does not include project libraries. Always create and activate your project virtual environment first!

```bash
# Step 1: Navigate to the web folder
cd SecureAI-main/SecureAI_Web

# Step 2: Create a virtual environment (one-time setup)
python3 -m venv ../.venv

# Step 3: Activate the virtual environment
source ../.venv/bin/activate       # macOS / Linux
# On Windows: ..\.venv\Scripts\activate

# Step 4: Install all required Python dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Step 5: Run database migrations
python manage.py migrate

# Step 6: Start the local development server
python manage.py runserver
```
Visit **`http://127.0.0.1:8000/`** in your browser.

---

### 2. 📱 Mobile Application (Flutter Android Client)

```bash
# Step 1: Navigate to the mobile app folder
cd SecureAI-main/SecureAI_Mobile_app

# Step 2: Fetch Flutter packages
flutter pub get

# Step 3: Run on connected Android device or emulator
flutter run

# Step 4 (Optional): Build split release APKs
flutter build apk --split-per-abi
```
Generated APK outputs:
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (20.2 MB - 64-bit phones)
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` (17.6 MB - 32-bit legacy)
- `build/app/outputs/flutter-apk/app-x86_64-release.apk` (21.6 MB - Emulators)

---

## 🚀 Core Security Features

SecureAI provides synchronized threat protection across both the Web portal and the Android application:

### 1. 📩 SMS Spam & Smishing Detector
- **AI Engine**: Natural Language Processing via Google Gemini 2.5 Flash.
- **Capability**: Real-time classification of incoming text messages into **Spam** or **Ham**, providing granular reasoning and identifying smishing tactics.

### 2. 🔗 QR Code & Quishing Threat Scanner
- **Computer Vision & AI**: OpenCV matrix decoding paired with Gemini 2.5 Flash link analysis.
- **Live Camera & Upload**: Supports live camera capture with real-time viewfinder reticle and automatic device camera detection, with seamless fallback to image upload.
- **Threat Verdict**: Classifies embedded URLs as **Safe**, **Phishing**, or **Malicious**, alerting users prior to browser navigation.

### 3. 📧 Email Phishing Analyzer
- **Psychological Profiling**: Deep analysis of urgency manipulation, false authority, and domain impersonation.
- **Verdict & Indicators**: Returns confidence scores along with categorized red flag indicators.

### 4. 🛡️ Password Strength & Breach Auditor
- **Zero-Knowledge Security**: SHA-1 k-Anonymity prefix hashing communicating with the "Have I Been Pwned" database.
- **Comprehensive Audit**: Evaluates character complexity and verifies credentials have not been compromised in global data leaks without transmitting plain-text passwords.

### 5. 🧠 User Behavioral Anomaly Profiling
- **Machine Learning**: Multi-classifier ensemble featuring Logistic Regression, Random Forest, and XGBoost.
- **Session Intelligence**: Predicts account takeover anomalies by evaluating multidimensional parameters (`login_hour`, `ip_score`).
- **Interactive Training**: In-app retraining pipeline with real-time confusion matrix heatmap visualizations.

### 6. 👥 Administrative Governance & Identity Management
- **Access Control**: Administrative dashboard with user activation, deactivation, and deletion controls.
- **Live Status Monitoring**: Real-time database heartbeat indicator with pulsating visual alerts.
- **Zero-Delay OTP**: Password recovery powered by the Resend HTTPS API.

---

## 📱 Mobile APK Download Guide & Device Compatibility

Why do we provide both a **Universal Fat APK** and a **Split ABI APK**?

| APK Package | Size | Architecture (ABI) | Compatible Devices |
| :--- | :--- | :--- | :--- |
| **`app-release.apk`** *(Universal Build)* | **~54 MB** | **All Architectures** (`armeabi-v7a`, `arm64-v8a`, `x86_64`) | **100% of Android devices** (Android 5.0 Lollipop to Android 16), older 32-bit phones, tablets, and emulators |
| **`app-arm64-v8a-release.apk`** *(Targeted Build)* | **~20.2 MB** | **64-bit ARM only** (`arm64-v8a`) | Modern 64-bit Android smartphones (Snapdragon, MediaTek, Exynos, Tensor) |
| **`app-armeabi-v7a-release.apk`** *(Targeted Build)* | **~17.6 MB** | **32-bit ARM only** (`armeabi-v7a`) | Legacy 32-bit smartphones and low-cost Android Go devices |
| **`app-x86_64-release.apk`** *(Emulator Build)* | **~21.6 MB** | **64-bit x86 only** (`x86_64`) | Android Studio Emulators, Chromebooks (ChromeOS), and Windows Subsystem for Android |

> [!TIP]
> **Recommendation**: If you are unsure of your Android device's processor architecture, download **[`app-release.apk`](https://secureai-7wgj.onrender.com/media/app-release.apk)** to ensure guaranteed installation across all phone brands and Android versions. For modern phones with fast downloads, **[`app-arm64-v8a-release.apk`](https://secureai-7wgj.onrender.com/media/app-arm64-v8a-release.apk)** is 60% lighter!

---

## 🛠️ Technology Stack Summary

- **Web Backend**: Python 3.10+, Django 5.0.9, Gunicorn, WhiteNoise
- **Web Frontend**: HTML5, Vanilla CSS Glassmorphism, Tailwind CSS, Font Awesome 6
- **Mobile Client**: Flutter 3.x, Dart 3.x, Google Fonts (Outfit), Custom Constellation Painter
- **AI & NLP**: Google Gemini 2.5 Flash, LangChain Core
- **Machine Learning**: Scikit-learn, XGBoost, NumPy, Pandas
- **Computer Vision**: OpenCV (Python), CameraX / ImagePicker (Mobile)
- **Databases**: SQLite (Development) & Neon Serverless PostgreSQL (Production)
- **Email Gateway**: Resend API (HTTPS Port 443)
- **Hosting**: Render Cloud Platform

---

## 👥 Authors & Developer

- **Kokala Sai Teja** - Developer, SecureAI Framework
- *Usage of AI in Prevention of Social Engineering Attacks*

---

© 2026 SecureAI. All rights reserved.
