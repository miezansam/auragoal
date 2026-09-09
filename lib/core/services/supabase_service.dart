import 'package:supabase_flutter/supabase_flutter.dart';

/// Point d'accès unique au client Supabase.
/// Toute la logique data (goals, habits, journal, xp_events...) doit passer
/// par ce client — jamais d'appel direct dispersé dans les widgets.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  static bool get isAuthenticated => currentUser != null;

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;
}
