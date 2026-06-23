
from django.shortcuts import render, redirect
from .models import RegisteredUser
from django.core.files.storage import FileSystemStorage

def register_view(request):
    msg = ''
    if request.method == 'POST':
        name = request.POST.get('name')
        email = request.POST.get('email')
        mobile = request.POST.get('mobile')
        password = request.POST.get('password')
        image = request.FILES.get('image')

        # Basic validation
        if not (name and email and mobile and password and image):
            msg = "All fields are required."
        else:
            # Save image manually
            fs = FileSystemStorage()
            filename = fs.save(image.name, image)
            img_url = fs.url(filename)

            # Save user with is_active=False
            RegisteredUser.objects.create(
                name=name,
                email=email,
                mobile=mobile,
                password=password,
                image=filename,
                is_active=False
            )
            msg = "Registered successfully! Wait for admin approval."

    return render(request, 'register.html', {'msg': msg})

from django.utils import timezone

from django.utils import timezone
import pytz

def user_login(request):
    msg = ''
    if request.method == 'POST':
        name = request.POST.get('name')
        password = request.POST.get('password')

        try:
            user = RegisteredUser.objects.get(name=name, password=password)
            if user.is_active:
                # Convert current time to IST
                ist = pytz.timezone('Asia/Kolkata')
                local_time = timezone.now().astimezone(ist)

                # Save user info in session
                request.session['user_id'] = user.id
                request.session['user_name'] = user.name
                request.session['user_image'] = user.image.url  # image URL
                request.session['login_time'] = local_time.strftime('%I:%M:%S %p')

                return redirect('user_homepage')
            else:
                msg = "Your account is not activated yet."
        except RegisteredUser.DoesNotExist:
            msg = "Invalid credentials."

    return render(request, 'user_login.html', {'msg': msg})

def admin_login(request):
    msg = ''
    if request.method == 'POST':
        name = request.POST.get('name')
        password = request.POST.get('password')

        if name == 'admin' and password == 'admin':
            return redirect('admin_home')
        else:
            msg = "Invalid admin credentials."

    return render(request, 'admin_login.html', {'msg': msg})

def admin_home(request):
    return render(request, 'admin_home.html')
    
def admin_dashboard(request):
    users = RegisteredUser.objects.all()
    return render(request, 'admin_dashboard.html', {'users': users})

def activate_user(request, user_id):
    user = RegisteredUser.objects.get(id=user_id)
    user.is_active = True
    user.save()
    return redirect('admin_dashboard')

def deactivate_user(request, user_id):
    user = RegisteredUser.objects.get(id=user_id)
    user.is_active = False
    user.save()
    return redirect('admin_dashboard')

def delete_user(request, user_id):
    user = RegisteredUser.objects.get(id=user_id)
    user.delete()
    return redirect('admin_dashboard')



def home(request):
    return render(request, 'home.html')

def user_homepage(request):
    if 'user_id' not in request.session:
        # User not logged in, redirect to login page
        return redirect('user_login')

    user_name = request.session.get('user_name')
    user_image = request.session.get('user_image')
    login_time = request.session.get('login_time')

    context = {
        'user_name': user_name,
        'user_image': user_image,
        'login_time': login_time,
    }
    return render(request, 'users/user_homepage.html', context)

def user_logout(request):
    request.session.flush()  # Clears all session data
    return redirect('user_login')



import random
from django.shortcuts import render, redirect
from django.core.mail import send_mail
from django.contrib import messages
from .models import RegisteredUser

otp_storage = {}  # Temporary dictionary to store OTPs

def send_otp(email):
    otp = random.randint(100000, 999999)  # Generate a 6-digit OTP
    otp_storage[email] = otp

    subject = "Password Reset OTP"
    message = f"Your OTP for password reset is: {otp}"

    from_email = getattr(settings, 'EMAIL_HOST_USER', None)
    if not from_email:
        raise EnvironmentError("EMAIL_HOST_USER is missing. Set it in .env.")

    try:
        send_mail(subject, message, from_email, [email])
    except Exception as exc:
        # For now, re-raise (so Django debug page shows details)
        # You can later replace this with a user-friendly message.
        raise
    return otp

