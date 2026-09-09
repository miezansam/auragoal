import 'package:flutter/material.dart';

/// Écran placeholder — à implémenter (voir cahier des charges AURAGOAL).
class AuraChatScreen extends StatelessWidget {
  const AuraChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AURA')),
      body: const Center(
        child: Text('AURA — à implémenter'),
      ),
    );
  }
}
