from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    CustomTokenObtainPairView,
    RegisterView,
    UserProfileView,
    me_view,
    ChangePasswordView,
    student_only_view,
    teacher_only_view,
    admin_only_view,
)

app_name = 'api'

urlpatterns = [
    # Authentification
    path('auth/register/', RegisterView.as_view(), name='register'),
    path('auth/login/', CustomTokenObtainPairView.as_view(), name='login'),
    path('auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('auth/me/', me_view, name='me'),
    path('auth/profile/', UserProfileView.as_view(), name='profile'),
    path('auth/change-password/', ChangePasswordView.as_view(), name='change_password'),
    
    # Endpoints de test pour les permissions
    path('auth/student-only/', student_only_view, name='student_only'),
    path('auth/teacher-only/', teacher_only_view, name='teacher_only'),
    path('auth/admin-only/', admin_only_view, name='admin_only'),
]

