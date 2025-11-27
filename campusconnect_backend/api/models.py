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


class Module(models.Model):
    """
    Modèle représentant un cours/module
    """
    code = models.CharField(
        max_length=20,
        unique=True,
        verbose_name='Code du module',
        help_text='Code unique identifiant le module (ex: INF101)'
    )
    name = models.CharField(
        max_length=200,
        verbose_name='Nom du module'
    )
    description = models.TextField(
        blank=True,
        null=True,
        verbose_name='Description'
    )
    teacher = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name='taught_modules',
        limit_choices_to={'role': 'teacher'},
        verbose_name='Enseignant référent'
    )
    credits = models.IntegerField(
        default=0,
        verbose_name='Crédits',
        help_text='Nombre de crédits ECTS'
    )
    semester = models.CharField(
        max_length=20,
        blank=True,
        null=True,
        verbose_name='Semestre',
        help_text='Ex: S1, S2, Automne 2024'
    )
    is_active = models.BooleanField(
        default=True,
        verbose_name='Actif',
        help_text='Indique si le module est actuellement actif'
    )
    max_students = models.IntegerField(
        blank=True,
        null=True,
        verbose_name='Nombre maximum d\'étudiants',
        help_text='Limite du nombre d\'étudiants pouvant s\'inscrire'
    )
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Date de création')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='Date de modification')
    
    class Meta:
        verbose_name = 'Module'
        verbose_name_plural = 'Modules'
        ordering = ['code', 'name']
        indexes = [
            models.Index(fields=['code']),
            models.Index(fields=['teacher']),
            models.Index(fields=['is_active']),
        ]
    
    def __str__(self):
        return f"{self.code} - {self.name}"
    
    @property
    def enrolled_students_count(self):
        """Retourne le nombre d'étudiants inscrits"""
        return self.enrollments.filter(is_active=True).count()
    
    @property
    def is_full(self):
        """Vérifie si le module a atteint sa capacité maximale"""
        if self.max_students is None:
            return False
        return self.enrolled_students_count >= self.max_students


class Enrollment(models.Model):
    """
    Modèle représentant l'inscription d'un étudiant à un module
    """
    student = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='enrollments',
        limit_choices_to={'role': 'student'},
        verbose_name='Étudiant'
    )
    module = models.ForeignKey(
        Module,
        on_delete=models.CASCADE,
        related_name='enrollments',
        verbose_name='Module'
    )
    enrollment_date = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Date d\'inscription'
    )
    is_active = models.BooleanField(
        default=True,
        verbose_name='Inscription active',
        help_text='Indique si l\'inscription est toujours active'
    )
    grade = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        blank=True,
        null=True,
        verbose_name='Note',
        help_text='Note obtenue (sur 20)'
    )
    notes = models.TextField(
        blank=True,
        null=True,
        verbose_name='Notes',
        help_text='Notes additionnelles sur l\'inscription'
    )
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Date de création')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='Date de modification')
    
    class Meta:
        verbose_name = 'Inscription'
        verbose_name_plural = 'Inscriptions'
        ordering = ['-enrollment_date']
        unique_together = ['student', 'module']
        indexes = [
            models.Index(fields=['student', 'module']),
            models.Index(fields=['is_active']),
            models.Index(fields=['enrollment_date']),
        ]
    
    def __str__(self):
        status = "active" if self.is_active else "inactive"
        return f"{self.student.username} - {self.module.code} ({status})"
    
    def save(self, *args, **kwargs):
        # Vérifier que l'utilisateur est bien un étudiant
        if self.student.role != 'student':
            raise ValueError("Seuls les étudiants peuvent s'inscrire à un module")
        super().save(*args, **kwargs)


