import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/global_providers.dart';
import '../../../../core/router/app_router.dart';

const _availableInterests = [
  'Santé & sport',
  'Carrière',
  'Finances',
  'Relations',
  'Apprentissage',
  'Créativité',
  'Bien-être mental',
  'Spiritualité',
];

const _coachingStyles = [
  ('gentle', 'Doux — encouragements, peu de pression'),
  ('balanced', 'Équilibré — un mélange des deux'),
  ('intense', 'Exigeant — pousse-moi à me dépasser'),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _mainGoalController = TextEditingController();

  int _currentStep = 0;
  final Set<String> _selectedInterests = {};
  double _availableTime = 30;
  String _coachingStyle = 'balanced';
  bool _isSaving = false;

  static const _totalSteps = 4;

  @override
  void dispose() {
    _pageController.dispose();
    _mainGoalController.dispose();
    super.dispose();
  }

  bool get _canGoNext {
    switch (_currentStep) {
      case 0:
        return _mainGoalController.text.trim().isNotEmpty;
      case 1:
        return _selectedInterests.isNotEmpty;
      default:
        return true;
    }
  }

  void _goNext() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(profileRepositoryProvider).completeOnboarding(
            mainGoal: _mainGoalController.text.trim(),
            interests: _selectedInterests.toList(),
            availableTimePerDay: _availableTime.round(),
            coachingStyle: _coachingStyle,
          );
      if (mounted) context.go(AppRoutes.dashboard);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Une erreur est survenue. Réessaie.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: List.generate(_totalSteps, (index) {
                  final isActive = index <= _currentStep;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _MainGoalStep(controller: _mainGoalController, onChanged: () => setState(() {})),
                  _InterestsStep(
                    selected: _selectedInterests,
                    onToggle: (interest) {
                      setState(() {
                        if (_selectedInterests.contains(interest)) {
                          _selectedInterests.remove(interest);
                        } else {
                          _selectedInterests.add(interest);
                        }
                      });
                    },
                  ),
                  _AvailableTimeStep(
                    value: _availableTime,
                    onChanged: (value) => setState(() => _availableTime = value),
                  ),
                  _CoachingStyleStep(
                    selected: _coachingStyle,
                    onSelect: (style) => setState(() => _coachingStyle = style),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: _isSaving ? null : _goBack,
                      child: const Text('Retour'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: (_canGoNext && !_isSaving) ? _goNext : null,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_currentStep == _totalSteps - 1 ? 'Terminer' : 'Suivant'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainGoalStep extends StatelessWidget {
  const _MainGoalStep({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quelle est ton ambition principale ?', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Décris-la avec tes propres mots — AURA t\'aidera à la structurer ensuite.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            maxLines: 3,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              hintText: 'Ex: Me remettre en forme, changer de carrière, apprendre l\'anglais...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterestsStep extends StatelessWidget {
  const _InterestsStep({required this.selected, required this.onToggle});

  final Set<String> selected;
  final void Function(String) onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quels domaines t\'intéressent ?', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Choisis-en un ou plusieurs.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableInterests.map((interest) {
              final isSelected = selected.contains(interest);
              return FilterChip(
                label: Text(interest),
                selected: isSelected,
                onSelected: (_) => onToggle(interest),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AvailableTimeStep extends StatelessWidget {
  const _AvailableTimeStep({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Combien de temps par jour ?', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Le temps que tu peux réalistement consacrer à tes objectifs chaque jour.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          Text(
            '${value.round()} minutes / jour',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          Slider(
            value: value,
            min: 10,
            max: 180,
            divisions: 17,
            label: '${value.round()} min',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _CoachingStyleStep extends StatelessWidget {
  const _CoachingStyleStep({required this.selected, required this.onSelect});

  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quel style de coaching préfères-tu ?', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Tu pourras changer ça plus tard dans les paramètres.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          ..._coachingStyles.map((style) {
            final (id, label) = style;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RadioListTile<String>(
                value: id,
                groupValue: selected,
                onChanged: (value) => onSelect(value!),
                title: Text(label),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
