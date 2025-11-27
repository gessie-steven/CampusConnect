from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from .models import User, StudentProfile, TeacherProfile


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

