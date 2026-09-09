import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/goals/presentation/screens/goals_list_screen.dart';
import '../../features/goals/presentation/screens/goal_detail_screen.dart';
import '../../features/habits/presentation/screens/habits_list_screen.dart';
import '../../features/journal/presentation/screens/journal_screen.dart';
import '../../features/aura/presentation/screens/aura_chat_screen.dart';
import '../../features/focus/presentation/screens/focus_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../shared/widgets/root_shell.dart';

/// Chemins nommés — centralisés pour éviter les strings éparpillées.
class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const signup = '/signup';
  static const onboarding = '/onboarding';
  static const dashboard = '/dashboard';
  static const goals = '/goals';
  static const goalDetail = '/goals/:goalId';
  static const habits = '/habits';
  static const journal = '/journal';
  static const aura = '/aura';
  static const focus = '/focus';
  static const profile = '/profile';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Shell avec navigation basse (Dashboard / Aura / Habitudes / Objectifs / Journal / Profil)
      ShellRoute(
        builder: (context, state, child) => RootShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.goals,
            builder: (context, state) => const GoalsListScreen(),
            routes: [
              GoRoute(
                path: ':goalId',
                builder: (context, state) => GoalDetailScreen(
                  goalId: state.pathParameters['goalId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.habits,
            builder: (context, state) => const HabitsListScreen(),
          ),
          GoRoute(
            path: AppRoutes.journal,
            builder: (context, state) => const JournalScreen(),
          ),
          GoRoute(
            path: AppRoutes.aura,
            builder: (context, state) => const AuraChatScreen(),
          ),
          GoRoute(
            path: AppRoutes.focus,
            builder: (context, state) => const FocusScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
