import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/arc_routines.dart';
import '../core/theme.dart';

/// Bottom sheet where the user picks their Winter Arc contract: up to
/// [ArcRoutines.maxContractSize] binary non-negotiables from the catalog.
///
/// The contract resets each season (September). Completing the contract's
/// tasks each day is what "locking in" means — the same three daily tasks
/// the app is built around.
class ArcContractSheet extends StatefulWidget {
  const ArcContractSheet({super.key, this.initialSelection});

  final List<String>? initialSelection;

  /// Shows the sheet and returns the chosen routine titles (null when
  /// dismissed without saving).
  static Future<List<String>?> show(
    BuildContext context, {
    List<String>? initialSelection,
  }) {
    return showModalBottomSheet<List<String>?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ArcContractSheet(initialSelection: initialSelection),
    );
  }

  @override
  State<ArcContractSheet> createState() => _ArcContractSheetState();
}

class _ArcContractSheetState extends State<ArcContractSheet> {
  List<String> _selected = [];
  bool get _canSave =>
      _selected.isNotEmpty && _selected.length <= ArcRoutines.maxContractSize;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSelection ?? const []);
  }

  void _toggle(String title) {
    setState(() {
      if (_selected.contains(title)) {
        _selected.remove(title);
      } else if (_selected.length < ArcRoutines.maxContractSize) {
        _selected.add(title);
      }
    });
  }

  Future<void> _save() async {
    final now = DateTime.now();
    final catalog = ArcRoutines.catalog();
    final routines =
        catalog.where((r) => _selected.contains(r.title)).toList();
    await ArcRoutines.saveContract(routines, now);
    if (mounted) Navigator.pop(context, _selected);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ArcRoutines.catalog();
    final byGoal = <String, List<ArcRoutine>>{};
    for (final r in catalog) {
      byGoal.putIfAbsent(r.goal, () => []).add(r);
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.mutedText.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Winter Arc contract',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pick up to 3 non-negotiables. Each day, completing them '
                    'counts as locked in — no zero days, never miss twice.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppTheme.mutedText,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                children: [
                  for (final goal in byGoal.keys) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Text(
                        _goalLabel(goal),
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: const Color(0xFF80D8FF),
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final routine in byGoal[goal]!)
                          _buildChip(routine),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_selected.length}/${ArcRoutines.maxContractSize} selected',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _canSave ? _save : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF80D8FF),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Lock in',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(ArcRoutine routine) {
    final selected = _selected.contains(routine.title);
    return GestureDetector(
      onTap: () => _toggle(routine.title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF80D8FF).withValues(alpha: 0.18)
              : AppTheme.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF80D8FF)
                : AppTheme.borderEmpty,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.lock : Icons.lock_outline,
              size: 14,
              color: selected
                  ? const Color(0xFF80D8FF)
                  : AppTheme.mutedText,
            ),
            const SizedBox(width: 6),
            Text(
              routine.title,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? Colors.white : AppTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _goalLabel(String goal) {
    switch (goal) {
      case 'fitness':
        return 'FITNESS';
      case 'health':
        return 'NUTRITION & HEALTH';
      case 'mindfulness':
        return 'MIND';
      case 'learning':
        return 'LEARNING';
      case 'career':
        return 'WORK';
      case 'creativity':
        return 'CREATIVITY';
      case 'relationships':
        return 'RELATIONSHIPS';
      default:
        return goal.toUpperCase();
    }
  }
}
