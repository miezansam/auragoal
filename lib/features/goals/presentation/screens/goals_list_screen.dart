import 'package:flutter/material.dart';

/// Écran placeholder — à implémenter (voir cahier des charges AURAGOAL).
class GoalsListScreen extends StatelessWidget {
  const GoalsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Objectifs')),
      body: const Center(
        child: Text('Objectifs — à implémenter'),
      ),
    );
  }
}
