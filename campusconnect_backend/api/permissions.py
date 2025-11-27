from rest_framework import permissions


class IsStudent(permissions.BasePermission):
    """
    Permission pour vérifier si l'utilisateur est un étudiant
    """
    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            request.user.role == 'student'
        )


class IsTeacher(permissions.BasePermission):
    """
    Permission pour vérifier si l'utilisateur est un enseignant
    """
    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            request.user.role == 'teacher'
        )


class IsAdmin(permissions.BasePermission):
    """
    Permission pour vérifier si l'utilisateur est un administrateur
    """
    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            request.user.role == 'admin'
        )


class IsTeacherOrAdmin(permissions.BasePermission):
    """
    Permission pour vérifier si l'utilisateur est un enseignant ou un administrateur
    """
    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            request.user.role in ['teacher', 'admin']
        )

