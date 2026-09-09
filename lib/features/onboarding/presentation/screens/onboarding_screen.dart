import 'package:flutter/material.dart';

/// Écran placeholder — à implémenter (voir cahier des charges AURAGOAL).
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bienvenue sur AURAGOAL')),
      body: const Center(
        child: Text('Bienvenue sur AURAGOAL — à implémenter'),
      ),
    );
  }
}
