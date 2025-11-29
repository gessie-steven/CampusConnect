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
from django.utils import timezone

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
    CourseResourceUploadSerializer,
    GradeSerializer,
    AnnouncementSerializer,
    ChatMessageSerializer,
    ChatMessageCreateSerializer,
    NotificationSerializer
)
from .permissions import IsStudent, IsTeacher, IsAdmin, IsTeacherOrAdmin, IsModuleTeacherOrAdmin
from .models import Module, Enrollment, CourseSession, CourseResource, Grade, Announcement, ChatMessage, Notification

User = get_user_model()


class UserViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour la gestion des utilisateurs
    - Admin : accès complet
    - Enseignant : peut voir les étudiants (pour créer des notes)
    """
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_permissions(self):
        """
        Les enseignants peuvent seulement lister les étudiants (pour créer des notes)
        Les admins ont un accès complet
        """
        if self.action in ['list']:
            user = self.request.user
            if user.role == 'teacher':
                # Les enseignants peuvent lister les étudiants
                return [IsAuthenticated()]
            elif user.role == 'admin':
                return [IsAuthenticated()]
            return [IsAdmin()]
        else:
            # Pour create, update, delete, seul l'admin peut
            return [IsAdmin()]

    def get_queryset(self):
        queryset = User.objects.all()
        user = self.request.user
        role = self.request.query_params.get('role', None)
        
        # Les enseignants ne peuvent voir que les étudiants
        if user.role == 'teacher':
            queryset = queryset.filter(role='student')
            # Si un rôle est spécifié, ignorer si ce n'est pas 'student'
            if role and role != 'student':
                queryset = queryset.none()
        # Les admins voient tout
        elif user.role == 'admin':
            if role:
                queryset = queryset.filter(role=role)
        else:
            # Pour les autres rôles, retourner une queryset vide
            queryset = queryset.none()
        
        return queryset.order_by('-date_joined')


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


# ==================== VUES POUR LES NOTES ====================

class GradeViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour gérer les notes des étudiants
    - Lecture : étudiants (leurs notes), enseignants (notes de leurs modules), admins
    - Création/modification/suppression : enseignants (leurs modules) et admins
    """
    queryset = Grade.objects.all()
    serializer_class = GradeSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """
        Filtrer les notes selon le rôle de l'utilisateur
        """
        user = self.request.user
        
        if user.role == 'student':
            # Les étudiants voient uniquement leurs notes
            queryset = Grade.objects.filter(student=user)
        elif user.role == 'teacher':
            # Les enseignants voient les notes des modules qu'ils enseignent
            queryset = Grade.objects.filter(module__teacher=user)
        elif user.role == 'admin':
            # Les admins voient toutes les notes
            queryset = Grade.objects.all()
        else:
            queryset = Grade.objects.none()
        
        # Filtres optionnels
        module_id = self.request.query_params.get('module', None)
        if module_id:
            queryset = queryset.filter(module_id=module_id)
        
        student_id = self.request.query_params.get('student', None)
        if student_id:
            queryset = queryset.filter(student_id=student_id)
        
        grade_type = self.request.query_params.get('grade_type', None)
        if grade_type:
            queryset = queryset.filter(grade_type=grade_type)
        
        return queryset.order_by('-graded_date')
    
    def get_permissions(self):
        """
        Les étudiants peuvent uniquement lire leurs notes
        Les enseignants et admins peuvent créer/modifier/supprimer
        """
        if self.action in ['list', 'retrieve']:
            return [IsAuthenticated()]
        elif self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsTeacherOrAdmin()]
        return [IsAuthenticated()]
    
    def perform_create(self, serializer):
        """
        Enregistrer qui a noté l'étudiant
        """
        serializer.save(graded_by=self.request.user)
    
    def perform_update(self, serializer):
        """
        Vérifier que l'enseignant peut modifier la note
        """
        instance = self.get_object()
        user = self.request.user
        
        # Les admins peuvent tout modifier
        if user.role == 'admin':
            serializer.save()
        # Les enseignants ne peuvent modifier que les notes de leurs modules
        elif user.role == 'teacher' and instance.module.teacher == user:
            serializer.save()
        else:
            raise PermissionError("Vous n'avez pas la permission de modifier cette note.")