def forgot_password(request):
    if request.method == "POST":
        email = request.POST.get("email")

        if RegisteredUser.objects.filter(email=email).exists():
            send_otp(email)
            request.session["reset_email"] = email  # Store email in session
            return redirect("verify_otp")
        else:
            messages.error(request, "Email not registered!")

    return render(request, "forgot_password.html")

def verify_otp(request):
    if request.method == "POST":
        otp_entered = request.POST.get("otp")
        email = request.session.get("reset_email")

        if otp_storage.get(email) and str(otp_storage[email]) == otp_entered:
            return redirect("reset_password")
        else:
            messages.error(request, "Invalid OTP!")

    return render(request, "verify_otp.html")

def reset_password(request):
    if request.method == "POST":
        new_password = request.POST.get("new_password")
        email = request.session.get("reset_email")

        if RegisteredUser.objects.filter(email=email).exists():
            user = RegisteredUser.objects.get(email=email)
            user.password = new_password  # Updating password
            user.save()
            messages.success(request, "Password reset successful! Please log in.")
            return redirect("user_login")

    return render(request, "reset_password.html")



#### ACTUAL PROJECT CODE STARTS HERE ####


from pathlib import Path
from django.shortcuts import render
from langchain_core.prompts import PromptTemplate
from langchain_google_genai import ChatGoogleGenerativeAI
from dotenv import load_dotenv
import os

# Load environment variables from .env in the project root
BASE_DIR = Path(__file__).resolve().parent.parent
dotenv_path = BASE_DIR / '.env'
load_dotenv(dotenv_path=dotenv_path)


def get_env_value(key: str):
    value = os.environ.get(key)
    if value:
        return value

    if dotenv_path.exists():
        for line in dotenv_path.read_text(encoding='utf-8').splitlines():
            if line.strip().startswith(f"{key}="):
                _, raw_value = line.split('=', 1)
                raw_value = raw_value.strip().strip('"').strip("'")
                if raw_value:
                    os.environ[key] = raw_value
                    return raw_value
    return None


def get_google_llm(**kwargs):
    api_key = get_env_value("GOOGLE_API_KEY")
    if not api_key:
        raise EnvironmentError("GOOGLE_API_KEY environment variable is missing")
    return ChatGoogleGenerativeAI(model="models/gemini-2.5-flash", **kwargs)


def get_spam_chain():
    prompt = PromptTemplate(
        input_variables=["sms"],
        template="""
You are an expert spam filter.
Classify the following SMS message as either 'spam' or 'ham' (not spam).
Message: "{sms}"
Respond only with 'spam' or 'ham' and give a one-line explanation.
"""
    )
    return prompt | get_google_llm()


def detect_spam(request):
    result = None
    explanation = None
    error = None
    message = ''

    if request.method == 'POST':
        message = request.POST.get('message', '').strip()
        if not message:
            error = "Please enter an SMS message to check."
        else:
            try:
                chain = get_spam_chain()
                response = chain.invoke({"sms": message}).content

                # Extract classification & explanation
                if "spam" in response.lower():
                    result = "Spam"
                else:
                    result = "Ham"
                explanation = response.strip()
            except EnvironmentError as exc:
                error = str(exc)
            except Exception as exc:
                error = f"Spam detection failed: {exc}"

    return render(request, 'users/detect.html', {
        'result': result,
        'explanation': explanation,
        'error': error,
        'message': message,
    })



# ANOMALY DETECTION
# NOTE: Heavy ML imports are kept inside functions (not global scope)
# to prevent Gunicorn workers from running out of memory on startup.

