from rest_framework import generics, status, viewsets
from rest_framework.decorators import api_view, permission_classes, action
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.exceptions import ValidationError
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from django.contrib.auth import get_user_model
from django.shortcuts import get_object_or_404
from django.db.models import Q

from .serializers import (
    RegisterSerializer,
    UserSerializer,
    ChangePasswordSerializer,
    ModuleSerializer,
    ModuleDetailSerializer,
    EnrollmentSerializer,
    EnrollmentCreateSerializer,
    StudentProfileSerializer,
    TeacherProfileSerializer
)
from .permissions import IsStudent, IsTeacher, IsAdmin, IsTeacherOrAdmin, IsModuleTeacherOrAdmin
from .models import Module, Enrollment

User = get_user_model()


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    """
    Serializer personnalisé pour inclure les informations utilisateur dans le token
    """
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        
        # Ajouter des informations personnalisées au token
        token['username'] = user.username
        token['role'] = user.role
        token['email'] = user.email
        
        return token
    
    def validate(self, attrs):
        data = super().validate(attrs)
        
        # Ajouter les informations utilisateur à la réponse
        data['user'] = UserSerializer(self.user).data
        
        return data


class CustomTokenObtainPairView(TokenObtainPairView):
    """
    Vue personnalisée pour l'obtention du token JWT (login)
    """
    serializer_class = CustomTokenObtainPairSerializer


class RegisterView(generics.CreateAPIView):
    """
    Endpoint pour l'inscription d'un nouvel utilisateur
    """
    queryset = User.objects.all()
    permission_classes = [AllowAny]
    serializer_class = RegisterSerializer
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        
        # Générer les tokens pour le nouvel utilisateur
        token_serializer = CustomTokenObtainPairSerializer()
        token_data = token_serializer.get_token(user)
        
        return Response({
            'message': 'Inscription réussie',
            'user': UserSerializer(user).data,
            'tokens': {
                'access': str(token_data.access_token),
                'refresh': str(token_data)
            }
        }, status=status.HTTP_201_CREATED)


class UserProfileView(generics.RetrieveUpdateAPIView):
    """
    Endpoint pour récupérer et mettre à jour le profil de l'utilisateur connecté
    GET /api/auth/me/ - Récupérer les informations de l'utilisateur
    PUT /api/auth/me/ - Mettre à jour les informations de l'utilisateur
    """
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]
    
    def get_object(self):
        return self.request.user


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def me_view(request):
    """
    Endpoint simple pour récupérer les informations de l'utilisateur connecté
    GET /api/auth/me/
    """
    serializer = UserSerializer(request.user)
    return Response(serializer.data)


