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


class Grade(models.Model):
    """
    Modèle représentant une note attribuée à un étudiant pour un module
    """
    GRADE_TYPE_CHOICES = [
        ('exam', 'Examen'),
        ('assignment', 'Devoir'),
        ('project', 'Projet'),
        ('quiz', 'Quiz'),
        ('participation', 'Participation'),
        ('midterm', 'Contrôle continu'),
        ('final', 'Examen final'),
        ('other', 'Autre'),
    ]
    
    student = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='grades',
        limit_choices_to={'role': 'student'},
        verbose_name='Étudiant'
    )
    module = models.ForeignKey(
        Module,
        on_delete=models.CASCADE,
        related_name='grades',
        verbose_name='Module'
    )
    grade_type = models.CharField(
        max_length=20,
        choices=GRADE_TYPE_CHOICES,
        default='other',
        verbose_name='Type de note'
    )
    grade = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        verbose_name='Note',
        help_text='Note sur 20'
    )
    max_grade = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=20.00,
        verbose_name='Note maximale',
        help_text='Note maximale possible (par défaut 20)'
    )
    comment = models.TextField(
        blank=True,
        null=True,
        verbose_name='Commentaire',
        help_text='Commentaire ou remarque sur la note'
    )
    graded_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name='graded_assignments',
        limit_choices_to={'role__in': ['teacher', 'admin']},
        verbose_name='Noté par'
    )
    graded_date = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Date de notation'
    )
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Date de création')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='Date de modification')
    
    class Meta:
        verbose_name = 'Note'
        verbose_name_plural = 'Notes'
        ordering = ['-graded_date']
        indexes = [
            models.Index(fields=['student', 'module']),
            models.Index(fields=['module', 'grade_type']),
            models.Index(fields=['graded_date']),
        ]
    
    def __str__(self):
        return f"{self.student.username} - {self.module.code}: {self.grade}/{self.max_grade}"
    
    @property
    def percentage(self):
        """Retourne la note en pourcentage"""
        if self.max_grade > 0:
            return (self.grade / self.max_grade) * 100
        return 0
    
    @property
    def letter_grade(self):
        """Retourne la note en lettre (A, B, C, D, F)"""
        percentage = self.percentage
        if percentage >= 90:
            return 'A'
        elif percentage >= 80:
            return 'B'
        elif percentage >= 70:
            return 'C'
        elif percentage >= 60:
            return 'D'
        else:
            return 'F'


class Announcement(models.Model):
    """
    Modèle représentant une annonce/message aux étudiants
    """
    PRIORITY_CHOICES = [
        ('low', 'Basse'),
        ('normal', 'Normale'),
        ('high', 'Haute'),
        ('urgent', 'Urgente'),
    ]
    
    author = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='announcements',
        limit_choices_to={'role__in': ['teacher', 'admin']},
        verbose_name='Auteur'
    )
    title = models.CharField(
        max_length=200,
        verbose_name='Titre'
    )
    content = models.TextField(
        verbose_name='Contenu'
    )
    module = models.ForeignKey(
        Module,
        on_delete=models.CASCADE,
        related_name='announcements',
        blank=True,
        null=True,
        verbose_name='Module',
        help_text='Module ciblé (optionnel, laisser vide pour une annonce générale)'
    )
    priority = models.CharField(
        max_length=20,
        choices=PRIORITY_CHOICES,
        default='normal',
        verbose_name='Priorité'
    )
    is_pinned = models.BooleanField(
        default=False,
        verbose_name='Épinglée',
        help_text='Annonce importante affichée en premier'
    )
    is_active = models.BooleanField(
        default=True,
        verbose_name='Active',
        help_text='Indique si l\'annonce est visible'
    )
    target_audience = models.CharField(
        max_length=20,
        choices=User.ROLE_CHOICES,
        blank=True,
        null=True,
        verbose_name='Public cible',
        help_text='Rôle ciblé (optionnel, laisser vide pour tous)'
    )
    published_date = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Date de publication'
    )
    expiry_date = models.DateTimeField(
        blank=True,
        null=True,
        verbose_name='Date d\'expiration',
        help_text='Date après laquelle l\'annonce ne sera plus visible'
    )
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Date de création')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='Date de modification')
    
    class Meta:
        verbose_name = 'Annonce'
        verbose_name_plural = 'Annonces'
        ordering = ['-is_pinned', '-published_date']
        indexes = [
            models.Index(fields=['author', 'published_date']),
            models.Index(fields=['module', 'is_active']),
            models.Index(fields=['is_pinned', 'published_date']),
            models.Index(fields=['is_active', 'published_date']),
        ]
    
    def __str__(self):
        module_str = f" - {self.module.code}" if self.module else " (Générale)"
        return f"{self.title}{module_str}"
    
    @property
    def is_expired(self):
        """Vérifie si l'annonce a expiré"""
        if self.expiry_date:
            from django.utils import timezone
            return timezone.now() > self.expiry_date
        return False
    
    @property
    def is_visible(self):
        """Vérifie si l'annonce est visible (active et non expirée)"""
        return self.is_active and not self.is_expired


