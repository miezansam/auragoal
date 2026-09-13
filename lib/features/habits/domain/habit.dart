enum HabitFrequency { daily, specificDays, weekly }

class Habit {
  Habit({
    required this.id,
    required this.userId,
    required this.title,
    this.goalId,
    this.frequency = HabitFrequency.daily,
    this.daysOfWeek = const [],
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.isActive = true,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String? goalId;
  final HabitFrequency frequency;
  final List<int> daysOfWeek; // 0=dimanche ... 6=samedi
  final int currentStreak;
  final int longestStreak;
  final bool isActive;
  final DateTime createdAt;

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      goalId: map['goal_id'] as String?,
      frequency: _matchFrequency(map['frequency'] as String? ?? 'daily'),
      daysOfWeek: (map['days_of_week'] as List<dynamic>?)?.cast<int>() ?? [],
      currentStreak: map['current_streak'] as int? ?? 0,
      longestStreak: map['longest_streak'] as int? ?? 0,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static HabitFrequency _matchFrequency(String value) {
    switch (value) {
      case 'specific_days':
        return HabitFrequency.specificDays;
      case 'weekly':
        return HabitFrequency.weekly;
      default:
        return HabitFrequency.daily;
    }
  }

  static String _dbValueFor(HabitFrequency frequency) => switch (frequency) {
        HabitFrequency.daily => 'daily',
        HabitFrequency.specificDays => 'specific_days',
        HabitFrequency.weekly => 'weekly',
      };

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'title': title,
      'goal_id': goalId,
      'frequency': _dbValueFor(frequency),
      'days_of_week': daysOfWeek,
    };
  }
}
