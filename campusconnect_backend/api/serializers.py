from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from .models import User, StudentProfile, TeacherProfile, Module, Enrollment, CourseSession, CourseResource


class UserSerializer(serializers.ModelSerializer):
    """
    Serializer pour les informations de l'utilisateur
    """
    role_display = serializers.CharField(source='get_role_display', read_only=True)
    
    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name',
            'role', 'role_display', 'phone', 'is_active',
            'date_joined', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'date_joined', 'created_at', 'updated_at']


class RegisterSerializer(serializers.ModelSerializer):
    """
    Serializer pour l'inscription d'un nouvel utilisateur
    """
    password = serializers.CharField(
        write_only=True,
        required=True,
        validators=[validate_password]
    )
    password2 = serializers.CharField(
        write_only=True,
        required=True,
        label='Confirmer le mot de passe'
    )
    
    # Champs spécifiques pour les étudiants
    student_id = serializers.CharField(
        write_only=True,
        required=False,
        allow_blank=True,
        allow_null=True
    )
    enrollment_date = serializers.DateField(
        write_only=True,
        required=False,
        allow_null=True
    )
    major = serializers.CharField(
        write_only=True,
        required=False,
        allow_blank=True,
        allow_null=True
    )
    year = serializers.IntegerField(
        write_only=True,
        required=False,
        allow_null=True
    )
    
    # Champs spécifiques pour les enseignants
    employee_id = serializers.CharField(
        write_only=True,
        required=False,
        allow_blank=True,
        allow_null=True
    )
    department = serializers.CharField(
        write_only=True,
        required=False,
        allow_blank=True,
        allow_null=True
    )
    hire_date = serializers.DateField(
        write_only=True,
        required=False,
        allow_null=True
    )
    specialization = serializers.CharField(
        write_only=True,
        required=False,
        allow_blank=True,
        allow_null=True
    )
    
    class Meta:
        model = User
        fields = [
            'username', 'email', 'password', 'password2',
            'first_name', 'last_name', 'role', 'phone',
            'student_id', 'enrollment_date', 'major', 'year',
            'employee_id', 'department', 'hire_date', 'specialization'
        ]
        extra_kwargs = {
            'email': {'required': True},
            'first_name': {'required': True},
            'last_name': {'required': True},
        }
    
    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({
                "password": "Les mots de passe ne correspondent pas."
            })
        
        role = attrs.get('role')
        
        # Validation pour les étudiants
        if role == 'student':
            if not attrs.get('student_id'):
                raise serializers.ValidationError({
                    "student_id": "Le numéro étudiant est requis pour les étudiants."
                })
        
        # Validation pour les enseignants
        if role == 'teacher':
            if not attrs.get('employee_id'):
                raise serializers.ValidationError({
                    "employee_id": "Le numéro employé est requis pour les enseignants."
                })
        
        return attrs
    
    def create(self, validated_data):
        # Extraire les données du profil
        password = validated_data.pop('password')
        validated_data.pop('password2')
        
        student_id = validated_data.pop('student_id', None)
        enrollment_date = validated_data.pop('enrollment_date', None)
        major = validated_data.pop('major', None)
        year = validated_data.pop('year', None)
        
        employee_id = validated_data.pop('employee_id', None)
        department = validated_data.pop('department', None)
        hire_date = validated_data.pop('hire_date', None)
        specialization = validated_data.pop('specialization', None)
        
        # Créer l'utilisateur
        user = User.objects.create_user(
            password=password,
            **validated_data
        )
        
        # Créer le profil selon le rôle
        if user.role == 'student' and student_id:
            StudentProfile.objects.create(
                user=user,
                student_id=student_id,
                enrollment_date=enrollment_date,
                major=major,
                year=year
            )
        elif user.role == 'teacher' and employee_id:
            TeacherProfile.objects.create(
                user=user,
                employee_id=employee_id,
                department=department,
                hire_date=hire_date,
                specialization=specialization
            )
        
        return user


class ChangePasswordSerializer(serializers.Serializer):
    """
    Serializer pour changer le mot de passe
    """
    old_password = serializers.CharField(required=True, write_only=True)
    new_password = serializers.CharField(
        required=True,
        write_only=True,
        validators=[validate_password]
    )
    new_password2 = serializers.CharField(
        required=True,
        write_only=True,
        label='Confirmer le nouveau mot de passe'
    )
    
    def validate(self, attrs):
        if attrs['new_password'] != attrs['new_password2']:
            raise serializers.ValidationError({
                "new_password": "Les nouveaux mots de passe ne correspondent pas."
            })
        return attrs
    
    def validate_old_password(self, value):
        user = self.context['request'].user
        if not user.check_password(value):
            raise serializers.ValidationError("L'ancien mot de passe est incorrect.")
        return value