# Training View
def train_anomaly_model(request):
    # --- lazy imports: only loaded when this view is actually called ---
    import os
    import joblib
    import pandas as pd
    import numpy as np
    from django.conf import settings
    from sklearn.model_selection import train_test_split
    from sklearn.metrics import classification_report, confusion_matrix
    from sklearn.linear_model import LogisticRegression
    from sklearn.ensemble import RandomForestClassifier
    from xgboost import XGBClassifier
    # ------------------------------------------------------------------

    df = pd.read_csv(os.path.join(settings.MEDIA_ROOT, 'behavior_anomaly_dataset.csv'))
    df['label_encoded'] = df['label'].map({'normal': 0, 'anomaly': 1})

    X = df[['login_hour', 'ip_score']]
    y = df['label_encoded']
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    models = {
        "Logistic Regression": LogisticRegression(max_iter=1000),
        "Random Forest": RandomForestClassifier(n_estimators=100, random_state=42),
        "XGBoost": XGBClassifier(eval_metric='logloss', random_state=42)
    }

    combined_data = []

    for name, model in models.items():
        model.fit(X_train, y_train)
        y_pred = model.predict(X_test)

        # Save model
        model_path = os.path.join(settings.MEDIA_ROOT, 'models', f"{name.replace(' ', '_').lower()}.pkl")
        joblib.dump(model, model_path)

        # Classification Report
        report_text = classification_report(y_test, y_pred, target_names=['Normal', 'Anomaly'])

        # Confusion Matrix
        cm = confusion_matrix(y_test, y_pred)
        tn, fp, fn, tp = cm.ravel()

        # Append both report and raw counts (rendered via HTML/CSS heatmap)
        combined_data.append({
            'name': name,
            'report': report_text,
            'tn': int(tn),
            'fp': int(fp),
            'fn': int(fn),
            'tp': int(tp),
        })

    return render(request, 'users/train_anomaly.html', {'combined_data': combined_data})


# Prediction View
def predict_anomaly(request):
    import os
    import joblib
    from django.conf import settings

    prediction = None
    if request.method == 'POST':
        login_hour = int(request.POST['login_hour'])
        ip_score = float(request.POST['ip_score'])

        model_path = os.path.join(settings.MEDIA_ROOT, 'models', 'random_forest.pkl')
        model = joblib.load(model_path)
        pred = model.predict([[login_hour, ip_score]])[0]
        prediction = 'Normal' if pred == 0 else 'Anomaly'

    return render(request, 'users/predict_anomaly.html', {'prediction': prediction})


# QR
# views.py

import os
import cv2
from django.conf import settings
from django.shortcuts import render
from django.core.files.storage import FileSystemStorage

from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.prompts import PromptTemplate
from langchain_core.output_parsers import StrOutputParser

# 🔑 Set your Gemini 2.5 Flash API key from environment variable
# Already set above, no need to duplicate

# 📌 Function to decode QR using OpenCV
def decode_qr_opencv(image_path):
    """Robust QR decoder.

    me-qr.com outputs often fail with plain cv2.QRCodeDetector().
    This function tries multiple strategies:
    - detectAndDecodeMulti
    - detectAndDecode
    - preprocessing + retries
    - pyzbar fallback
    """
    img = cv2.imread(image_path)
    if img is None:
        return None

    def _try_decode(frame):
        detector = cv2.QRCodeDetector()

        # 1) Multi-code decoder
        try:
            ok, decoded_info, _, _ = detector.detectAndDecodeMulti(frame)
            if ok and decoded_info:
                for d in decoded_info:
                    if d:
                        return d
        except Exception:
            pass

        # 2) Single-code decoder
        try:
            data, _, _ = detector.detectAndDecode(frame)
            if data:
                return data
        except Exception:
            pass

        return None

    # 1st pass (raw)
    data = _try_decode(img)
    if data:
        return data

    # Preprocess: grayscale + blur + adaptive threshold
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    gray = cv2.GaussianBlur(gray, (5, 5), 0)
    th = cv2.adaptiveThreshold(
        gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 11, 2
    )

    # 2nd pass (binarized)
    data = _try_decode(th)
    if data:
        return data

    # 3rd pass (upscaled)
    scale = 2
    up = cv2.resize(
        img,
        (img.shape[1] * scale, img.shape[0] * scale),
        interpolation=cv2.INTER_CUBIC,
    )
    data = _try_decode(up)
    if data:
        return data

    # 4th pass: pyzbar fallback (often more tolerant)
    try:
        from pyzbar.pyzbar import decode as zbar_decode

        z = zbar_decode(img)
        if z:
            return z[0].data.decode("utf-8", errors="ignore")
    except Exception:
        pass

    return None

# 📌 LangChain + Gemini-based URL classification
def classify_url_with_langchain(url):
    llm = get_google_llm(temperature=0)
    
    template = """You are a cybersecurity expert.
    Classify the following URL as:
    - Safe
    - Phishing
    - Malicious

    URL: {url}

    Only reply with one of: Safe / Phishing / Malicious and a short reason.
    """
    prompt = PromptTemplate.from_template(template)
    chain = prompt | llm | StrOutputParser()

    result = chain.invoke({"url": url})
    return result