class ChangePasswordView(generics.UpdateAPIView):
    """
    Endpoint pour changer le mot de passe
    PUT /api/auth/change-password/
    """
    serializer_class = ChangePasswordSerializer
    permission_classes = [IsAuthenticated]
    
    def get_object(self):
        return self.request.user
    
    def update(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        user = self.get_object()
        user.set_password(serializer.validated_data['new_password'])
        user.save()
        
        return Response({
            'message': 'Mot de passe modifié avec succès'
        }, status=status.HTTP_200_OK)


# Vues pour tester les permissions par rôle
@api_view(['GET'])
@permission_classes([IsStudent])
def student_only_view(request):
    """
    Endpoint accessible uniquement aux étudiants
    GET /api/auth/student-only/
    """
    return Response({
        'message': 'Vous êtes un étudiant',
        'user': UserSerializer(request.user).data
    })


@api_view(['GET'])
@permission_classes([IsTeacher])
def teacher_only_view(request):
    """
    Endpoint accessible uniquement aux enseignants
    GET /api/auth/teacher-only/
    """
    return Response({
        'message': 'Vous êtes un enseignant',
        'user': UserSerializer(request.user).data
    })


@api_view(['GET'])
@permission_classes([IsAdmin])
def admin_only_view(request):
    """
    Endpoint accessible uniquement aux administrateurs
    GET /api/auth/admin-only/
    """
    return Response({
        'message': 'Vous êtes un administrateur',
        'user': UserSerializer(request.user).data
    })


# ==================== VUES POUR LES MODULES ====================

class ModuleViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour gérer les modules (cours)
    - Liste et création : enseignants et admins
    - Détail, modification, suppression : enseignant responsable ou admin
    """
    queryset = Module.objects.all()
    serializer_class = ModuleSerializer
    permission_classes = [IsAuthenticated]
    
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return ModuleDetailSerializer
        return ModuleSerializer
    
    def get_permissions(self):
        """
        Les enseignants et admins peuvent créer et lister
        Seul l'enseignant responsable ou l'admin peut modifier/supprimer
        """
        if self.action in ['create', 'list', 'retrieve']:
            return [IsTeacherOrAdmin()]
        elif self.action in ['update', 'partial_update', 'destroy']:
            return [IsModuleTeacherOrAdmin()]
        return [IsAuthenticated()]
    
    def get_queryset(self):
        """
        Filtrer les modules selon le rôle de l'utilisateur
        """
        user = self.request.user
        queryset = Module.objects.all()
        
        # Les étudiants voient uniquement les modules actifs
        if user.role == 'student':
            queryset = queryset.filter(is_active=True)
        # Les enseignants voient leurs modules et tous les modules actifs
        elif user.role == 'teacher':
            queryset = queryset.filter(
                Q(teacher=user) | Q(is_active=True)
            )
        # Les admins voient tout
        
        # Filtres optionnels
        teacher_id = self.request.query_params.get('teacher', None)
        if teacher_id:
            queryset = queryset.filter(teacher_id=teacher_id)
        
        is_active = self.request.query_params.get('is_active', None)
        if is_active is not None:
            queryset = queryset.filter(is_active=is_active.lower() == 'true')
        
        semester = self.request.query_params.get('semester', None)
        if semester:
            queryset = queryset.filter(semester=semester)
        
        return queryset.order_by('code', 'name')
    
    def perform_create(self, serializer):
        """
        Lors de la création, si l'utilisateur est un enseignant,
        il devient automatiquement l'enseignant référent
        """
        user = self.request.user
        if user.role == 'teacher' and not serializer.validated_data.get('teacher'):
            serializer.save(teacher=user)
        else:
            serializer.save()
    
    @action(detail=True, methods=['get'], permission_classes=[IsTeacherOrAdmin])
    def enrollments(self, request, pk=None):
        """
        Récupérer la liste des étudiants inscrits à un module
        GET /api/modules/{id}/enrollments/
        """
        module = self.get_object()
        enrollments = module.enrollments.filter(is_active=True)
        serializer = EnrollmentSerializer(enrollments, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['get'], permission_classes=[IsAuthenticated])
    def my_enrollment(self, request, pk=None):
        """
        Vérifier si l'utilisateur connecté est inscrit au module
        GET /api/modules/{id}/my_enrollment/
        """
        module = self.get_object()
        if request.user.role != 'student':
            return Response({
                'enrolled': False,
                'message': 'Seuls les étudiants peuvent vérifier leur inscription'
            })
        
        try:
            enrollment = Enrollment.objects.get(
                student=request.user,
                module=module,
                is_active=True
            )
            serializer = EnrollmentSerializer(enrollment)
            return Response({
                'enrolled': True,
                'enrollment': serializer.data
            })
        except Enrollment.DoesNotExist:
            return Response({
                'enrolled': False,
                'enrollment': None
            })


# ==================== VUES POUR LES INSCRIPTIONS ====================

class EnrollmentViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour gérer les inscriptions
    - Les étudiants peuvent créer leurs propres inscriptions
    - Les enseignants et admins peuvent voir toutes les inscriptions
    - Les étudiants peuvent désactiver leurs inscriptions
    """
    queryset = Enrollment.objects.all()
    serializer_class = EnrollmentSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """
        Filtrer les inscriptions selon le rôle de l'utilisateur
        """
        user = self.request.user
        
        if user.role == 'student':
            # Les étudiants voient uniquement leurs inscriptions
            return Enrollment.objects.filter(student=user, is_active=True)
        elif user.role == 'teacher':
            # Les enseignants voient les inscriptions de leurs modules
            return Enrollment.objects.filter(
                module__teacher=user,
                is_active=True
            )
        elif user.role == 'admin':
            # Les admins voient toutes les inscriptions
            return Enrollment.objects.all()
        
        return Enrollment.objects.none()
    
    def get_permissions(self):
        """
        Les étudiants peuvent créer leurs propres inscriptions
        Les enseignants et admins peuvent modifier les notes
        """
        if self.action == 'create':
            return [IsStudent()]
        elif self.action in ['update', 'partial_update']:
            return [IsTeacherOrAdmin()]
        elif self.action == 'destroy':
            # Les étudiants peuvent désactiver leurs inscriptions
            return [IsAuthenticated()]
        return [IsAuthenticated()]
    
    def perform_create(self, serializer):
        """
        Créer une inscription pour l'étudiant connecté
        """
        module_id = self.request.data.get('module_id')
        if not module_id:
            raise ValidationError({
                'module_id': 'Ce champ est requis.'
            })
        
        module = get_object_or_404(Module, id=module_id)
        
        # Vérifier si l'étudiant n'est pas déjà inscrit
        if Enrollment.objects.filter(
            student=self.request.user,
            module=module,
            is_active=True
        ).exists():
            raise ValidationError({
                'module': 'Vous êtes déjà inscrit à ce module.'
            })
        
        # Vérifier si le module est plein
        if module.is_full:
            raise ValidationError({
                'module': 'Le module a atteint sa capacité maximale.'
            })
        
        # Vérifier si le module est actif
        if not module.is_active:
            raise ValidationError({
                'module': 'Le module n\'est pas actif.'
            })
        
        serializer.save(student=self.request.user, module=module)
    
    def perform_destroy(self, instance):
        """
        Désactiver l'inscription au lieu de la supprimer
        """
        if self.request.user.role == 'student' and instance.student != self.request.user:
            raise PermissionError("Vous ne pouvez désactiver que vos propres inscriptions.")
        
        instance.is_active = False
        instance.save()


@api_view(['POST'])
@permission_classes([IsStudent])
def enroll_to_module(request, module_id):
    """
    Endpoint pour qu'un étudiant s'inscrive à un module
    POST /api/modules/{module_id}/enroll/
    """
    module = get_object_or_404(Module, id=module_id)
    
    # Vérifier si déjà inscrit
    if Enrollment.objects.filter(
        student=request.user,
        module=module,
        is_active=True
    ).exists():
        return Response({
            'message': 'Vous êtes déjà inscrit à ce module.'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    # Vérifier si le module est plein
    if module.is_full:
        return Response({
            'message': 'Le module a atteint sa capacité maximale.'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    # Vérifier si le module est actif
    if not module.is_active:
        return Response({
            'message': 'Le module n\'est pas actif.'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    enrollment = Enrollment.objects.create(
        student=request.user,
        module=module
    )
    
    serializer = EnrollmentSerializer(enrollment)
    return Response(serializer.data, status=status.HTTP_201_CREATED)


@api_view(['POST'])
@permission_classes([IsStudent])
def unenroll_from_module(request, module_id):
    """
    Endpoint pour qu'un étudiant se désinscrive d'un module
    POST /api/modules/{module_id}/unenroll/
    """
    module = get_object_or_404(Module, id=module_id)
    
    try:
        enrollment = Enrollment.objects.get(
            student=request.user,
            module=module,
            is_active=True
        )
        enrollment.is_active = False
        enrollment.save()
        
        return Response({
            'message': 'Vous avez été désinscrit du module avec succès.'
        }, status=status.HTTP_200_OK)
    except Enrollment.DoesNotExist:
        return Response({
            'message': 'Vous n\'êtes pas inscrit à ce module.'
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['GET'])
@permission_classes([IsStudent])
def my_enrollments(request):
    """
    Endpoint pour qu'un étudiant voie toutes ses inscriptions
    GET /api/enrollments/my/
    """
    enrollments = Enrollment.objects.filter(
        student=request.user,
        is_active=True
    )
    serializer = EnrollmentSerializer(enrollments, many=True)
    return Response(serializer.data)
