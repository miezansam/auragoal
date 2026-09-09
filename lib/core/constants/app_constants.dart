/// Constantes générales de l'application AURAGOAL.
class AppConstants {
  AppConstants._();

  static const String appName = 'AURAGOAL';

  // Gamification
  static const int xpPerHabitCompletion = 10;
  static const int xpPerGoalMilestone = 50;
  static const int maxPriorityRecommendations = 3; // cf. cahier des charges §8

  // AURA
  static const int auraMaxContextGoals = 10;
  static const List<String> auraAllowedActions = [
    'CREATE_GOAL',
    'UPDATE_GOAL',
    'CREATE_SUBGOAL',
    'CREATE_HABIT',
    'UPDATE_HABIT',
    'CREATE_TASK',
    'CREATE_FOCUS_SESSION',
    'ARCHIVE_GOAL',
    'CHANGE_DEADLINE',
    'UPDATE_PRIORITY',
  ];
}
