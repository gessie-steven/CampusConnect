from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User, StudentProfile, TeacherProfile, Module, Enrollment


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