@api_view(['GET'])
@permission_classes([IsStudent])
def my_grades(request):
    """
    Endpoint pour qu'un étudiant voie toutes ses notes
    GET /api/grades/my/
    """
    grades = Grade.objects.filter(student=request.user)
    
    # Filtres optionnels
    module_id = request.query_params.get('module', None)
    if module_id:
        grades = grades.filter(module_id=module_id)
    
    grade_type = request.query_params.get('grade_type', None)
    if grade_type:
        grades = grades.filter(grade_type=grade_type)
    
    serializer = GradeSerializer(grades.order_by('-graded_date'), many=True)
    return Response(serializer.data)


# ==================== VUES POUR LES ANNONCES ====================

class AnnouncementViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour gérer les annonces/messages
    - Lecture : étudiants (annonces de leurs modules ou générales), enseignants (leurs annonces), admins
    - Création/modification/suppression : enseignants (leurs modules) et admins
    """
    queryset = Announcement.objects.all()
    serializer_class = AnnouncementSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """
        Filtrer les annonces selon le rôle de l'utilisateur
        """
        user = self.request.user
        
        if user.role == 'student':
            # Les étudiants voient les annonces des modules où ils sont inscrits ou les annonces générales
            enrolled_modules = Module.objects.filter(
                enrollments__student=user,
                enrollments__is_active=True
            )
            queryset = Announcement.objects.filter(
                Q(module__in=enrolled_modules) | Q(module__isnull=True),
                is_active=True
            )
            # Filtrer par date d'expiration
            from django.utils import timezone
            queryset = queryset.filter(
                Q(expiry_date__isnull=True) | Q(expiry_date__gt=timezone.now())
            )
        elif user.role == 'teacher':
            # Les enseignants voient les annonces de leurs modules
            queryset = Announcement.objects.filter(module__teacher=user)
        elif user.role == 'admin':
            # Les admins voient toutes les annonces
            queryset = Announcement.objects.all()
        else:
            queryset = Announcement.objects.none()
        
        # Filtres optionnels
        module_id = self.request.query_params.get('module', None)
        if module_id:
            queryset = queryset.filter(module_id=module_id)
        
        author_id = self.request.query_params.get('author', None)
        if author_id:
            queryset = queryset.filter(author_id=author_id)
        
        priority = self.request.query_params.get('priority', None)
        if priority:
            queryset = queryset.filter(priority=priority)
        
        is_pinned = self.request.query_params.get('is_pinned', None)
        if is_pinned is not None:
            queryset = queryset.filter(is_pinned=is_pinned.lower() == 'true')
        
        return queryset.order_by('-is_pinned', '-published_date')
    
    def get_permissions(self):
        """
        Tous les utilisateurs authentifiés peuvent lire
        Les enseignants et admins peuvent créer/modifier/supprimer
        """
        if self.action in ['list', 'retrieve']:
            return [IsAuthenticated()]
        elif self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsTeacherOrAdmin()]
        return [IsAuthenticated()]
    
    def perform_create(self, serializer):
        """
        Enregistrer l'auteur de l'annonce
        """
        serializer.save(author=self.request.user)
    
    def perform_update(self, serializer):
        """
        Vérifier que l'utilisateur peut modifier l'annonce
        """
        instance = self.get_object()
        user = self.request.user
        
        # Les admins peuvent tout modifier
        if user.role == 'admin':
            serializer.save()
        # Les enseignants ne peuvent modifier que leurs annonces
        elif user.role == 'teacher' and instance.author == user:
            serializer.save()
        else:
            raise PermissionError("Vous n'avez pas la permission de modifier cette annonce.")


@api_view(['GET'])
@permission_classes([IsStudent])
def my_announcements(request):
    """
    Endpoint pour qu'un étudiant voie toutes les annonces qui le concernent
    GET /api/announcements/my/
    """
    enrolled_modules = Module.objects.filter(
        enrollments__student=request.user,
        enrollments__is_active=True
    )
    
    # Annonces des modules où l'étudiant est inscrit ou annonces générales
    announcements = Announcement.objects.filter(
        Q(module__in=enrolled_modules) | Q(module__isnull=True),
        is_active=True
    )
    
    # Filtrer par date d'expiration
    from django.utils import timezone
    announcements = announcements.filter(
        Q(expiry_date__isnull=True) | Q(expiry_date__gt=timezone.now())
    )
    
    # Filtres optionnels
    module_id = request.query_params.get('module', None)
    if module_id:
        announcements = announcements.filter(module_id=module_id)
    
    priority = request.query_params.get('priority', None)
    if priority:
        announcements = announcements.filter(priority=priority)
    
    serializer = AnnouncementSerializer(announcements.order_by('-is_pinned', '-published_date'), many=True)
    return Response(serializer.data)


# ==================== VUES POUR LES MESSAGES ====================

class ChatMessageViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour gérer les messages de chat
    - Les utilisateurs peuvent envoyer et recevoir des messages
    - Chaque utilisateur ne voit que ses messages (envoyés ou reçus)
    """
    queryset = ChatMessage.objects.all()
    serializer_class = ChatMessageSerializer
    permission_classes = [IsAuthenticated]
    
    def get_serializer_class(self):
        if self.action == 'create':
            return ChatMessageCreateSerializer
        return ChatMessageSerializer
    
    def get_queryset(self):
        """
        Filtrer les messages pour ne montrer que ceux de l'utilisateur connecté
        """
        user = self.request.user
        
        # L'utilisateur voit les messages qu'il a envoyés et reçus
        queryset = ChatMessage.objects.filter(
            Q(sender=user) | Q(recipient=user)
        )
        
        # Filtres optionnels
        other_user_id = self.request.query_params.get('user', None)
        if other_user_id:
            # Messages avec un utilisateur spécifique
            queryset = queryset.filter(
                Q(sender=user, recipient_id=other_user_id) |
                Q(sender_id=other_user_id, recipient=user)
            )
        
        is_read = self.request.query_params.get('is_read', None)
        if is_read is not None:
            # Filtrer par statut de lecture (seulement pour les messages reçus)
            if is_read.lower() == 'true':
                queryset = queryset.filter(recipient=user, is_read=True)
            else:
                queryset = queryset.filter(recipient=user, is_read=False)
        
        return queryset.order_by('-created_at')
    
    def perform_create(self, serializer):
        """
        Créer un message avec l'utilisateur connecté comme expéditeur
        """
        recipient_id = serializer.validated_data['recipient_id']
        message_text = serializer.validated_data['message']
        
        from django.contrib.auth import get_user_model
        User = get_user_model()
        recipient = get_object_or_404(User, id=recipient_id)
        
        # Créer le message
        chat_message = ChatMessage.objects.create(
            sender=self.request.user,
            recipient=recipient,
            message=message_text
        )
        
        # Créer une notification pour le destinataire
        Notification.create_for_user(
            user=recipient,
            notification_type='message',
            title='Nouveau message',
            content=f"Vous avez reçu un message de {self.request.user.get_full_name() or self.request.user.username}",
            link=f"/messages/{chat_message.id}/"
        )
    
    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def mark_as_read(self, request, pk=None):
        """
        Marquer un message comme lu
        POST /api/messages/{id}/mark_as_read/
        """
        message = self.get_object()
        
        # Seul le destinataire peut marquer le message comme lu
        if message.recipient != request.user:
            return Response({
                'error': 'Vous ne pouvez marquer comme lu que les messages que vous avez reçus.'
            }, status=status.HTTP_403_FORBIDDEN)
        
        message.mark_as_read()
        serializer = self.get_serializer(message)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def conversations(self, request):
        """
        Récupérer la liste des conversations (utilisateurs avec qui on a échangé)
        GET /api/messages/conversations/
        """
        user = request.user
        
        # Récupérer les IDs des utilisateurs avec qui on a échangé
        sent_to = ChatMessage.objects.filter(sender=user).values_list('recipient_id', flat=True).distinct()
        received_from = ChatMessage.objects.filter(recipient=user).values_list('sender_id', flat=True).distinct()
        
        # Combiner et obtenir les utilisateurs uniques
        user_ids = set(list(sent_to) + list(received_from))
        
        from django.contrib.auth import get_user_model
        User = get_user_model()
        users = User.objects.filter(id__in=user_ids)
        
        # Pour chaque utilisateur, récupérer le dernier message
        conversations = []
        for other_user in users:
            last_message = ChatMessage.objects.filter(
                Q(sender=user, recipient=other_user) | Q(sender=other_user, recipient=user)
            ).order_by('-created_at').first()
            
            unread_count = ChatMessage.objects.filter(
                sender=other_user,
                recipient=user,
                is_read=False
            ).count()
            
            conversations.append({
                'user': UserSerializer(other_user).data,
                'last_message': ChatMessageSerializer(last_message).data if last_message else None,
                'unread_count': unread_count
            })
        
        # Trier par date du dernier message
        conversations.sort(key=lambda x: x['last_message']['created_at'] if x['last_message'] else '', reverse=True)
        
        return Response(conversations)


