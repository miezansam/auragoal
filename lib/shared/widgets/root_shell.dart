import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';

/// Coquille commune aux écrans principaux, avec navigation basse.
/// Correspond à l'accès rapide décrit dans le cahier des charges :
/// Tableau de bord, Aura, Habitudes, Objectifs, Journal, Profil.
class RootShell extends StatelessWidget {
  const RootShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    (route: AppRoutes.dashboard, icon: Icons.home_rounded, label: 'Accueil'),
    (route: AppRoutes.goals, icon: Icons.flag_rounded, label: 'Objectifs'),
    (route: AppRoutes.aura, icon: Icons.auto_awesome_rounded, label: 'Aura'),
    (route: AppRoutes.habits, icon: Icons.repeat_rounded, label: 'Habitudes'),
    (route: AppRoutes.journal, icon: Icons.book_rounded, label: 'Journal'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _tabs.indexWhere((t) => location.startsWith(t.route));
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => context.go(_tabs[index].route),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}