# 📌 Main QR scan view
def qr_scan_view(request):
    if request.method == 'POST' and request.FILES['qr_image']:
        img = request.FILES['qr_image']
        fs = FileSystemStorage()
        filename = fs.save(img.name, img)
        uploaded_file_path = fs.path(filename)

        # Step 1: Decode QR
        decoded_url = decode_qr_opencv(uploaded_file_path)

        # Step 2: Classify via Gemini + LangChain
        if decoded_url:
            classification = classify_url_with_langchain(decoded_url)
        else:
            classification = "❌ QR Code not detected."

        return render(request, 'users/qr_result.html', {
            'qr_data': decoded_url,
            'classification': classification
        })

    return render(request, 'users/qr_form.html')


# 📌 Password Strength & Breach Analyzer
import hashlib
import requests

def password_analyzer(request):
    result = None
    if request.method == 'POST':
        password = request.POST.get('password', '')
        
        # 1. Check strength
        length = len(password)
        has_upper = any(c.isupper() for c in password)
        has_lower = any(c.islower() for c in password)
        has_digit = any(c.isdigit() for c in password)
        has_special = any(not c.isalnum() for c in password)
        
        score = sum([length >= 8, length >= 12, has_upper, has_lower, has_digit, has_special])
        if score <= 2:
            strength = "Weak"
            color = "red-500"
        elif score <= 4:
            strength = "Moderate"
            color = "yellow-400"
        else:
            strength = "Strong"
            color = "green-500"
            
        # 2. Check Have I Been Pwned API (k-Anonymity)
        sha1_pwd = hashlib.sha1(password.encode('utf-8')).hexdigest().upper()
        prefix, suffix = sha1_pwd[:5], sha1_pwd[5:]
        
        pwned_count = 0
        try:
            resp = requests.get(f"https://api.pwnedpasswords.com/range/{prefix}", timeout=5)
            if resp.status_code == 200:
                hashes = (line.split(':') for line in resp.text.splitlines())
                for h, count in hashes:
                    if h == suffix:
                        pwned_count = int(count)
                        break
        except Exception:
            pass
            
        result = {
            'password_length': length, # Don't send plaintext back to UI for security best practice, but maybe as masked
            'masked_password': '*' * length,
            'strength': strength,
            'color': color,
            'pwned_count': pwned_count,
            'has_upper': has_upper,
            'has_lower': has_lower,
            'has_digit': has_digit,
            'has_special': has_special,
        }
        
    return render(request, 'users/password_analyzer.html', {'result': result})

# 📌 Global Pages
def introduction(request):
    return render(request, 'introduction.html')

def contact(request):
    return render(request, 'contact.html')

# 📌 Email Phishing Analyzer
def email_phishing_analyzer(request):
    result = None
    explanation = None
    error = None
    email_text = ''

    if request.method == 'POST':
        email_text = request.POST.get('email_text', '').strip()
        if not email_text:
            error = "Please enter an email body to analyze."
        else:
            try:
                from langchain_core.prompts import PromptTemplate
                llm = get_google_llm()
                prompt = PromptTemplate(
                    input_variables=["email"],
                    template="""You are an expert cybersecurity analyst.
Analyze the following email for phishing or social engineering attempts.
Email: "{email}"
First, reply with exactly 'Phishing', 'Suspicious', or 'Safe' on the first line.
Then, provide a brief bulleted explanation of your findings and any red flags."""
                )
                chain = prompt | llm
                response = chain.invoke({"email": email_text}).content
                
                parts = response.strip().split('\n', 1)
                classification = parts[0].strip().replace('*', '').replace('#', '').strip()
                if len(parts) > 1:
                    explanation = parts[1].strip()
                else:
                    explanation = "No detailed explanation provided."
                
                result = classification
            except Exception as exc:
                error = f"Analysis failed: {exc}"

    return render(request, 'users/email_phishing.html', {
        'result': result,
        'explanation': explanation,
        'error': error,
        'email_text': email_text,
    })