class CourseSession(models.Model):
    """
    Modèle représentant une session de cours dans l'emploi du temps
    """
    SESSION_TYPE_CHOICES = [
        ('lecture', 'Cours magistral'),
        ('tutorial', 'TD - Travaux dirigés'),
        ('lab', 'TP - Travaux pratiques'),
        ('exam', 'Examen'),
        ('other', 'Autre'),
    ]
    
    module = models.ForeignKey(
        Module,
        on_delete=models.CASCADE,
        related_name='sessions',
        verbose_name='Module'
    )
    teacher = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name='taught_sessions',
        limit_choices_to={'role': 'teacher'},
        verbose_name='Enseignant'
    )
    title = models.CharField(
        max_length=200,
        blank=True,
        null=True,
        verbose_name='Titre',
        help_text='Titre optionnel de la session'
    )
    session_type = models.CharField(
        max_length=20,
        choices=SESSION_TYPE_CHOICES,
        default='lecture',
        verbose_name='Type de session'
    )
    date = models.DateField(
        verbose_name='Date'
    )
    start_time = models.TimeField(
        verbose_name='Heure de début'
    )
    end_time = models.TimeField(
        verbose_name='Heure de fin'
    )
    location = models.CharField(
        max_length=200,
        blank=True,
        null=True,
        verbose_name='Lieu',
        help_text='Salle physique ou lien de visioconférence'
    )
    is_online = models.BooleanField(
        default=False,
        verbose_name='Session en ligne',
        help_text='Indique si la session est en visioconférence'
    )
    description = models.TextField(
        blank=True,
        null=True,
        verbose_name='Description',
        help_text='Description ou notes sur la session'
    )
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Date de création')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='Date de modification')
    
    class Meta:
        verbose_name = 'Session de cours'
        verbose_name_plural = 'Sessions de cours'
        ordering = ['date', 'start_time']
        indexes = [
            models.Index(fields=['module', 'date']),
            models.Index(fields=['teacher', 'date']),
            models.Index(fields=['date', 'start_time']),
        ]
    
    def __str__(self):
        date_str = self.date.strftime('%d/%m/%Y')
        time_str = f"{self.start_time.strftime('%H:%M')} - {self.end_time.strftime('%H:%M')}"
        return f"{self.module.code} - {date_str} {time_str}"
    
    def clean(self):
        """Valider que l'heure de fin est après l'heure de début"""
        from django.core.exceptions import ValidationError
        if self.start_time and self.end_time and self.end_time <= self.start_time:
            raise ValidationError("L'heure de fin doit être après l'heure de début")


class CourseResource(models.Model):
    """
    Modèle représentant une ressource de cours (fichier)
    """
    RESOURCE_TYPE_CHOICES = [
        ('pdf', 'PDF'),
        ('doc', 'Document Word'),
        ('docx', 'Document Word'),
        ('ppt', 'PowerPoint'),
        ('pptx', 'PowerPoint'),
        ('xls', 'Excel'),
        ('xlsx', 'Excel'),
        ('video', 'Vidéo'),
        ('audio', 'Audio'),
        ('image', 'Image'),
        ('link', 'Lien externe'),
        ('other', 'Autre'),
    ]
    
    module = models.ForeignKey(
        Module,
        on_delete=models.CASCADE,
        related_name='resources',
        verbose_name='Module'
    )
    title = models.CharField(
        max_length=200,
        verbose_name='Titre'
    )
    description = models.TextField(
        blank=True,
        null=True,
        verbose_name='Description'
    )
    resource_type = models.CharField(
        max_length=20,
        choices=RESOURCE_TYPE_CHOICES,
        default='other',
        verbose_name='Type de ressource'
    )
    file = models.FileField(
        upload_to='course_resources/%Y/%m/%d/',
        blank=True,
        null=True,
        verbose_name='Fichier',
        help_text='Fichier à télécharger'
    )
    external_url = models.URLField(
        blank=True,
        null=True,
        verbose_name='URL externe',
        help_text='Lien externe si la ressource n\'est pas un fichier'
    )
    uploaded_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name='uploaded_resources',
        verbose_name='Téléchargé par'
    )
    is_public = models.BooleanField(
        default=True,
        verbose_name='Public',
        help_text='Indique si la ressource est accessible à tous les étudiants du module'
    )
    file_size = models.BigIntegerField(
        blank=True,
        null=True,
        verbose_name='Taille du fichier (octets)',
        help_text='Taille du fichier en octets'
    )
    download_count = models.IntegerField(
        default=0,
        verbose_name='Nombre de téléchargements'
    )
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Date de création')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='Date de modification')
    
    class Meta:
        verbose_name = 'Ressource de cours'
        verbose_name_plural = 'Ressources de cours'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['module']),
            models.Index(fields=['resource_type']),
            models.Index(fields=['is_public']),
        ]
    
    def __str__(self):
        return f"{self.title} - {self.module.code}"
    
    def save(self, *args, **kwargs):
        """Calculer la taille du fichier lors de l'enregistrement"""
        if self.file:
            self.file_size = self.file.size
        super().save(*args, **kwargs)
    
    @property
    def file_size_human(self):
        """Retourne la taille du fichier formatée de manière lisible"""
        if not self.file_size:
            return "N/A"
        
        size = float(self.file_size)
        for unit in ['B', 'KB', 'MB', 'GB']:
            if size < 1024.0:
                return f"{size:.2f} {unit}"
            size /= 1024.0
        return f"{size:.2f} TB"
