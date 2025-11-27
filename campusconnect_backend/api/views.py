from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from django.contrib.auth import get_user_model

from .serializers import (
    RegisterSerializer,
    UserSerializer,
    ChangePasswordSerializer
)
from .permissions import IsStudent, IsTeacher, IsAdmin

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
