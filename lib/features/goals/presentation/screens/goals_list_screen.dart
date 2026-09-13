import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/goal.dart';
import '../goals_providers.dart';
import '../widgets/create_goal_sheet.dart';
import '../widgets/goal_card.dart';

class GoalsListScreen extends ConsumerStatefulWidget {
  const GoalsListScreen({super.key});

  @override
  ConsumerState<GoalsListScreen> createState() => _GoalsListScreenState();
}

class _GoalsListScreenState extends ConsumerState<GoalsListScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Goal> _filterGoals(List<Goal> goals, int tabIndex) {
    switch (tabIndex) {
      case 0:
        return goals.where((g) => g.status == GoalStatus.active || g.status == GoalStatus.overdue).toList();
      case 1:
        return goals.where((g) => g.status == GoalStatus.completed).toList();
      case 2:
        return goals.where((g) => g.status == GoalStatus.archived).toList();
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Objectifs'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Actifs'),
            Tab(text: 'Terminés'),
            Tab(text: 'Archivés'),
          ],
        ),
      ),
      body: goalsAsync.when(
        data: (goals) {
          return TabBarView(
            controller: _tabController,
            children: List.generate(3, (index) {
              final filtered = _filterGoals(goals, index);
              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    index == 0 ? 'Aucun objectif actif — crée le premier !' : 'Rien ici pour le moment.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final goal = filtered[i];
                  return GoalCard(
                    goal: goal,
                    onTap: () => context.push('/goals/${goal.id}'),
                  );
                },
              );
            }),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur : $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCreateGoalSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
