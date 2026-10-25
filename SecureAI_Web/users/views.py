
from functools import wraps
from django.shortcuts import render, redirect
from django.contrib import messages
from django.views.decorators.csrf import csrf_exempt
from .models import RegisteredUser
from django.core.files.storage import FileSystemStorage

# Authentication Decorators to handle forbidden / unauthorized access cleanly
def user_required(view_func):
    @wraps(view_func)
    def _wrapped_view(request, *args, **kwargs):
        is_json = request.headers.get('Accept') == 'application/json' or request.content_type == 'application/json'
        user_id = request.session.get('user_id')
        if not user_id:
            if is_json:
                from django.http import JsonResponse
                return JsonResponse({'success': False, 'message': 'Authentication required.'}, status=401)
            return redirect('user_login')

        try:
            user = RegisteredUser.objects.get(id=user_id)
            if not user.is_active:
                request.session.flush()
                if is_json:
                    from django.http import JsonResponse
                    return JsonResponse({'success': False, 'message': 'Account is inactive. Please contact admin.'}, status=403)
                return redirect('user_login')
        except RegisteredUser.DoesNotExist:
            request.session.flush()
            if is_json:
                from django.http import JsonResponse
                return JsonResponse({'success': False, 'message': 'Account no longer exists.'}, status=401)
            return redirect('user_login')

        return view_func(request, *args, **kwargs)
    return _wrapped_view

def admin_required(view_func):
    @wraps(view_func)
    def _wrapped_view(request, *args, **kwargs):
        if not request.session.get('is_admin'):
            return redirect('admin_login')
        return view_func(request, *args, **kwargs)
    return _wrapped_view

@csrf_exempt
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
        elif RegisteredUser.objects.filter(name=name).exists():
            msg = "already exist keep any other username."
        else:
            # Read image bytes and encode to base64 Data URI for permanent persistent storage
            b64_str = ''
            if image:
                try:
                    img_bytes = image.read()
                    image.seek(0)
                    content_type = getattr(image, 'content_type', 'image/jpeg') or 'image/jpeg'
                    b64_str = f"data:{content_type};base64," + base64.b64encode(img_bytes).decode('utf-8')
                except Exception:
                    b64_str = ''

            # Save user with is_active=False. Both file on disk and base64 in DB are saved.
            RegisteredUser.objects.create(
                name=name,
                email=email,
                mobile=mobile,
                password=password,
                image=image,
                image_base64=b64_str,
                is_active=False
            )
            msg = "Registered successfully! Wait for admin approval."

    return render(request, 'register.html', {'msg': msg})

from django.utils import timezone
import pytz

@csrf_exempt
def user_login(request):
    msg = ''
    is_json = request.headers.get('Accept') == 'application/json' or request.content_type == 'application/json'
    if request.method == 'POST':
        name = request.POST.get('name')
        password = request.POST.get('password')

        try:
            user = RegisteredUser.objects.get(name=name, password=password)
            if user.is_active:
                # Convert current time to IST
                ist = pytz.timezone('Asia/Kolkata')
                local_time = timezone.now().astimezone(ist)

                img_url = ''
                if user.image:
                    try:
                        img_url = user.image.url
                    except Exception:
                        img_url = ''

                active_img = user.image_base64 if user.image_base64 else img_url

                # Save user info in session
                request.session['user_id'] = user.id
                request.session['user_name'] = user.name
                request.session['user_image'] = img_url
                request.session['user_image_base64'] = user.image_base64
                request.session['login_time'] = local_time.strftime('%I:%M:%S %p')

                if is_json:
                    return JsonResponse({
                        'success': True,
                        'message': 'Login successful!',
                        'user_name': user.name,
                        'user_image': active_img,
                        'login_time': local_time.strftime('%I:%M:%S %p'),
                    })

                return redirect('user_homepage')
            else:
                msg = "Your account is not activated yet."
                if is_json:
                    return JsonResponse({'success': False, 'message': msg}, status=403)
        except RegisteredUser.DoesNotExist:
            msg = "Invalid credentials."
            if is_json:
                return JsonResponse({'success': False, 'message': msg}, status=401)

    return render(request, 'user_login.html', {'msg': msg})

