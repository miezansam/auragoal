import 'package:supabase_flutter/supabase_flutter.dart';

/// Modèle simple du profil — reflète la table "profiles".
class UserProfile {
  UserProfile({
    required this.id,
    this.displayName,
    this.mainGoal,
    this.interests = const [],
    this.availableTimePerDay,
    this.coachingStyle = 'balanced',
    this.level = 1,
    this.xp = 0,
    this.currentStreak = 0,
    this.onboardingCompleted = false,
  });

  final String id;
  final String? displayName;
  final String? mainGoal;
  final List<String> interests;
  final int? availableTimePerDay;
  final String coachingStyle;
  final int level;
  final int xp;
  final int currentStreak;
  final bool onboardingCompleted;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      displayName: map['display_name'] as String?,
      mainGoal: map['main_goal'] as String?,
      interests: (map['interests'] as List<dynamic>?)?.cast<String>() ?? [],
      availableTimePerDay: map['available_time_per_day'] as int?,
      coachingStyle: map['coaching_style'] as String? ?? 'balanced',
      level: map['level'] as int? ?? 1,
      xp: map['xp'] as int? ?? 0,
      currentStreak: map['current_streak'] as int? ?? 0,
      onboardingCompleted: map['onboarding_completed'] as bool? ?? false,
    );
  }
}

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Stream<UserProfile?> watchCurrentProfile() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value(null);

    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((rows) => rows.isEmpty ? null : UserProfile.fromMap(rows.first));
  }

  Future<UserProfile?> fetchCurrentProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final row = await _client.from('profiles').select().eq('id', userId).maybeSingle();
    return row == null ? null : UserProfile.fromMap(row);
  }

  Future<void> completeOnboarding({
    required String mainGoal,
    required List<String> interests,
    required int availableTimePerDay,
    required String coachingStyle,
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('profiles').update({
      'main_goal': mainGoal,
      'interests': interests,
      'available_time_per_day': availableTimePerDay,
      'coaching_style': coachingStyle,
      'onboarding_completed': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }
}
