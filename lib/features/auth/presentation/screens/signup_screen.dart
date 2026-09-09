import 'package:flutter/material.dart';

/// Écran placeholder — à implémenter (voir cahier des charges AURAGOAL).
class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscription')),
      body: const Center(
        child: Text('Inscription — à implémenter'),
      ),
    );
  }
}
