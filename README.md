# AURAGOAL — App mobile Flutter

Plateforme de développement personnel : objectifs, habitudes, journal,
gamification et coach IA (AURA). Voir le cahier des charges complet pour
la vision produit détaillée.

## Stack technique

- **Flutter** (Dart) — mobile iOS + Android à partir d'une seule base de code
- **Riverpod** — gestion d'état
- **go_router** — navigation (routes nommées, deep links)
- **Supabase** — backend (Postgres + Auth + Storage + Realtime)

## Structure du projet (feature-first)

```
lib/
  main.dart                 → point d'entrée, initialise Supabase
  app.dart                  → widget racine (thème + routeur)

  core/                     → tout ce qui est transverse à l'app
    config/                 → configuration générale
    constants/              → constantes (XP, actions AURA autorisées...)
    theme/                  → couleurs, thème clair/sombre
    router/                 → go_router, routes nommées
    services/               → accès Supabase centralisé
    providers/              → providers Riverpod globaux (auth, client...)
    utils/                  → fonctions utilitaires

  features/                 → un dossier par fonctionnalité métier
    auth/                   → connexion, inscription
    onboarding/             → parcours de bienvenue
    dashboard/              → tableau de bord
    goals/                  → objectifs, sous-objectifs, étapes
    habits/                 → habitudes, check-in, séries
    journal/                → journal privé, réflexions
    gamification/           → XP, niveaux, badges, ledger XP
    aura/                   → coach IA — contexte, propositions, actions
    focus/                  → sessions AURA Focus
    profile/                → profil utilisateur
    settings/               → paramètres, confidentialité, abonnement

    Chaque feature suit (au fur et à mesure des besoins) :
      data/          → accès Supabase, modèles de données bruts
      domain/        → logique métier, entités
      presentation/
        screens/     → écrans complets
        widgets/     → composants réutilisables de la feature

  shared/                   → widgets et modèles partagés entre features
    widgets/                → ex. RootShell (navigation basse)
    models/                 → modèles transverses
```

## Pourquoi cette organisation

- **Feature-first** plutôt que "par couche" (tous les screens ensemble, tous
  les models ensemble) : plus facile à faire évoluer et à confier des
  parties à d'autres développeurs plus tard sans tout mélanger.
- **`core/services/supabase_service.dart`** centralise l'accès à Supabase :
  aucun widget n'appelle Supabase directement, ce qui facilite les tests et
  respecte le principe du cahier des charges ("aucune clé IA/API sensible
  dispersée dans le client").
- **`core/constants/app_constants.dart`** contient déjà la liste des actions
  AURA autorisées (`CREATE_GOAL`, `UPDATE_GOAL`, etc.) — le backend (pas le
  modèle IA lui-même) doit être la seule autorité qui décide si une action
  proposée est valide et l'exécute.

## Étapes déjà faites

- [x] Structure de projet feature-first
- [x] `pubspec.yaml` avec les dépendances principales
- [x] Thème (couleurs bleu/cyan/violet, clair + sombre)
- [x] Routeur avec navigation basse (Accueil, Objectifs, Aura, Habitudes,
      Journal) et écrans placeholders
- [x] Connexion Supabase initialisée dans `main.dart`

## Prochaines étapes

1. Créer le projet Supabase et remplir `.env` (voir `.env.example`)
2. Définir le schéma de base (tables `users`, `goals`, `habits`, etc.) avec
   Row Level Security dès le départ
3. Implémenter l'authentification (écrans + logique Supabase Auth)
4. Implémenter le dashboard et les objectifs (Phase 1 du cahier des charges)

## Démarrage local

```bash
flutter pub get
cp .env.example .env   # puis renseigner tes clés Supabase
flutter run
```