@csrf_exempt
def admin_login(request):
    msg = ''
    if request.method == 'POST':
        name = request.POST.get('name')
        password = request.POST.get('password')

        if name == 'admin' and password == 'admin':
            request.session['is_admin'] = True
            return redirect('admin_home')
        else:
            msg = "Invalid admin credentials."

    return render(request, 'admin_login.html', {'msg': msg})

@admin_required
def admin_home(request):
    return render(request, 'admin_home.html')

@admin_required
def admin_dashboard(request):
    users = RegisteredUser.objects.all().order_by('-id')
    is_json = request.headers.get('Accept') == 'application/json' or request.content_type == 'application/json'
    if is_json:
        user_list = []
        for u in users:
            img_url = ''
            if u.image:
                try:
                    img_url = u.image.url
                except Exception:
                    pass
            if not img_url and u.image_base64:
                img_url = u.image_base64
            user_list.append({
                'id': u.id,
                'name': u.name,
                'email': u.email,
                'mobile': u.mobile,
                'image_url': img_url,
                'is_active': u.is_active,
            })
        return JsonResponse({'success': True, 'users': user_list})
    return render(request, 'admin_dashboard.html', {'users': users})

@admin_required
def activate_user(request, user_id):
    try:
        user = RegisteredUser.objects.get(id=user_id)
        user.is_active = True
        user.save()
    except RegisteredUser.DoesNotExist:
        pass
    return redirect('admin_dashboard')

@admin_required
def deactivate_user(request, user_id):
    try:
        user = RegisteredUser.objects.get(id=user_id)
        user.is_active = False
        user.save()
    except RegisteredUser.DoesNotExist:
        pass
    return redirect('admin_dashboard')

@admin_required
def delete_user(request, user_id):
    is_json = request.headers.get('Accept') == 'application/json' or request.content_type == 'application/json'
    from django.http import JsonResponse
    try:
        user = RegisteredUser.objects.get(id=user_id)
        from .utils import delete_user_account
        success, msg = delete_user_account(user, otp_storage_ref=otp_storage)
        if not success:
            if is_json:
                return JsonResponse({'success': False, 'message': msg}, status=500)
            messages.error(request, f"Failed to delete user: {msg}")
            return redirect('admin_dashboard')

        if is_json:
            return JsonResponse({'success': True, 'message': f"User {user_id} deleted successfully."})
        messages.success(request, f"User {user.name} has been permanently deleted.")
    except RegisteredUser.DoesNotExist:
        if is_json:
            return JsonResponse({'success': False, 'message': 'User does not exist or has already been deleted.'}, status=404)
        messages.warning(request, "User does not exist or has already been deleted.")

    return redirect('admin_dashboard')

def home(request):
    return render(request, 'home.html')

