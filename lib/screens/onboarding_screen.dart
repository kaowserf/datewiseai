import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common/brand_mark.dart';
import 'chat_screen.dart';

/// Profile questionnaire shown after tier selection, before the first chat.
/// Collects gender, age, who they're interested in, their goal, and the app
/// they use — so the coach can ground every reply in their specifics.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  Gender? _gender;
  InterestedIn? _interestedIn;
  DatingGoal? _goal;
  DatingApp? _app;
  final _ageController = TextEditingController();
  final _cityController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _ageController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  int? get _age {
    final v = int.tryParse(_ageController.text.trim());
    if (v == null || v < 18 || v > 99) return null;
    return v;
  }

  bool get _isValid =>
      _gender != null &&
      _interestedIn != null &&
      _goal != null &&
      _app != null &&
      _age != null;

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_isValid) return;
    final profile = UserProfile(
      gender: _gender!,
      age: _age!,
      interestedIn: _interestedIn!,
      goal: _goal!,
      app: _app!,
      city: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
    );
    await context.read<AppState>().completeOnboarding(profile);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tierName = context.read<AppState>().tierInfo.name;

    return Scaffold(
      appBar: AppBar(
        title: const BrandMark(),
        titleSpacing: AppSpacing.lg,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '$tierName · STEP 2 OF 2',
                    style: const TextStyle(
                      color: Color(0xFFB07E20),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text("Let's set up your profile",
                    style: theme.textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  "A few quick questions so your coach's advice actually fits "
                  "you — not generic tips.",
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.xl),

                _Question(
                  label: "I'm a…",
                  error: _submitted && _gender == null,
                  child: _Chips<Gender>(
                    values: Gender.values,
                    selected: _gender,
                    labelOf: (g) => g.label,
                    onChanged: (g) => setState(() => _gender = g),
                  ),
                ),
                _Question(
                  label: 'My age',
                  error: _submitted && _age == null,
                  errorText: 'Enter an age between 18 and 99',
                  child: SizedBox(
                    width: 160,
                    child: TextField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(hintText: 'e.g. 28'),
                    ),
                  ),
                ),
                _Question(
                  label: "I'm interested in…",
                  error: _submitted && _interestedIn == null,
                  child: _Chips<InterestedIn>(
                    values: InterestedIn.values,
                    selected: _interestedIn,
                    labelOf: (i) => i.label,
                    onChanged: (i) => setState(() => _interestedIn = i),
                  ),
                ),
                _Question(
                  label: "I'm looking for…",
                  error: _submitted && _goal == null,
                  child: _Chips<DatingGoal>(
                    values: DatingGoal.values,
                    selected: _goal,
                    labelOf: (g) => g.label,
                    onChanged: (g) => setState(() => _goal = g),
                  ),
                ),
                _Question(
                  label: 'Which app are you on?',
                  error: _submitted && _app == null,
                  child: _Chips<DatingApp>(
                    values: DatingApp.values,
                    selected: _app,
                    labelOf: (a) => a.label,
                    onChanged: (a) => setState(() => _app = a),
                  ),
                ),
                _Question(
                  label: 'City (optional)',
                  child: TextField(
                    controller: _cityController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Helps with date-spot ideas',
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text('Start coaching →'),
                    ),
                  ),
                ),
                if (_submitted && !_isValid)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      'Please answer the questions above to continue.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: const Color(0xFFD64545)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: Text(
                    'Private by design — your answers stay on your device.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({
    required this.label,
    required this.child,
    this.error = false,
    this.errorText,
  });
  final String label;
  final Widget child;
  final bool error;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          child,
          if (error)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                errorText ?? 'Please pick one',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: const Color(0xFFD64545)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chips<T> extends StatelessWidget {
  const _Chips({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });
  final List<T> values;
  final T? selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: values.map((v) {
        final isSelected = v == selected;
        return _SelectChip(
          label: labelOf(v),
          selected: isSelected,
          onTap: () => onChanged(v),
        );
      }).toList(),
    );
  }
}

class _SelectChip extends StatelessWidget {
  const _SelectChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.cardBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.text,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