class ChatMessage(models.Model):
    """
    Modèle représentant un message de chat entre deux utilisateurs
    """
    sender = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='sent_messages',
        verbose_name='Expéditeur'
    )
    recipient = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='received_messages',
        verbose_name='Destinataire'
    )
    message = models.TextField(
        verbose_name='Message'
    )
    is_read = models.BooleanField(
        default=False,
        verbose_name='Lu',
        help_text='Indique si le message a été lu par le destinataire'
    )
    read_at = models.DateTimeField(
        blank=True,
        null=True,
        verbose_name='Date de lecture',
        help_text='Date et heure à laquelle le message a été lu'
    )
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Date d\'envoi')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='Date de modification')
    
    class Meta:
        verbose_name = 'Message'
        verbose_name_plural = 'Messages'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['sender', 'recipient']),
            models.Index(fields=['recipient', 'is_read']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"{self.sender.username} -> {self.recipient.username}: {self.message[:50]}"
    
    def mark_as_read(self):
        """Marquer le message comme lu"""
        if not self.is_read:
            from django.utils import timezone
            self.is_read = True
            self.read_at = timezone.now()
            self.save(update_fields=['is_read', 'read_at'])


class Notification(models.Model):
    """
    Modèle représentant une notification pour un utilisateur
    """
    NOTIFICATION_TYPE_CHOICES = [
        ('announcement', 'Annonce'),
        ('grade', 'Note'),
        ('message', 'Message'),
        ('enrollment', 'Inscription'),
        ('module', 'Module'),
        ('session', 'Session de cours'),
        ('resource', 'Ressource'),
        ('other', 'Autre'),
    ]
    
    recipient = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='notifications',
        verbose_name='Destinataire'
    )
    notification_type = models.CharField(
        max_length=20,
        choices=NOTIFICATION_TYPE_CHOICES,
        default='other',
        verbose_name='Type de notification'
    )
    title = models.CharField(
        max_length=200,
        verbose_name='Titre'
    )
    content = models.TextField(
        verbose_name='Contenu'
    )
    link = models.URLField(
        blank=True,
        null=True,
        verbose_name='Lien',
        help_text='Lien vers la ressource concernée'
    )
    related_module = models.ForeignKey(
        Module,
        on_delete=models.SET_NULL,
        blank=True,
        null=True,
        related_name='notifications',
        verbose_name='Module concerné'
    )
    related_grade = models.ForeignKey(
        Grade,
        on_delete=models.SET_NULL,
        blank=True,
        null=True,
        related_name='notifications',
        verbose_name='Note concernée'
    )
    related_announcement = models.ForeignKey(
        Announcement,
        on_delete=models.SET_NULL,
        blank=True,
        null=True,
        related_name='notifications',
        verbose_name='Annonce concernée'
    )
    is_read = models.BooleanField(
        default=False,
        verbose_name='Lu',
        help_text='Indique si la notification a été lue'
    )
    read_at = models.DateTimeField(
        blank=True,
        null=True,
        verbose_name='Date de lecture',
        help_text='Date et heure à laquelle la notification a été lue'
    )
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Date de création')
    
    class Meta:
        verbose_name = 'Notification'
        verbose_name_plural = 'Notifications'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['recipient', 'is_read']),
            models.Index(fields=['notification_type']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"{self.title} - {self.recipient.username}"
    
    def mark_as_read(self):
        """Marquer la notification comme lue"""
        if not self.is_read:
            from django.utils import timezone
            self.is_read = True
            self.read_at = timezone.now()
            self.save(update_fields=['is_read', 'read_at'])
    
    @classmethod
    def create_for_user(cls, user, notification_type, title, content, link=None, 
                       related_module=None, related_grade=None, related_announcement=None):
        """
        Méthode utilitaire pour créer une notification
        """
        return cls.objects.create(
            recipient=user,
            notification_type=notification_type,
            title=title,
            content=content,
            link=link,
            related_module=related_module,
            related_grade=related_grade,
            related_announcement=related_announcement
        )
