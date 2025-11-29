from django.urls import path, include
from rest_framework.routers import DefaultRouter
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
    UserViewSet,
    ModuleViewSet,
    EnrollmentViewSet,
    enroll_to_module,
    unenroll_from_module,
    my_enrollments,
    CourseSessionViewSet,
    CourseResourceViewSet,
    my_schedule,
    GradeViewSet,
    AnnouncementViewSet,
    my_grades,
    my_announcements,
    ChatMessageViewSet,
    NotificationViewSet,
    my_messages,
    my_unread_notifications,
)

app_name = 'api'

# Router pour les ViewSets
router = DefaultRouter()
router.register(r'users', UserViewSet, basename='user')
router.register(r'modules', ModuleViewSet, basename='module')
router.register(r'enrollments', EnrollmentViewSet, basename='enrollment')
router.register(r'sessions', CourseSessionViewSet, basename='session')
router.register(r'resources', CourseResourceViewSet, basename='resource')
router.register(r'grades', GradeViewSet, basename='grade')
router.register(r'announcements', AnnouncementViewSet, basename='announcement')
router.register(r'messages', ChatMessageViewSet, basename='message')
router.register(r'notifications', NotificationViewSet, basename='notification')

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
    
    # Routes personnalisées pour les inscriptions (AVANT le router pour éviter les conflits)
    path('modules/<int:module_id>/enroll/', enroll_to_module, name='enroll_to_module'),
    path('modules/<int:module_id>/unenroll/', unenroll_from_module, name='unenroll_from_module'),
    path('enrollments/my/', my_enrollments, name='my_enrollments'),
    
    # Routes personnalisées pour l'emploi du temps
    path('schedule/my/', my_schedule, name='my_schedule'),
    
    # Routes personnalisées pour les notes
    path('grades/my/', my_grades, name='my_grades'),
    
    # Routes personnalisées pour les annonces
    path('announcements/my/', my_announcements, name='my_announcements'),
    
    # Routes personnalisées pour les messages
    path('messages/my/', my_messages, name='my_messages'),
    
    # Routes personnalisées pour les notifications
    path('notifications/unread/', my_unread_notifications, name='my_unread_notifications'),
    
    # Routes pour les modules et inscriptions (router en dernier)
    path('', include(router.urls)),
]

