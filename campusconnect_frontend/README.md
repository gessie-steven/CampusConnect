# CampusConnect Frontend

Application mobile Flutter pour CampusConnect - Plateforme de gestion académique pour étudiants et enseignants.

## Architecture

Le projet suit une architecture Clean Architecture avec les couches suivantes :

- **presentation/** : Interface utilisateur, pages, widgets, providers
- **domain/** : Entités métier, use cases
- **data/** : Repositories, datasources, modèles de données
- **core/** : Constantes, utilitaires, gestion d'erreurs

## Structure du projet

```
lib/
├── core/
│   ├── constants/     # Constantes de l'application
│   ├── utils/         # Utilitaires
│   └── errors/        # Gestion des erreurs
├── data/
│   ├── datasources/   # Sources de données (API, local)
│   ├── models/        # Modèles de données
│   └── repositories/  # Implémentation des repositories
├── domain/
│   ├── entities/      # Entités métier
│   └── usecases/      # Cas d'utilisation
└── presentation/
    ├── pages/         # Pages de l'application
    ├── widgets/       # Widgets réutilisables
    └── providers/     # Providers pour la gestion d'état
```

## Dépendances principales

- **dio** : Client HTTP pour les appels API
- **provider** : Gestion d'état
- **flutter_secure_storage** : Stockage sécurisé des tokens
- **shared_preferences** : Stockage local
- **flutter_local_notifications** : Notifications locales

## Routes

- `/login` : Page de connexion
- `/signup` : Page d'inscription
- `/dashboard` : Tableau de bord principal
- `/student/home` : Espace étudiant
- `/teacher/home` : Espace enseignant
- `/admin/home` : Espace administrateur

## Configuration

1. Installer les dépendances :
```bash
flutter pub get
```

2. Configurer l'URL de l'API dans `lib/core/constants/app_constants.dart`

3. Lancer l'application :
```bash
flutter run
```

## Développement

Le projet est prêt pour l'intégration avec l'API Django REST Framework backend.
