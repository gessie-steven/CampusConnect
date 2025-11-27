from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import (
    User, StudentProfile, TeacherProfile, Module, Enrollment, 
    CourseSession, CourseResource, Grade, Announcement, 
    ChatMessage, Notification
)


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """
    Administration personnalisée pour le modèle User
    """
    list_display = ['username', 'email', 'first_name', 'last_name', 'role', 'is_active', 'date_joined']
    list_filter = ['role', 'is_active', 'is_staff', 'is_superuser', 'date_joined']
    search_fields = ['username', 'email', 'first_name', 'last_name']
    ordering = ['-date_joined']
    
    fieldsets = BaseUserAdmin.fieldsets + (
        ('Informations supplémentaires', {
            'fields': ('role', 'phone', 'created_at', 'updated_at')
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at']
    
    add_fieldsets = BaseUserAdmin.add_fieldsets + (
        ('Informations supplémentaires', {
            'fields': ('role', 'phone', 'email', 'first_name', 'last_name')
        }),
    )


@admin.register(StudentProfile)
class StudentProfileAdmin(admin.ModelAdmin):
    """
    Administration pour le profil étudiant
    """
    list_display = ['user', 'student_id', 'major', 'year', 'enrollment_date']
    list_filter = ['major', 'year', 'enrollment_date']
    search_fields = ['user__username', 'user__email', 'student_id', 'major']
    raw_id_fields = ['user']


@admin.register(TeacherProfile)
class TeacherProfileAdmin(admin.ModelAdmin):
    """
    Administration pour le profil enseignant
    """
    list_display = ['user', 'employee_id', 'department', 'specialization', 'hire_date']
    list_filter = ['department', 'hire_date']
    search_fields = ['user__username', 'user__email', 'employee_id', 'department', 'specialization']
    raw_id_fields = ['user']


@admin.register(Module)
class ModuleAdmin(admin.ModelAdmin):
    """
    Administration pour les modules
    """
    list_display = ['code', 'name', 'teacher', 'credits', 'semester', 'is_active', 'enrolled_students_count', 'created_at']
    list_filter = ['is_active', 'semester', 'teacher', 'created_at']
    search_fields = ['code', 'name', 'description', 'teacher__username', 'teacher__email']
    raw_id_fields = ['teacher']
    readonly_fields = ['created_at', 'updated_at', 'enrolled_students_count']
    
    fieldsets = (
        ('Informations générales', {
            'fields': ('code', 'name', 'description', 'teacher')
        }),
        ('Détails', {
            'fields': ('credits', 'semester', 'is_active', 'max_students')
        }),
        ('Statistiques', {
            'fields': ('enrolled_students_count',)
        }),
        ('Dates', {
            'fields': ('created_at', 'updated_at')
        }),
    )


@admin.register(Enrollment)
class EnrollmentAdmin(admin.ModelAdmin):
    """
    Administration pour les inscriptions
    """
    list_display = ['student', 'module', 'enrollment_date', 'is_active', 'grade', 'created_at']
    list_filter = ['is_active', 'enrollment_date', 'module', 'created_at']
    search_fields = [
        'student__username', 'student__email', 'student__first_name', 'student__last_name',
        'module__code', 'module__name'
    ]
    raw_id_fields = ['student', 'module']
    readonly_fields = ['enrollment_date', 'created_at', 'updated_at']
    
    fieldsets = (
        ('Inscription', {
            'fields': ('student', 'module', 'enrollment_date', 'is_active')
        }),
        ('Évaluation', {
            'fields': ('grade', 'notes')
        }),
        ('Dates', {
            'fields': ('created_at', 'updated_at')
        }),
    )


@admin.register(CourseSession)
class CourseSessionAdmin(admin.ModelAdmin):
    """
    Administration pour les sessions de cours
    """
    list_display = ['module', 'teacher', 'date', 'start_time', 'end_time', 'session_type', 'location', 'is_online']
    list_filter = ['session_type', 'is_online', 'date', 'module', 'teacher']
    search_fields = [
        'module__code', 'module__name', 'teacher__username', 'teacher__email',
        'title', 'location', 'description'
    ]
    raw_id_fields = ['module', 'teacher']
    readonly_fields = ['created_at', 'updated_at']
    date_hierarchy = 'date'
    
    fieldsets = (
        ('Informations générales', {
            'fields': ('module', 'teacher', 'title', 'session_type')
        }),
        ('Horaires', {
            'fields': ('date', 'start_time', 'end_time')
        }),
        ('Lieu', {
            'fields': ('location', 'is_online')
        }),
        ('Description', {
            'fields': ('description',)
        }),
        ('Dates', {
            'fields': ('created_at', 'updated_at')
        }),
    )


@admin.register(CourseResource)
class CourseResourceAdmin(admin.ModelAdmin):
    """
    Administration pour les ressources de cours
    """
    list_display = ['title', 'module', 'resource_type', 'uploaded_by', 'is_public', 'download_count', 'created_at']
    list_filter = ['resource_type', 'is_public', 'created_at', 'module']
    search_fields = [
        'title', 'description', 'module__code', 'module__name',
        'uploaded_by__username', 'uploaded_by__email'
    ]
    raw_id_fields = ['module', 'uploaded_by']
    readonly_fields = ['file_size', 'download_count', 'created_at', 'updated_at']
    
    fieldsets = (
        ('Informations générales', {
            'fields': ('module', 'title', 'description', 'resource_type')
        }),
        ('Fichier', {
            'fields': ('file', 'external_url', 'file_size')
        }),
        ('Métadonnées', {
            'fields': ('uploaded_by', 'is_public', 'download_count')
        }),
        ('Dates', {
            'fields': ('created_at', 'updated_at')
        }),
    )


@admin.register(Grade)
class GradeAdmin(admin.ModelAdmin):
    """
    Administration pour les notes
    """
    list_display = ['student', 'module', 'grade_type', 'grade', 'max_grade', 'graded_by', 'graded_date']
    list_filter = ['grade_type', 'graded_date', 'module', 'graded_by']
    search_fields = [
        'student__username', 'student__email', 'student__first_name', 'student__last_name',
        'module__code', 'module__name', 'comment'
    ]
    raw_id_fields = ['student', 'module', 'graded_by']
    readonly_fields = ['graded_date', 'created_at', 'updated_at']
    date_hierarchy = 'graded_date'
    
    fieldsets = (
        ('Note', {
            'fields': ('student', 'module', 'grade_type', 'grade', 'max_grade', 'comment')
        }),
        ('Métadonnées', {
            'fields': ('graded_by', 'graded_date')
        }),
        ('Dates', {
            'fields': ('created_at', 'updated_at')
        }),
    )


@admin.register(Announcement)
class AnnouncementAdmin(admin.ModelAdmin):
    """
    Administration pour les annonces
    """
    list_display = ['title', 'author', 'module', 'priority', 'is_pinned', 'is_active', 'published_date']
    list_filter = ['priority', 'is_pinned', 'is_active', 'target_audience', 'published_date', 'module']
    search_fields = [
        'title', 'content', 'author__username', 'author__email',
        'module__code', 'module__name'
    ]
    raw_id_fields = ['author', 'module']
    readonly_fields = ['published_date', 'created_at', 'updated_at']
    date_hierarchy = 'published_date'
    
    fieldsets = (
        ('Contenu', {
            'fields': ('author', 'title', 'content')
        }),
        ('Ciblage', {
            'fields': ('module', 'target_audience', 'priority')
        }),
        ('Affichage', {
            'fields': ('is_pinned', 'is_active', 'expiry_date')
        }),
        ('Dates', {
            'fields': ('published_date', 'created_at', 'updated_at')
        }),
    )


@admin.register(ChatMessage)
class ChatMessageAdmin(admin.ModelAdmin):
    """
    Administration pour les messages de chat
    """
    list_display = ['sender', 'recipient', 'message_preview', 'is_read', 'created_at']
    list_filter = ['is_read', 'created_at', 'sender', 'recipient']
    search_fields = [
        'sender__username', 'sender__email', 'recipient__username', 'recipient__email',
        'message'
    ]
    raw_id_fields = ['sender', 'recipient']
    readonly_fields = ['created_at', 'updated_at', 'read_at']
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Message', {
            'fields': ('sender', 'recipient', 'message')
        }),
        ('Statut', {
            'fields': ('is_read', 'read_at')
        }),
        ('Dates', {
            'fields': ('created_at', 'updated_at')
        }),
    )
    
    def message_preview(self, obj):
        """Aperçu du message"""
        return obj.message[:50] + '...' if len(obj.message) > 50 else obj.message
    message_preview.short_description = 'Message'


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    """
    Administration pour les notifications
    """
    list_display = ['recipient', 'notification_type', 'title', 'is_read', 'created_at']
    list_filter = ['notification_type', 'is_read', 'created_at', 'recipient']
    search_fields = [
        'recipient__username', 'recipient__email', 'title', 'content'
    ]
    raw_id_fields = ['recipient', 'related_module', 'related_grade', 'related_announcement']
    readonly_fields = ['created_at', 'read_at']
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Notification', {
            'fields': ('recipient', 'notification_type', 'title', 'content', 'link')
        }),
        ('Relations', {
            'fields': ('related_module', 'related_grade', 'related_announcement')
        }),
        ('Statut', {
            'fields': ('is_read', 'read_at')
        }),
        ('Dates', {
            'fields': ('created_at',)
        }),
    )