class StudentProfileSerializer(serializers.ModelSerializer):
    """
    Serializer pour le profil étudiant
    """
    user = UserSerializer(read_only=True)
    user_id = serializers.IntegerField(write_only=True, required=False)
    
    class Meta:
        model = StudentProfile
        fields = [
            'id', 'user', 'user_id', 'student_id', 'enrollment_date',
            'major', 'year'
        ]
        read_only_fields = ['id']


class TeacherProfileSerializer(serializers.ModelSerializer):
    """
    Serializer pour le profil enseignant
    """
    user = UserSerializer(read_only=True)
    user_id = serializers.IntegerField(write_only=True, required=False)
    
    class Meta:
        model = TeacherProfile
        fields = [
            'id', 'user', 'user_id', 'employee_id', 'department',
            'hire_date', 'specialization'
        ]
        read_only_fields = ['id']


class ModuleSerializer(serializers.ModelSerializer):
    """
    Serializer pour le module/cours
    """
    teacher_name = serializers.CharField(
        source='teacher.get_full_name',
        read_only=True,
        allow_null=True
    )
    teacher_username = serializers.CharField(
        source='teacher.username',
        read_only=True,
        allow_null=True
    )
    enrolled_students_count = serializers.IntegerField(read_only=True)
    is_full = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = Module
        fields = [
            'id', 'code', 'name', 'description', 'teacher', 'teacher_name',
            'teacher_username', 'credits', 'semester', 'is_active',
            'max_students', 'enrolled_students_count', 'is_full',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'enrolled_students_count', 'is_full']
    
    def validate_code(self, value):
        """Valider que le code est en majuscules"""
        return value.upper()


class EnrollmentSerializer(serializers.ModelSerializer):
    """
    Serializer pour l'inscription d'un étudiant à un module
    """
    student_name = serializers.CharField(
        source='student.get_full_name',
        read_only=True
    )
    student_username = serializers.CharField(
        source='student.username',
        read_only=True
    )
    student_email = serializers.EmailField(
        source='student.email',
        read_only=True
    )
    module_code = serializers.CharField(
        source='module.code',
        read_only=True
    )
    module_name = serializers.CharField(
        source='module.name',
        read_only=True
    )
    
    class Meta:
        model = Enrollment
        fields = [
            'id', 'student', 'student_name', 'student_username', 'student_email',
            'module', 'module_code', 'module_name', 'enrollment_date',
            'is_active', 'grade', 'notes', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'enrollment_date', 'created_at', 'updated_at']
    
    def validate(self, attrs):
        student = attrs.get('student') or self.instance.student if self.instance else None
        module = attrs.get('module') or self.instance.module if self.instance else None
        
        if student and student.role != 'student':
            raise serializers.ValidationError({
                "student": "Seuls les étudiants peuvent s'inscrire à un module."
            })
        
        if module and module.is_full:
            raise serializers.ValidationError({
                "module": "Le module a atteint sa capacité maximale."
            })
        
        if module and not module.is_active:
            raise serializers.ValidationError({
                "module": "Le module n'est pas actif."
            })
        
        return attrs


class EnrollmentCreateSerializer(serializers.Serializer):
    """
    Serializer simplifié pour créer une inscription
    """
    module_id = serializers.IntegerField(required=True)
    
    def validate_module_id(self, value):
        try:
            module = Module.objects.get(id=value)
            if not module.is_active:
                raise serializers.ValidationError("Le module n'est pas actif.")
            if module.is_full:
                raise serializers.ValidationError("Le module a atteint sa capacité maximale.")
        except Module.DoesNotExist:
            raise serializers.ValidationError("Le module spécifié n'existe pas.")
        return value


class ModuleDetailSerializer(ModuleSerializer):
    """
    Serializer détaillé pour un module avec la liste des étudiants inscrits
    """
    enrollments = EnrollmentSerializer(many=True, read_only=True, source='enrollments.filter(is_active=True)')
    
    class Meta(ModuleSerializer.Meta):
        fields = ModuleSerializer.Meta.fields + ['enrollments']


