import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/goals.dart';

/// Bottom-sheet goal picker. Returns the selected goal keys (List<String>)
/// if the user taps Save, or null if they cancel/skip without saving.
class GoalSelectSheet {
  static Future<List<String>?> show(
    BuildContext context, {
    List<String>? initial,
    String title = 'What matters to you?',
    String subtitle = 'Pick up to 3. Mita uses these to suggest your daily tasks.',
  }) {
    return showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _GoalSelectSheetContent(
        initial: initial ?? const [],
        title: title,
        subtitle: subtitle,
      ),
    );
  }
}

class _GoalSelectSheetContent extends StatefulWidget {
  final List<String> initial;
  final String title;
  final String subtitle;

  const _GoalSelectSheetContent({
    required this.initial,
    required this.title,
    required this.subtitle,
  });

  @override
  State<_GoalSelectSheetContent> createState() => _GoalSelectSheetContentState();
}

class _GoalSelectSheetContentState extends State<_GoalSelectSheetContent> {
  late final Set<String> _selected = widget.initial.toSet();

  void _toggle(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selected.contains(key)) {
        _selected.remove(key);
      } else if (_selected.length < 3) {
        _selected.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderEmpty,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppTheme.mutedText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final goal in Goals.all)
                    _GoalChipView(
                      goal: goal,
                      isSelected: _selected.contains(goal.key),
                      onTap: () => _toggle(goal.key),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).pop(_selected.toList());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save Picks',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: const Text('Not now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalChipView extends StatelessWidget {
  final Goal goal;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalChipView({
    required this.goal,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accent.withValues(alpha: 0.15)
              : AppTheme.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.accent : AppTheme.borderEmpty,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              goal.icon,
              size: 18,
              color: isSelected ? AppTheme.accent : AppTheme.mutedText,
            ),
            const SizedBox(width: 8),
            Text(
              goal.label,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}