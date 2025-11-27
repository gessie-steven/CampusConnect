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
    TeacherProfileSerializer,
    CourseSessionSerializer,
    CourseResourceSerializer,
    CourseResourceUploadSerializer
)
from .permissions import IsStudent, IsTeacher, IsAdmin, IsTeacherOrAdmin, IsModuleTeacherOrAdmin
from .models import Module, Enrollment, CourseSession, CourseResource

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


# ==================== VUES POUR LES SESSIONS DE COURS ====================

class CourseSessionViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour gérer les sessions de cours (emploi du temps)
    - Lecture : tous les utilisateurs authentifiés (filtré selon le rôle)
    - Création/modification/suppression : enseignants (leurs modules) et admins
    """
    queryset = CourseSession.objects.all()
    serializer_class = CourseSessionSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """
        Filtrer les sessions selon le rôle de l'utilisateur
        """
        user = self.request.user
        queryset = CourseSession.objects.all()
        
        # Les étudiants voient uniquement les sessions des modules où ils sont inscrits
        if user.role == 'student':
            enrolled_modules = Module.objects.filter(
                enrollments__student=user,
                enrollments__is_active=True
            )
            queryset = queryset.filter(module__in=enrolled_modules)
        # Les enseignants voient les sessions de leurs modules
        elif user.role == 'teacher':
            queryset = queryset.filter(module__teacher=user)
        # Les admins voient tout
        
        # Filtres optionnels
        module_id = self.request.query_params.get('module', None)
        if module_id:
            queryset = queryset.filter(module_id=module_id)
        
        teacher_id = self.request.query_params.get('teacher', None)
        if teacher_id:
            queryset = queryset.filter(teacher_id=teacher_id)
        
        date_from = self.request.query_params.get('date_from', None)
        if date_from:
            queryset = queryset.filter(date__gte=date_from)
        
        date_to = self.request.query_params.get('date_to', None)
        if date_to:
            queryset = queryset.filter(date__lte=date_to)
        
        session_type = self.request.query_params.get('session_type', None)
        if session_type:
            queryset = queryset.filter(session_type=session_type)
        
        return queryset.order_by('date', 'start_time')
    
    def get_permissions(self):
        """
        Les étudiants peuvent uniquement lire
        Les enseignants et admins peuvent créer/modifier/supprimer
        """
        if self.action in ['list', 'retrieve']:
            return [IsAuthenticated()]
        elif self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsTeacherOrAdmin()]
        return [IsAuthenticated()]
    
    def perform_create(self, serializer):
        """
        Lors de la création, si l'utilisateur est un enseignant,
        il devient automatiquement l'enseignant de la session
        """
        user = self.request.user
        if user.role == 'teacher' and not serializer.validated_data.get('teacher'):
            serializer.save(teacher=user)
        else:
            serializer.save()
    
    def perform_update(self, serializer):
        """
        Vérifier que l'enseignant peut modifier la session
        """
        instance = self.get_object()
        user = self.request.user
        
        # Les admins peuvent tout modifier
        if user.role == 'admin':
            serializer.save()
        # Les enseignants ne peuvent modifier que leurs sessions
        elif user.role == 'teacher' and instance.module.teacher == user:
            serializer.save()
        else:
            raise PermissionError("Vous n'avez pas la permission de modifier cette session.")


# ==================== VUES POUR LES RESSOURCES DE COURS ====================

class CourseResourceViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour gérer les ressources de cours
    - Lecture : étudiants (modules où ils sont inscrits), enseignants (leurs modules), admins
    - Création/modification/suppression : enseignants (leurs modules) et admins
    """
    queryset = CourseResource.objects.all()
    serializer_class = CourseResourceSerializer
    permission_classes = [IsAuthenticated]
    
    def get_serializer_class(self):
        if self.action == 'create':
            return CourseResourceUploadSerializer
        return CourseResourceSerializer
    
    def get_queryset(self):
        """
        Filtrer les ressources selon le rôle de l'utilisateur
        """
        user = self.request.user
        queryset = CourseResource.objects.all()
        
        # Les étudiants voient uniquement les ressources publiques des modules où ils sont inscrits
        if user.role == 'student':
            enrolled_modules = Module.objects.filter(
                enrollments__student=user,
                enrollments__is_active=True
            )
            queryset = queryset.filter(
                module__in=enrolled_modules,
                is_public=True
            )
        # Les enseignants voient les ressources de leurs modules
        elif user.role == 'teacher':
            queryset = queryset.filter(module__teacher=user)
        # Les admins voient tout
        
        # Filtres optionnels
        module_id = self.request.query_params.get('module', None)
        if module_id:
            queryset = queryset.filter(module_id=module_id)
        
        resource_type = self.request.query_params.get('resource_type', None)
        if resource_type:
            queryset = queryset.filter(resource_type=resource_type)
        
        is_public = self.request.query_params.get('is_public', None)
        if is_public is not None:
            queryset = queryset.filter(is_public=is_public.lower() == 'true')
        
        return queryset.order_by('-created_at')
    
    def get_permissions(self):
        """
        Les étudiants peuvent uniquement lire et télécharger
        Les enseignants et admins peuvent créer/modifier/supprimer
        """
        if self.action in ['list', 'retrieve', 'download']:
            return [IsAuthenticated()]
        elif self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsTeacherOrAdmin()]
        return [IsAuthenticated()]
    
    def perform_create(self, serializer):
        """
        Enregistrer qui a uploadé la ressource
        """
        serializer.save(uploaded_by=self.request.user)
    
    def perform_update(self, serializer):
        """
        Vérifier que l'enseignant peut modifier la ressource
        """
        instance = self.get_object()
        user = self.request.user
        
        # Les admins peuvent tout modifier
        if user.role == 'admin':
            serializer.save()
        # Les enseignants ne peuvent modifier que les ressources de leurs modules
        elif user.role == 'teacher' and instance.module.teacher == user:
            serializer.save()
        else:
            raise PermissionError("Vous n'avez pas la permission de modifier cette ressource.")
    
    @action(detail=True, methods=['get'], permission_classes=[IsAuthenticated])
    def download(self, request, pk=None):
        """
        Télécharger une ressource et incrémenter le compteur
        GET /api/resources/{id}/download/
        """
        resource = self.get_object()
        
        # Vérifier les permissions
        user = request.user
        
        if user.role == 'student':
            # Vérifier que l'étudiant est inscrit au module
            if not Enrollment.objects.filter(
                student=user,
                module=resource.module,
                is_active=True
            ).exists():
                return Response({
                    'error': 'Vous n\'êtes pas inscrit à ce module.'
                }, status=status.HTTP_403_FORBIDDEN)
            
            # Vérifier que la ressource est publique
            if not resource.is_public:
                return Response({
                    'error': 'Cette ressource n\'est pas publique.'
                }, status=status.HTTP_403_FORBIDDEN)
        
        # Incrémenter le compteur de téléchargements
        resource.download_count += 1
        resource.save(update_fields=['download_count'])
        
        # Si c'est un fichier, retourner l'URL de téléchargement
        if resource.file:
            serializer = self.get_serializer(resource)
            return Response({
                'message': 'Ressource disponible',
                'file_url': serializer.data['file_url'],
                'download_count': resource.download_count
            })
        elif resource.external_url:
            return Response({
                'message': 'Ressource externe',
                'external_url': resource.external_url,
                'download_count': resource.download_count
            })
        
        return Response({
            'error': 'Aucun fichier ou URL disponible.'
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_schedule(request):
    """
    Endpoint pour récupérer l'emploi du temps de l'utilisateur connecté
    GET /api/schedule/my/
    """
    user = request.user
    
    if user.role == 'student':
        # Sessions des modules où l'étudiant est inscrit
        enrolled_modules = Module.objects.filter(
            enrollments__student=user,
            enrollments__is_active=True
        )
        sessions = CourseSession.objects.filter(module__in=enrolled_modules)
    elif user.role == 'teacher':
        # Sessions des modules de l'enseignant
        sessions = CourseSession.objects.filter(module__teacher=user)
    elif user.role == 'admin':
        # Toutes les sessions
        sessions = CourseSession.objects.all()
    else:
        sessions = CourseSession.objects.none()
    
    # Filtres optionnels
    date_from = request.query_params.get('date_from', None)
    if date_from:
        sessions = sessions.filter(date__gte=date_from)
    
    date_to = request.query_params.get('date_to', None)
    if date_to:
        sessions = sessions.filter(date__lte=date_to)
    
    serializer = CourseSessionSerializer(sessions.order_by('date', 'start_time'), many=True)
    return Response(serializer.data)
