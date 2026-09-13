import 'package:flutter/material.dart';

import '../../domain/goal.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.goal, required this.onTap});

  final Goal goal;
  final VoidCallback onTap;

  Color _priorityColor(BuildContext context) {
    switch (goal.priority) {
      case GoalPriority.high:
        return Colors.redAccent;
      case GoalPriority.medium:
        return Colors.orangeAccent;
      case GoalPriority.low:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _priorityColor(context),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      goal.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (goal.status == GoalStatus.completed)
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                ],
              ),
              if (goal.category != null) ...[
                const SizedBox(height: 4),
                Text(
                  goal.category!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (goal.progress / 100).clamp(0, 1),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${goal.progress.round()}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
