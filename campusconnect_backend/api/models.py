from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    """
    Modèle utilisateur personnalisé avec gestion des rôles
    """
    ROLE_CHOICES = [
        ('student', 'Étudiant'),
        ('teacher', 'Enseignant'),
        ('admin', 'Administrateur'),
    ]
    
    role = models.CharField(
        max_length=20,
        choices=ROLE_CHOICES,
        default='student',
        verbose_name='Rôle'
    )
    phone = models.CharField(
        max_length=20,
        blank=True,
        null=True,
        verbose_name='Téléphone'
    )
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Date de création')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='Date de modification')
    
    class Meta:
        verbose_name = 'Utilisateur'
        verbose_name_plural = 'Utilisateurs'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.username} ({self.get_role_display()})"
    
    @property
    def is_student(self):
        return self.role == 'student'
    
    @property
    def is_teacher(self):
        return self.role == 'teacher'
    
    @property
    def is_admin(self):
        return self.role == 'admin'


class StudentProfile(models.Model):
    """
    Profil spécifique pour les étudiants
    """
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='student_profile',
        limit_choices_to={'role': 'student'}
    )
    student_id = models.CharField(
        max_length=50,
        unique=True,
        verbose_name='Numéro étudiant'
    )
    enrollment_date = models.DateField(
        blank=True,
        null=True,
        verbose_name='Date d\'inscription'
    )
    major = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        verbose_name='Filière'
    )
    year = models.IntegerField(
        blank=True,
        null=True,
        verbose_name='Année d\'étude'
    )
    
    class Meta:
        verbose_name = 'Profil Étudiant'
        verbose_name_plural = 'Profils Étudiants'
    
    def __str__(self):
        return f"Profil de {self.user.username}"


class TeacherProfile(models.Model):
    """
    Profil spécifique pour les enseignants
    """
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='teacher_profile',
        limit_choices_to={'role': 'teacher'}
    )
    employee_id = models.CharField(
        max_length=50,
        unique=True,
        verbose_name='Numéro employé'
    )
    department = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        verbose_name='Département'
    )
    hire_date = models.DateField(
        blank=True,
        null=True,
        verbose_name='Date d\'embauche'
    )
    specialization = models.CharField(
        max_length=200,
        blank=True,
        null=True,
        verbose_name='Spécialisation'
    )
    
    class Meta:
        verbose_name = 'Profil Enseignant'
        verbose_name_plural = 'Profils Enseignants'
    
    def __str__(self):
        return f"Profil de {self.user.username}"
