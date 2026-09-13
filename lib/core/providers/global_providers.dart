import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/onboarding/data/profile_repository.dart';
import '../services/supabase_service.dart';

/// Client Supabase, injectable et testable (mockable en test).
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseService.client;
});

/// Repository d'authentification, injectable et testable.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

/// Repository du profil utilisateur.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

/// Flux temps réel du profil de l'utilisateur connecté — se met à jour
/// automatiquement dès qu'une ligne "profiles" change (XP, niveau, etc.).
final currentProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  // On relance le flux à chaque changement d'état d'auth (connexion/déconnexion).
  if (authState == null) {
    // évalué une seule fois au démarrage, avant le premier événement auth
  }
  return ref.watch(profileRepositoryProvider).watchCurrentProfile();
});

/// Flux de l'état d'authentification — écouté par le routeur pour
/// rediriger automatiquement vers /login si la session expire.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseService.authStateChanges;
});

/// Utilisateur actuellement connecté (ou null).
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  return authState?.session?.user ?? SupabaseService.currentUser;
});