# ==================== VUES POUR LES NOTIFICATIONS ====================

class NotificationViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet pour gérer les notifications (lecture seule pour les utilisateurs)
    - Les utilisateurs peuvent uniquement lire leurs propres notifications
    - Les admins peuvent créer des notifications
    """
    queryset = Notification.objects.all()
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """
        Filtrer les notifications pour ne montrer que celles de l'utilisateur connecté
        """
        user = self.request.user
        
        queryset = Notification.objects.filter(recipient=user)
        
        # Filtres optionnels
        notification_type = self.request.query_params.get('type', None)
        if notification_type:
            queryset = queryset.filter(notification_type=notification_type)
        
        is_read = self.request.query_params.get('is_read', None)
        if is_read is not None:
            queryset = queryset.filter(is_read=is_read.lower() == 'true')
        
        return queryset.order_by('-created_at')
    
    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def mark_as_read(self, request, pk=None):
        """
        Marquer une notification comme lue
        POST /api/notifications/{id}/mark_as_read/
        """
        notification = self.get_object()
        
        # Seul le destinataire peut marquer la notification comme lue
        if notification.recipient != request.user:
            return Response({
                'error': 'Vous ne pouvez marquer comme lu que vos propres notifications.'
            }, status=status.HTTP_403_FORBIDDEN)
        
        notification.mark_as_read()
        serializer = self.get_serializer(notification)
        return Response(serializer.data)
    
    @action(detail=False, methods=['post'], permission_classes=[IsAuthenticated])
    def mark_all_as_read(self, request):
        """
        Marquer toutes les notifications comme lues
        POST /api/notifications/mark_all_as_read/
        """
        user = request.user
        updated = Notification.objects.filter(
            recipient=user,
            is_read=False
        ).update(
            is_read=True,
            read_at=timezone.now()
        )
        
        return Response({
            'message': f'{updated} notification(s) marquée(s) comme lue(s).'
        })
    
    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def unread_count(self, request):
        """
        Récupérer le nombre de notifications non lues
        GET /api/notifications/unread_count/
        """
        user = request.user
        count = Notification.objects.filter(
            recipient=user,
            is_read=False
        ).count()
        
        return Response({
            'unread_count': count
        })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_messages(request):
    """
    Endpoint pour récupérer les messages récents de l'utilisateur
    GET /api/messages/my/
    """
    user = request.user
    
    # Récupérer les messages récents (envoyés et reçus)
    messages = ChatMessage.objects.filter(
        Q(sender=user) | Q(recipient=user)
    ).order_by('-created_at')[:50]  # Limiter à 50 messages récents
    
    serializer = ChatMessageSerializer(messages, many=True)
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_unread_notifications(request):
    """
    Endpoint pour récupérer les notifications non lues
    GET /api/notifications/unread/
    """
    user = request.user
    
    notifications = Notification.objects.filter(
        recipient=user,
        is_read=False
    ).order_by('-created_at')
    
    serializer = NotificationSerializer(notifications, many=True)
    return Response(serializer.data)
