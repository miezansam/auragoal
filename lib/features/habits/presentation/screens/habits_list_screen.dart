import 'package:flutter/material.dart';

/// Écran placeholder — à implémenter (voir cahier des charges AURAGOAL).
class HabitsListScreen extends StatelessWidget {
  const HabitsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habitudes')),
      body: const Center(
        child: Text('Habitudes — à implémenter'),
      ),
    );
  }
}
