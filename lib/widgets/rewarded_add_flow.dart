import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../providers/task_provider.dart';
import '../services/ad_service.dart';

/// Adds a routine / non-negotiable as today's task through the same rules
/// as the Home screen's add flow:
///
/// - Fewer than 3 tasks today -> a regular core slot, added directly.
/// - 3 or more tasks (extension territory) -> the rewarded-ad gate: the
///   task is added (as an extended task, consuming an extension slot)
///   only after the reward is earned. If ads are remotely disabled the
///   add is free so the flow never dead-ends.
///
/// Returns true when the task was added.
Future<bool> addTaskWithRewardedGate(
  BuildContext context,
  TaskProvider provider,
  String title,
) async {
  if (!provider.canAddTask) return false; // day already full (5/5)

  // Core slots (first three tasks) are free.
  if (provider.todayTasks.length < 3) {
    await provider.addTask(title);
    return true;
  }

  // Extension slots follow the Home screen's rewarded-ad flow.
  if (AdService.disabled) {
    provider.grantExtensionSlot();
    await provider.addTask(title, isExtended: true);
    return true;
  }

  if (!AdService().isRewardedReady) {
    ScaffoldMessenger.of(context).showSnackBar(
      AppTheme.customSnackBar(
        message: 'Ad not ready yet, try again in a moment',
        context: context,
        icon: Icons.info_outline,
        leftBarColor: Colors.orangeAccent,
      ),
    );
    return false;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.surface,
      content: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(width: 16),
          Text('Loading ad...', style: GoogleFonts.dmSans(color: Colors.white)),
        ],
      ),
    ),
  );

  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  // Built up front (customSnackBar is pure) so no BuildContext is touched
  // after the async ad gap.
  final successBar = AppTheme.customSnackBar(
    message: 'Extra task unlocked!',
    context: context,
    icon: Icons.check_circle_outline,
    leftBarColor: AppTheme.success,
  );
  final failureBar = AppTheme.customSnackBar(
    message: 'Ad closed before completing. Task not added.',
    context: context,
    icon: Icons.info_outline,
    leftBarColor: Colors.orangeAccent,
  );

  final earned = await AdService().showRewardedAd();
  navigator.pop();

  if (earned) {
    provider.grantExtensionSlot();
    await provider.addTask(title, isExtended: true);
  }  if (context.mounted) {
    messenger.showSnackBar(earned ? successBar : failureBar);
  }
  return earned;
}
