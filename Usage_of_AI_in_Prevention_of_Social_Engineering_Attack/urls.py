"""
URL configuration for Usage_of_AI_in_Prevention_of_Social_Engineering_Attack project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, re_path
from django.conf import settings
from django.conf.urls.static import static
from django.views.static import serve
from users import views

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', views.home, name='home'),
    path('register/', views.register_view, name='register'),
    path('user-login/', views.user_login, name='user_login'),
    path('user-homepage/', views.user_homepage, name='user_homepage'),  # new user homepage url
    path('admin-login/', views.admin_login, name='admin_login'),
    path('admin-home/', views.admin_home, name='admin_home'),
    path('admin-dashboard/', views.admin_dashboard, name='admin_dashboard'),
    path('activate/<int:user_id>/', views.activate_user, name='activate_user'),
    path('deactivate/<int:user_id>/', views.deactivate_user, name='deactivate_user'),
    path('delete/<int:user_id>/', views.delete_user, name='delete_user'),
    path('user-logout/', views.user_logout, name='user_logout'),
    path("forgot-password/",views.forgot_password, name="forgot_password"),
    path("verify-otp/",views.verify_otp, name="verify_otp"),
    path("reset-password/",views.reset_password, name="reset_password"),

    path('detect_spam/', views.detect_spam, name='detect_spam'),
    path('train-anomaly-model/', views.train_anomaly_model, name='train_anomaly_model'),
    path('predict-anomaly/', views.predict_anomaly, name='predict_anomaly'),
    path('scan-qr/',views.qr_scan_view, name='qr-scan'),
    path('password-analyzer/', views.password_analyzer, name='password_analyzer'),
    path('email-phishing/', views.email_phishing_analyzer, name='email_phishing_analyzer'),
    path('introduction/', views.introduction, name='introduction'),
    path('contact/', views.contact, name='contact'),
    path('dispatch-verification/', views.dispatch_verification_challenge, name='dispatch_verification_challenge'),
    path('confirm-verification/', views.confirm_verification_challenge, name='confirm_verification_challenge'),
    re_path(r'^media/(?P<path>.*)$', serve, {'document_root': settings.MEDIA_ROOT}),
]
