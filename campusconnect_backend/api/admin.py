from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User, StudentProfile, TeacherProfile


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
