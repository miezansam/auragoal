import 'package:flutter/material.dart';

/// Écran placeholder — à implémenter (voir cahier des charges AURAGOAL).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: const Center(
        child: Text('Profil — à implémenter'),
      ),
    );
  }
}