@user_required
def user_homepage(request):
    user_name = request.session.get('user_name')
    user_image = request.session.get('user_image')
    user_image_b64 = request.session.get('user_image_base64')
    if not user_image_b64 and request.session.get('user_id'):
        u = RegisteredUser.objects.filter(id=request.session.get('user_id')).first()
        if u and u.image_base64:
            user_image_b64 = u.image_base64
            request.session['user_image_base64'] = user_image_b64
    active_image = user_image_b64 or user_image
    login_time = request.session.get('login_time')

    is_json = request.headers.get('Accept') == 'application/json' or request.content_type == 'application/json'
    if is_json:
        return JsonResponse({
            'success': True,
            'user_name': user_name,
            'user_image': active_image,
            'login_time': login_time,
        })

    context = {
        'user_name': user_name,
        'user_image': active_image,
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
from django.conf import settings

otp_storage = {}  # Temporary dictionary to store OTPs

def send_otp(email):
    from .utils import generate_six_digit_otp, send_secure_otp_email
    otp = generate_six_digit_otp()
    
    success = send_secure_otp_email(email, otp)
    if not success:
        return None, "Failed to send email. Check Render Environment Variables (RESEND_API_KEY)."
        
    otp_storage[email] = otp
    return otp, None

@csrf_exempt
def forgot_password(request):
    is_json = request.headers.get('Accept') == 'application/json' or request.content_type == 'application/json'
    if request.method == "POST":
        email = (request.POST.get("email") or '').strip()

        if RegisteredUser.objects.filter(email=email).exists():
            otp, error = send_otp(email)
            if error:
                if is_json:
                    return JsonResponse({'success': False, 'message': error}, status=500)
                messages.error(request, error)
            else:
                request.session["reset_email"] = email  # Store email in session
                if is_json:
                    return JsonResponse({'success': True, 'message': 'Verification OTP sent to your registered email.'})
                return redirect("verify_otp")
        else:
            if is_json:
                return JsonResponse({'success': False, 'message': 'Email not registered!'}, status=404)
            messages.error(request, "Email not registered!")

    return render(request, "forgot_password.html")

@csrf_exempt
def verify_otp(request):
    is_json = request.headers.get('Accept') == 'application/json' or request.content_type == 'application/json'
    if request.method == "POST":
        otp_entered = (request.POST.get("otp") or '').strip()
        email = (request.POST.get("email") or '').strip() or request.session.get("reset_email")

        if otp_storage.get(email) and str(otp_storage[email]) == otp_entered:
            if is_json:
                return JsonResponse({'success': True, 'message': 'OTP verified successfully!'})
            return redirect("reset_password")
        else:
            if is_json:
                return JsonResponse({'success': False, 'message': 'Invalid OTP code!'}, status=400)
            messages.error(request, "Invalid OTP!")

    return render(request, "verify_otp.html")

@csrf_exempt
def reset_password(request):
    is_json = request.headers.get('Accept') == 'application/json' or request.content_type == 'application/json'
    if request.method == "POST":
        new_password = (request.POST.get("new_password") or '').strip()
        email = (request.POST.get("email") or '').strip() or request.session.get("reset_email")

        if RegisteredUser.objects.filter(email=email).exists():
            user = RegisteredUser.objects.get(email=email)
            user.password = new_password  # Updating password
            user.save()
            otp_storage.pop(email, None)
            if is_json:
                return JsonResponse({'success': True, 'message': 'Password reset successful! Please log in.'})
            messages.success(request, "Password reset successful! Please log in.")
            return redirect("user_login")
        else:
            if is_json:
                return JsonResponse({'success': False, 'message': 'User not found or session expired.'}, status=404)
            messages.error(request, "User not found or session expired.")

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
    return ChatGoogleGenerativeAI(model="models/gemini-2.5-flash", max_retries=5, timeout=0, **kwargs)


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


@csrf_exempt
@user_required
def detect_spam(request):
    result = None
    explanation = None
    error = None
    message = ''
    is_json = 'application/json' in request.headers.get('Accept', '') or request.content_type == 'application/json'

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

        if is_json:
            if error:
                return JsonResponse({'success': False, 'message': error}, status=400)
            return JsonResponse({'success': True, 'result': result, 'explanation': explanation})

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
@csrf_exempt
@user_required
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
        model_path = os.path.join(settings.MEDIA_ROOT, 'models', f"{name.replace(' ', '_').lower()}.pkl")
        
        if os.path.exists(model_path):
            model = joblib.load(model_path)
        else:
            model.fit(X_train, y_train)
            os.makedirs(os.path.dirname(model_path), exist_ok=True)
            joblib.dump(model, model_path)
            
        y_pred = model.predict(X_test)

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

    is_json = 'application/json' in request.headers.get('Accept', '') or request.content_type == 'application/json'
    if is_json:
        return JsonResponse({'success': True, 'models': combined_data})

    return render(request, 'users/train_anomaly.html', {'combined_data': combined_data})


# Prediction View
@csrf_exempt
@user_required
def predict_anomaly(request):
    is_json = request.headers.get('Accept') == 'application/json' or request.content_type == 'application/json'
    import os
    import joblib
    from django.conf import settings

    prediction = None
    error = None
    if request.method == 'POST':
        try:
            raw_hour = request.POST.get('login_hour', '').strip()
            raw_score = request.POST.get('ip_score', '').strip()
            if not raw_hour or not raw_score:
                error = "Please fill in both login hour and IP score."
            else:
                login_hour = int(raw_hour)
                ip_score = float(raw_score)

                model_path = os.path.join(settings.MEDIA_ROOT, 'models', 'random_forest.pkl')
                if not os.path.exists(model_path):
                    import pandas as pd
                    from sklearn.ensemble import RandomForestClassifier
                    df = pd.read_csv(os.path.join(settings.MEDIA_ROOT, 'behavior_anomaly_dataset.csv'))
                    df['label_encoded'] = df['label'].map({'normal': 0, 'anomaly': 1})
                    X = df[['login_hour', 'ip_score']]
                    y = df['label_encoded']
                    model = RandomForestClassifier(n_estimators=100, random_state=42)
                    model.fit(X, y)
                    os.makedirs(os.path.dirname(model_path), exist_ok=True)
                    joblib.dump(model, model_path)
                else:
                    model = joblib.load(model_path)

                pred = model.predict([[login_hour, ip_score]])[0]
                prediction = 'Normal' if pred == 0 else 'Anomaly'
        except ValueError:
            error = "Invalid numerical values. Login hour must be 0-23 and IP score must be 0.0-1.0."
        except Exception as exc:
            error = f"Prediction failed: {exc}"

        if is_json:
            if error:
                return JsonResponse({'success': False, 'message': error}, status=400)
            return JsonResponse({'success': True, 'prediction': prediction})

    return render(request, 'users/predict_anomaly.html', {
        'prediction': prediction,
        'error': error,
        'login_hour': request.POST.get('login_hour', '') if request.method == 'POST' else '',
        'ip_score': request.POST.get('ip_score', '') if request.method == 'POST' else '',
    })


# QR
import os
import cv2
from django.conf import settings
from django.shortcuts import render
from django.core.files.storage import FileSystemStorage

from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.prompts import PromptTemplate
from langchain_core.output_parsers import StrOutputParser

# 📌 Function to decode QR using OpenCV
def decode_qr_opencv(image_path):
    img = cv2.imread(image_path)
    if img is None:
        return None

    def _try_decode(frame):
        detector = cv2.QRCodeDetector()
        try:
            ok, decoded_info, _, _ = detector.detectAndDecodeMulti(frame)
            if ok and decoded_info:
                for d in decoded_info:
                    if d:
                        return d
        except Exception:
            pass

        try:
            data, _, _ = detector.detectAndDecode(frame)
            if data:
                return data
        except Exception:
            pass

        return None

    data = _try_decode(img)
    if data:
        return data

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    gray = cv2.GaussianBlur(gray, (5, 5), 0)
    th = cv2.adaptiveThreshold(
        gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 11, 2
    )

    data = _try_decode(th)
    if data:
        return data

    scale = 2
    up = cv2.resize(
        img,
        (img.shape[1] * scale, img.shape[0] * scale),
        interpolation=cv2.INTER_CUBIC,
    )
    data = _try_decode(up)
    if data:
        return data

    try:
        from pyzbar.pyzbar import decode as zbar_decode

        z = zbar_decode(img)
        if z:
            return z[0].data.decode("utf-8", errors="ignore")
    except Exception:
        pass

    return None

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
@csrf_exempt
@user_required
def qr_scan_view(request):
    is_json = 'application/json' in request.headers.get('Accept', '') or request.content_type == 'application/json'
    if request.method == 'POST':
        img = request.FILES.get('qr_image')
        if not img:
            if is_json:
                return JsonResponse({'success': False, 'message': 'Please select an image file to scan.'}, status=400)
            return render(request, 'users/qr_form.html', {'error': 'Please select an image file to scan.'})

        fs = FileSystemStorage()
        filename = fs.save(img.name, img)
        uploaded_file_path = fs.path(filename)

        try:
            decoded_url = decode_qr_opencv(uploaded_file_path)
            if decoded_url:
                classification = classify_url_with_langchain(decoded_url)
            else:
                classification = "❌ QR Code not detected."

            # Delete the temporary uploaded file to prevent storage leakage
            try:
                if os.path.exists(uploaded_file_path):
                    os.remove(uploaded_file_path)
            except Exception:
                pass

            if is_json:
                return JsonResponse({
                    'success': True,
                    'detected': bool(decoded_url),
                    'url': decoded_url or 'None',
                    'classification': classification
                })

            return render(request, 'users/qr_result.html', {
                'qr_data': decoded_url,
                'classification': classification
            })
        except Exception as exc:
            try:
                if os.path.exists(uploaded_file_path):
                    os.remove(uploaded_file_path)
            except Exception:
                pass
            if is_json:
                return JsonResponse({'success': False, 'message': f"QR scanning failed: {exc}"}, status=400)
            return render(request, 'users/qr_form.html', {'error': f"QR scanning failed: {exc}"})

    return render(request, 'users/qr_form.html')


# 📌 Password Strength & Breach Analyzer
import hashlib
import requests

@csrf_exempt
@user_required
def password_analyzer(request):
    result = None
    if request.method == 'POST':
        password = request.POST.get('password', '')
        
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
            'password_length': length,
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
@csrf_exempt
@user_required
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

# --- SECURE OTP INTEGRATION ---
from django.http import JsonResponse
from django.views.decorators.http import require_POST
from django.views.decorators.csrf import csrf_protect
from .utils import generate_six_digit_otp, send_secure_otp_email

@require_POST
@csrf_protect
def dispatch_verification_challenge(request):
    target_email = request.POST.get("email", "").strip()
    
    if not target_email:
        return JsonResponse({
            "status": "error", 
            "message": "Target registration parameter 'email' is required."
        }, status=400)
    
    generated_otp = generate_six_digit_otp()
    request.session["active_security_otp"] = generated_otp
    delivery_success = send_secure_otp_email(target_email, generated_otp)
    
    if delivery_success:
        return JsonResponse({
            "status": "success", 
            "message": "Authorization payload successfully issued via web API channel."
        })
    else:
        return JsonResponse({
            "status": "error", 
            "message": "Edge gateway delivery failure. Verify Render environment flags."
        }, status=500)

@require_POST
@csrf_protect
def confirm_verification_challenge(request):
    user_entry = request.POST.get("otp_entry", "").strip()
    cached_challenge = request.session.get("active_security_otp")
    
    if not cached_challenge:
        return JsonResponse({
            "status": "error", 
            "message": "Verification flow uninitialized or token expired."
        }, status=400)
        
    if user_entry == cached_challenge:
        del request.session["active_security_otp"]
        return JsonResponse({
            "status": "success", 
            "message": "Authentication token verified. Flow clear."
        })
    else:
        return JsonResponse({
            "status": "error", 
            "message": "Supplied passcode does not match target profile criteria."
        }, status=403)

# --- CUSTOM ERROR HANDLERS FOR FORBIDDEN / CSRF / 404 / 500 ---

def custom_403_view(request, exception=None):
    return render(request, '403.html', {'exception': exception}, status=403)

def custom_csrf_failure(request, reason=""):
    return render(request, '403.html', {
        'exception': 'Security verification failed (CSRF check mismatch). Please refresh the page and log in again.'
    }, status=403)

def custom_404_view(request, exception=None):
    return render(request, '404.html', status=404)

def custom_500_view(request):
    return render(request, '500.html', status=500)

from django.http import FileResponse, Http404
from django.shortcuts import redirect
import os
import shutil

def download_apk(request, apk_type=None):
    """Directly serves the freshly compiled Android APK from SecureAI_Mobile_app/build/app/outputs/flutter-apk/ (or synced SecureAI_Web/media/)"""
    target = request.GET.get('type', apk_type or 'v8')
    if target in ['universal', 'all', 'app-release.apk']:
        apk_filename = 'app-release.apk'
    else:
        apk_filename = 'app-arm64-v8a-release.apk'
    
    flutter_apk_path = os.path.join(str(settings.BASE_DIR.parent), 'SecureAI_Mobile_app', 'build', 'app', 'outputs', 'flutter-apk', apk_filename)
    media_apk_path = os.path.join(settings.MEDIA_ROOT, apk_filename)

    # Prioritize the fresh build from flutter-apk and synchronize to media
    target_path = None
    if os.path.exists(flutter_apk_path):
        target_path = flutter_apk_path
        if not os.path.exists(media_apk_path) or os.path.getmtime(flutter_apk_path) > os.path.getmtime(media_apk_path):
            try:
                shutil.copy2(flutter_apk_path, media_apk_path)
            except Exception:
                pass
    elif os.path.exists(media_apk_path):
        target_path = media_apk_path

    if target_path and os.path.exists(target_path):
        response = FileResponse(open(target_path, 'rb'), as_attachment=True, filename=apk_filename)
        response['Content-Type'] = 'application/vnd.android.package-archive'
        response['Content-Disposition'] = f'attachment; filename="{apk_filename}"'
        return response
    raise Http404(f"Android APK package ({apk_filename}) is currently unavailable. Please refresh in a moment.")

def favicon_view(request):
    """Directly serves favicon.png with HTTP 200 and image/png headers to guarantee visibility on Render and local"""
    candidates = [
        os.path.join(settings.BASE_DIR, 'static', 'favicon.png'),
        os.path.join(settings.BASE_DIR, 'staticfiles', 'favicon.png'),
        os.path.join(settings.MEDIA_ROOT, 'favicon.png'),
        os.path.join(str(settings.BASE_DIR.parent), 'SecureAI_Mobile_app', 'assets', 'images', 'app_icon.png'),
    ]
    for path in candidates:
        if os.path.exists(path):
            resp = FileResponse(open(path, 'rb'), content_type='image/png')
            resp['Cache-Control'] = 'public, max-age=86400'
            return resp
    raise Http404("Favicon not found")

def favicon_ico_view(request):
    """Directly serves favicon.ico with HTTP 200 and image/x-icon headers"""
    candidates = [
        os.path.join(settings.BASE_DIR, 'static', 'favicon.ico'),
        os.path.join(settings.BASE_DIR, 'staticfiles', 'favicon.ico'),
        os.path.join(settings.MEDIA_ROOT, 'favicon.ico'),
    ]
    for path in candidates:
        if os.path.exists(path):
            resp = FileResponse(open(path, 'rb'), content_type='image/x-icon')
            resp['Cache-Control'] = 'public, max-age=86400'
            return resp
    return favicon_view(request)



import base64
from pathlib import Path
from django.views.static import serve
from django.http import HttpResponse, Http404

def smart_media_serve(request, path):
    """
    Self-healing media handler:
    1. Directly serves existing files from disk.
    2. If Render restarted and wiped ephemeral disk files in user_images/,
       it automatically retrieves the original image bytes from PostgreSQL (image_base64),
       restores the physical file on disk on-the-fly, and serves HTTP 200 OK.
    """
    full_path = Path(settings.MEDIA_ROOT) / path
    if full_path.exists():
        return serve(request, path, document_root=settings.MEDIA_ROOT)

    # Check if this is an uploaded user image that was cleared by container restart
    if 'user_images/' in path or path.startswith('user_images/'):
        filename = os.path.basename(path)
        user = RegisteredUser.objects.filter(image__endswith=filename).first()
        if user and user.image_base64:
            try:
                b64_data = user.image_base64
                content_type = 'image/jpeg'
                if b64_data.startswith('data:'):
                    header, b64_data = b64_data.split(',', 1)
                    if ';base64' in header:
                        content_type = header.replace('data:', '').replace(';base64', '')

                img_bytes = base64.b64decode(b64_data)

                # Reconstruct file on disk so future requests are instant
                full_path.parent.mkdir(parents=True, exist_ok=True)
                with open(full_path, 'wb') as f:
                    f.write(img_bytes)

                return HttpResponse(img_bytes, content_type=content_type)
            except Exception:
                pass

    return serve(request, path, document_root=settings.MEDIA_ROOT)
