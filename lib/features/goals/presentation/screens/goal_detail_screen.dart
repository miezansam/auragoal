import 'package:flutter/material.dart';

/// Écran de détail d'un objectif — sous-objectifs, étapes, habitudes liées.
class GoalDetailScreen extends StatelessWidget {
  const GoalDetailScreen({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail de l\'objectif')),
      body: Center(
        child: Text('Objectif #$goalId — à implémenter'),
      ),
    );
  }
}
