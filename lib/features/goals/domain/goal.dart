enum GoalStatus { active, completed, overdue, archived }
enum GoalPriority { low, medium, high }

class Goal {
  Goal({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.category,
    this.priority = GoalPriority.medium,
    this.status = GoalStatus.active,
    this.dueDate,
    this.progress = 0,
    this.parentGoalId,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? category;
  final GoalPriority priority;
  final GoalStatus status;
  final DateTime? dueDate;
  final double progress;
  final String? parentGoalId;
  final DateTime createdAt;

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      category: map['category'] as String?,
      priority: GoalPriority.values.firstWhere(
        (p) => p.name == map['priority'],
        orElse: () => GoalPriority.medium,
      ),
      status: GoalStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => GoalStatus.active,
      ),
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      progress: (map['progress'] as num?)?.toDouble() ?? 0,
      parentGoalId: map['parent_goal_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority.name,
      'due_date': dueDate?.toIso8601String().split('T').first,
    };
  }
}

class GoalStep {
  GoalStep({
    required this.id,
    required this.goalId,
    required this.title,
    this.isCompleted = false,
    this.orderIndex = 0,
  });

  final String id;
  final String goalId;
  final String title;
  final bool isCompleted;
  final int orderIndex;

  factory GoalStep.fromMap(Map<String, dynamic> map) {
    return GoalStep(
      id: map['id'] as String,
      goalId: map['goal_id'] as String,
      title: map['title'] as String,
      isCompleted: map['is_completed'] as bool? ?? false,
      orderIndex: map['order_index'] as int? ?? 0,
    );
  }
}