class CourseSessionSerializer(serializers.ModelSerializer):
    """
    Serializer pour les sessions de cours (emploi du temps)
    """
    module_code = serializers.CharField(source='module.code', read_only=True)
    module_name = serializers.CharField(source='module.name', read_only=True)
    teacher_name = serializers.CharField(source='teacher.get_full_name', read_only=True, allow_null=True)
    teacher_username = serializers.CharField(source='teacher.username', read_only=True, allow_null=True)
    session_type_display = serializers.CharField(source='get_session_type_display', read_only=True)
    duration_minutes = serializers.SerializerMethodField()
    
    class Meta:
        model = CourseSession
        fields = [
            'id', 'module', 'module_code', 'module_name', 'teacher', 'teacher_name',
            'teacher_username', 'title', 'session_type', 'session_type_display',
            'date', 'start_time', 'end_time', 'duration_minutes', 'location',
            'is_online', 'description', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_duration_minutes(self, obj):
        """Calculer la durée de la session en minutes"""
        if obj.start_time and obj.end_time:
            from datetime import datetime, timedelta
            start = datetime.combine(obj.date, obj.start_time)
            end = datetime.combine(obj.date, obj.end_time)
            if end < start:
                # Si la session se termine le lendemain
                end += timedelta(days=1)
            duration = end - start
            return int(duration.total_seconds() / 60)
        return None
    
    def validate(self, attrs):
        """Valider que l'heure de fin est après l'heure de début"""
        start_time = attrs.get('start_time') or (self.instance.start_time if self.instance else None)
        end_time = attrs.get('end_time') or (self.instance.end_time if self.instance else None)
        date = attrs.get('date') or (self.instance.date if self.instance else None)
        
        if start_time and end_time:
            if end_time <= start_time:
                raise serializers.ValidationError({
                    'end_time': "L'heure de fin doit être après l'heure de début."
                })
        
        return attrs


class CourseResourceSerializer(serializers.ModelSerializer):
    """
    Serializer pour les ressources de cours
    """
    module_code = serializers.CharField(source='module.code', read_only=True)
    module_name = serializers.CharField(source='module.name', read_only=True)
    uploaded_by_name = serializers.CharField(source='uploaded_by.get_full_name', read_only=True, allow_null=True)
    uploaded_by_username = serializers.CharField(source='uploaded_by.username', read_only=True, allow_null=True)
    resource_type_display = serializers.CharField(source='get_resource_type_display', read_only=True)
    file_size_human = serializers.CharField(read_only=True)
    file_url = serializers.SerializerMethodField()
    
    class Meta:
        model = CourseResource
        fields = [
            'id', 'module', 'module_code', 'module_name', 'title', 'description',
            'resource_type', 'resource_type_display', 'file', 'file_url',
            'external_url', 'uploaded_by', 'uploaded_by_name', 'uploaded_by_username',
            'is_public', 'file_size', 'file_size_human', 'download_count',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'uploaded_by', 'file_size', 'download_count', 'created_at', 'updated_at']
    
    def get_file_url(self, obj):
        """Retourner l'URL du fichier ou de l'URL externe"""
        if obj.file:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.file.url)
            return obj.file.url
        elif obj.external_url:
            return obj.external_url
        return None
    
    def validate(self, attrs):
        """Valider qu'au moins un fichier ou une URL externe est fourni"""
        file = attrs.get('file') or (self.instance.file if self.instance else None)
        external_url = attrs.get('external_url') or (self.instance.external_url if self.instance else None)
        
        if not file and not external_url:
            raise serializers.ValidationError({
                'file': 'Vous devez fournir soit un fichier, soit une URL externe.',
                'external_url': 'Vous devez fournir soit un fichier, soit une URL externe.'
            })
        
        return attrs


class CourseResourceUploadSerializer(serializers.ModelSerializer):
    """
    Serializer simplifié pour l'upload de ressources
    """
    class Meta:
        model = CourseResource
        fields = ['module', 'title', 'description', 'resource_type', 'file', 'external_url', 'is_public']
    
    def validate(self, attrs):
        """Valider qu'au moins un fichier ou une URL externe est fourni"""
        file = attrs.get('file')
        external_url = attrs.get('external_url')
        
        if not file and not external_url:
            raise serializers.ValidationError({
                'file': 'Vous devez fournir soit un fichier, soit une URL externe.',
                'external_url': 'Vous devez fournir soit un fichier, soit une URL externe.'
            })
        
        return attrs

