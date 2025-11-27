# Documentation de l'API d'Authentification - CampusConnect

## Vue d'ensemble

Cette API fournit un système complet d'authentification avec gestion des rôles (étudiant, enseignant, administrateur) utilisant JWT (JSON Web Tokens).

## Endpoints disponibles

### 1. Inscription (Register)
**POST** `/api/auth/register/`

Permet à un nouvel utilisateur de s'inscrire avec un rôle spécifique.

**Corps de la requête (JSON) :**
```json
{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "securepassword123",
  "password2": "securepassword123",
  "first_name": "John",
  "last_name": "Doe",
  "role": "student",
  "phone": "+1234567890",
  "student_id": "STU001",
  "enrollment_date": "2024-01-15",
  "major": "Informatique",
  "year": 2
}
```

**Pour un enseignant :**
```json
{
  "username": "jane_teacher",
  "email": "jane@example.com",
  "password": "securepassword123",
  "password2": "securepassword123",
  "first_name": "Jane",
  "last_name": "Smith",
  "role": "teacher",
  "phone": "+1234567890",
  "employee_id": "EMP001",
  "department": "Informatique",
  "hire_date": "2020-09-01",
  "specialization": "Intelligence Artificielle"
}
```

**Réponse (201 Created) :**
```json
{
  "message": "Inscription réussie",
  "user": {
    "id": 1,
    "username": "john_doe",
    "email": "john@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "role": "student",
    "role_display": "Étudiant",
    "phone": "+1234567890",
    "is_active": true,
    "date_joined": "2024-01-15T10:00:00Z",
    "created_at": "2024-01-15T10:00:00Z",
    "updated_at": "2024-01-15T10:00:00Z"
  },
  "tokens": {
    "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
  }
}
```

---

### 2. Connexion (Login)
**POST** `/api/auth/login/`

Permet à un utilisateur de se connecter et d'obtenir des tokens JWT.

**Corps de la requête (JSON) :**
```json
{
  "username": "john_doe",
  "password": "securepassword123"
}
```

**Réponse (200 OK) :**
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {
    "id": 1,
    "username": "john_doe",
    "email": "john@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "role": "student",
    "role_display": "Étudiant",
    "phone": "+1234567890",
    "is_active": true,
    "date_joined": "2024-01-15T10:00:00Z",
    "created_at": "2024-01-15T10:00:00Z",
    "updated_at": "2024-01-15T10:00:00Z"
  }
}
```

---

### 3. Rafraîchir le token (Refresh Token)
**POST** `/api/auth/refresh/`

Permet de renouveler l'access token en utilisant le refresh token.

**Corps de la requête (JSON) :**
```json
{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

**Réponse (200 OK) :**
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

---

### 4. Informations de l'utilisateur connecté (Me)
**GET** `/api/auth/me/`

Récupère les informations de l'utilisateur actuellement connecté.

**Headers :**
```
Authorization: Bearer <access_token>
```

**Réponse (200 OK) :**
```json
{
  "id": 1,
  "username": "john_doe",
  "email": "john@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "role": "student",
  "role_display": "Étudiant",
  "phone": "+1234567890",
  "is_active": true,
  "date_joined": "2024-01-15T10:00:00Z",
  "created_at": "2024-01-15T10:00:00Z",
  "updated_at": "2024-01-15T10:00:00Z"
}
```

---

### 5. Profil utilisateur (GET/PUT)
**GET** `/api/auth/profile/` - Récupérer le profil
**PUT** `/api/auth/profile/` - Mettre à jour le profil

**Headers :**
```
Authorization: Bearer <access_token>
```

**Corps de la requête PUT (JSON) :**
```json
{
  "first_name": "John",
  "last_name": "Doe",
  "email": "newemail@example.com",
  "phone": "+1234567890"
}
```

---

### 6. Changer le mot de passe
**PUT** `/api/auth/change-password/`

**Headers :**
```
Authorization: Bearer <access_token>
```

**Corps de la requête (JSON) :**
```json
{
  "old_password": "oldpassword123",
  "new_password": "newpassword123",
  "new_password2": "newpassword123"
}
```

**Réponse (200 OK) :**
```json
{
  "message": "Mot de passe modifié avec succès"
}
```

---

## Endpoints de test des permissions

### Étudiant uniquement
**GET** `/api/auth/student-only/`

Accessible uniquement aux utilisateurs avec le rôle "student".

**Headers :**
```
Authorization: Bearer <access_token>
```

### Enseignant uniquement
**GET** `/api/auth/teacher-only/`

Accessible uniquement aux utilisateurs avec le rôle "teacher".

**Headers :**
```
Authorization: Bearer <access_token>
```

### Administrateur uniquement
**GET** `/api/auth/admin-only/`

Accessible uniquement aux utilisateurs avec le rôle "admin".

**Headers :**
```
Authorization: Bearer <access_token>
```

---

## Rôles disponibles

- **student** : Étudiant
- **teacher** : Enseignant
- **admin** : Administrateur

## Permissions personnalisées

Les permissions suivantes sont disponibles pour protéger vos vues :

- `IsStudent` : Vérifie que l'utilisateur est un étudiant
- `IsTeacher` : Vérifie que l'utilisateur est un enseignant
- `IsAdmin` : Vérifie que l'utilisateur est un administrateur
- `IsTeacherOrAdmin` : Vérifie que l'utilisateur est un enseignant ou un administrateur

**Exemple d'utilisation dans une vue :**
```python
from rest_framework import viewsets
from api.permissions import IsStudent

class MyViewSet(viewsets.ModelViewSet):
    permission_classes = [IsStudent]
    # ...
```

---

## Configuration JWT

- **Access Token Lifetime** : 60 minutes
- **Refresh Token Lifetime** : 7 jours
- **Token Rotation** : Activée (les refresh tokens sont mis à jour après utilisation)

---

## Exemples avec cURL

### Inscription
```bash
curl -X POST http://localhost:8000/api/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john_doe",
    "email": "john@example.com",
    "password": "securepassword123",
    "password2": "securepassword123",
    "first_name": "John",
    "last_name": "Doe",
    "role": "student",
    "student_id": "STU001"
  }'
```

### Connexion
```bash
curl -X POST http://localhost:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john_doe",
    "password": "securepassword123"
  }'
```

### Récupérer les informations utilisateur
```bash
curl -X GET http://localhost:8000/api/auth/me/ \
  -H "Authorization: Bearer <access_token>"
```

### Rafraîchir le token
```bash
curl -X POST http://localhost:8000/api/auth/refresh/ \
  -H "Content-Type: application/json" \
  -d '{
    "refresh": "<refresh_token>"
  }'
```

---

## Codes de statut HTTP

- **200 OK** : Requête réussie
- **201 Created** : Ressource créée avec succès
- **400 Bad Request** : Données invalides
- **401 Unauthorized** : Token manquant ou invalide
- **403 Forbidden** : Permissions insuffisantes
- **404 Not Found** : Ressource non trouvée

---

## Notes importantes

1. Tous les endpoints (sauf register et login) nécessitent un token JWT valide dans le header `Authorization: Bearer <token>`.

2. Le refresh token doit être utilisé pour obtenir un nouvel access token avant l'expiration de celui-ci.

3. Les champs `student_id` et `employee_id` sont obligatoires respectivement pour les étudiants et les enseignants lors de l'inscription.

4. Les mots de passe doivent respecter les validations Django (longueur minimale, complexité, etc.).

