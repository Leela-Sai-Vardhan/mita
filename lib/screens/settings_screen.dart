import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:app_settings/app_settings.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../providers/task_provider.dart';
import '../providers/pomodoro_provider.dart';
import '../data/database_helper.dart';
import '../services/notification_service.dart';
import '../services/backup_service.dart';
import '../services/json_storage_service.dart';
import '../services/rate_prompt_service.dart';
import '../services/remote_config_service.dart';
import '../services/app_update_service.dart';
import '../core/quick_picks.dart';
import '../widgets/goal_select_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Settings',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  const SizedBox(height: 8),
                  _buildSectionTitle('NOTIFICATIONS'),
                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: 'Daily Reminder',
                    subtitle: 'Set a time for daily task reminders',
                    onTap: () => _showNotificationTimeDialog(context),
                  ),
                  const _NotificationToggleTile(
                    icon: Icons.alarm,
                    title: 'Daily Reminder',
                    subtitle: 'Morning nudge at your chosen time',
                    prefKey: NotificationService.prefDaily,
                  ),
                  const _NotificationToggleTile(
                    icon: Icons.nightlight_outlined,
                    title: 'End-of-Day Check-in',
                    subtitle: 'Gentle evening nudge if tasks remain (10 PM)',
                    prefKey: NotificationService.prefEndOfDay,
                    iconColor: Colors.orangeAccent,
                  ),
                  const _NotificationToggleTile(
                    icon: Icons.summarize_outlined,
                    title: 'Weekly Summary',
                    subtitle: 'Monday progress recap',
                    prefKey: NotificationService.prefWeeklySummary,
                    iconColor: Colors.amber,
                  ),
                  const _NotificationToggleTile(
                    icon: Icons.radio_button_checked,
                    title: 'Focus Complete',
                    subtitle: 'When your focus session ends',
                    prefKey: NotificationService.prefFocus,
                    iconColor: Colors.blueAccent,
                  ),
                  _SettingsTile(
                    icon: Icons.battery_charging_full,
                    title: 'Battery Optimization',
                    subtitle: 'Ensure reliable notifications',
                    iconColor: Colors.amber,
                    onTap: () => _showBatteryOptimizationDialog(context),
                  ),
                  _SettingsTile(
                    icon: Icons.rocket_launch,
                    title: 'AutoStart (Xiaomi/Oppo)',
                    subtitle: 'Prevent system from killing Mita',
                    iconColor: Colors.blueAccent,
                    onTap: () => _showAutoStartDialog(context),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24, left: 12, right: 12, top: 4),
                    child: Text(
                      'Note: Both Battery Optimization (No Restrictions) and AutoStart must be enabled for reliable daily reminders on some devices (Xiaomi, Oppo, Vivo).',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Colors.orange.withValues(alpha: 0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('BACKUP'),
                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Icons.upload_file,
                    title: 'Export Data',
                    subtitle: 'Save your data as JSON',
                    onTap: () => _exportData(context),
                  ),
                  _SettingsTile(
                    icon: Icons.download,
                    title: 'Import Data',
                    subtitle: 'Restore from JSON backup',
                    onTap: () => _importData(context),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('PERSONALIZE'),
                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Icons.track_changes,
                    title: 'Your Goals',
                    subtitle: 'Pick up to 3 focus areas for smarter task suggestions',
                    iconColor: AppTheme.accent,
                    onTap: () => _showGoalSelectSheet(context),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('DATA'),
                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Icons.delete_outline,
                    title: 'Clear All Data',
                    subtitle: 'Delete all tasks and history',
                    iconColor: Colors.redAccent,
                    onTap: () => _showClearDataDialog(context),
                  ),
                  _SettingsTile(
                    icon: Icons.clear_all,
                    title: "Clear Today's Tasks",
                    subtitle: 'Remove all tasks for today',
                    iconColor: Colors.orangeAccent,
                    onTap: () => _showClearTodayDialog(context),
                  ),
                  _SettingsTile(
                    icon: Icons.refresh,
                    title: 'Reset Streak',
                    subtitle: 'Reset current and best streak to 0',
                    iconColor: Colors.orangeAccent,
                    onTap: () => _showResetStreakDialog(context),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('LEGAL'),
                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'View our privacy policy',
                    onTap: () => _showPrivacyPolicyDialog(context),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('ABOUT'),
                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: AppTheme.appVersion,
                    onTap: () => _showAboutDialog(context),
                  ),
                  _SettingsTile(
                    icon: Icons.favorite_outline,
                    title: 'Rate Us',
                    subtitle: 'Support a student developer',
                    iconColor: Colors.pinkAccent,
                    onTap: () => RatePromptService().show(context),
                  ),
                  _SettingsTile(
                    icon: Icons.star_outline,
                    title: 'Ad-Free Upgrade',
                    subtitle: 'Coming soon',
                    locked: true,
                    onTap: () {},
                  ),
                  const SizedBox(height: 8),
                  _buildSectionTitle('UPDATES'),
                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Icons.sync,
                    title: 'Check for Updates',
                    subtitle: 'Refresh remote config & re-theme',
                    iconColor: AppTheme.accent,
                    onTap: () => _checkForUpdates(context),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppTheme.mutedText,
        letterSpacing: 1.2,
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          'Clear All Data?',
          style: GoogleFonts.spaceGrotesk(color: Colors.white),
        ),
        content: Text(
          'This will delete all your tasks and history. This action cannot be undone.',
          style: GoogleFonts.dmSans(color: AppTheme.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: AppTheme.mutedText)),
          ),
          ElevatedButton(
            onPressed: () async {
              await Provider.of<TaskProvider>(context, listen: false).clearAllData();
              if (context.mounted) {
                await Provider.of<PomodoroProvider>(context, listen: false).clearAll();
              }
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  AppTheme.customSnackBar(
                    message: 'All data cleared',
                    context: context,
                    icon: Icons.check_circle_outline,
                    leftBarColor: AppTheme.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('Clear', style: GoogleFonts.dmSans(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showClearTodayDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text("Clear Today's Tasks?", style: GoogleFonts.spaceGrotesk(color: Colors.white)),
        content: Text(
          'This will remove all tasks for today. This cannot be undone.',
          style: GoogleFonts.dmSans(color: AppTheme.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: AppTheme.mutedText)),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<TaskProvider>(context, listen: false);
              final todayTasks = provider.todayTasks;
              for (final task in todayTasks) {
                if (task.id != null) {
                  await DatabaseHelper.instance.deleteTask(task.id!);
                }
              }
              await JsonStorageService().clearJson();
              await provider.loadData();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  AppTheme.customSnackBar(
                    message: "Today's tasks cleared",
                    context: context,
                    icon: Icons.check_circle_outline,
                    leftBarColor: AppTheme.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            child: Text('Clear', style: GoogleFonts.dmSans(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showGoalSelectSheet(BuildContext context) async {
    final current = await QuickPicks.getGoalKeys();
    if (!context.mounted) return;
    final result = await GoalSelectSheet.show(context, initial: current);
    if (result != null && context.mounted) {
      await QuickPicks.saveGoals(result);
    }
  }

  void _showResetStreakDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          'Reset Streak?',
          style: GoogleFonts.spaceGrotesk(color: Colors.white),
        ),
        content: Text(
          'This will reset both your current and best streak to 0.',
          style: GoogleFonts.dmSans(color: AppTheme.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: AppTheme.mutedText)),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<TaskProvider>(context, listen: false);
              await provider.resetStreak();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  AppTheme.customSnackBar(
                    message: 'Streak reset to 0',
                    context: context,
                    icon: Icons.refresh,
                    leftBarColor: Colors.orangeAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            child: Text('Reset', style: GoogleFonts.dmSans(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showNotificationTimeDialog(BuildContext context) async {
    final notificationService = NotificationService();
    final currentHour = notificationService.notificationHour;
    final currentMinute = notificationService.notificationMinute;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: AppTheme.surface,
              hourMinuteTextColor: Colors.white,
              dayPeriodTextColor: Colors.white,
              dialBackgroundColor: AppTheme.background,
              dialHandColor: AppTheme.accent,
              dialTextColor: Colors.white,
              entryModeIconColor: AppTheme.accent,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    await notificationService.setNotificationTime(picked.hour, picked.minute);
    if (!context.mounted) return;
    
    final formattedTime = picked.format(context);
    
    // Use a post-frame callback to ensure we're using the correct context
    Future.delayed(Duration.zero, () {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.customSnackBar(
          message: 'Daily reminder set for $formattedTime',
          context: context,
          icon: Icons.notifications_active,
          leftBarColor: AppTheme.accent,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }


  void _showBatteryOptimizationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Row(
          children: [
            const Icon(Icons.battery_charging_full, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(child: Text('Battery Optimization', style: GoogleFonts.spaceGrotesk(color: Colors.white))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To ensure you receive timely task reminders, please disable battery optimization for Mita.',
                style: GoogleFonts.dmSans(color: AppTheme.mutedText, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Without this, notifications may be delayed or not delivered.',
                        style: GoogleFonts.dmSans(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: AppTheme.mutedText)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _openBatterySettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: Text('Open Settings', style: GoogleFonts.dmSans(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _openBatterySettings() async {
    if (Platform.isAndroid) {
      try {
        await AppSettings.openAppSettings(type: AppSettingsType.batteryOptimization);
      } catch (_) {
        try {
          await AppSettings.openAppSettings();
        } catch (_) {}
      }
    }
  }

  void _showAutoStartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Row(
          children: [
            const Icon(Icons.rocket_launch, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Expanded(child: Text('AutoStart (Xiaomi/Oppo)', style: GoogleFonts.spaceGrotesk(color: Colors.white))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'On devices like Xiaomi, Oppo, and Vivo, you must enable "AutoStart" for Mita.',
                style: GoogleFonts.dmSans(color: AppTheme.mutedText, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blueAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tap below to open App Info. Look for "AutoStart" or "Background Execution" and turn it ON.',
                        style: GoogleFonts.dmSans(color: Colors.blueAccent, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: AppTheme.mutedText)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _openAutoStartSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: Text('Open App Info', style: GoogleFonts.dmSans(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _openAutoStartSettings() async {
    if (Platform.isAndroid) {
      await AppSettings.openAppSettings(type: AppSettingsType.settings);
    }
  }

  void _exportData(BuildContext context) async {
    try {
      final backupService = BackupService();
      await backupService.shareExport();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.customSnackBar(
            message: 'Data exported successfully!',
            context: context,
            icon: Icons.check_circle_outline,
            leftBarColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.customSnackBar(
            message: 'Export failed: $e',
            context: context,
            icon: Icons.error_outline,
            leftBarColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _importData(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Import Data?', style: GoogleFonts.spaceGrotesk(color: Colors.white)),
        content: Text(
          'This will replace all your current data with the backup. This cannot be undone.',
          style: GoogleFonts.dmSans(color: AppTheme.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: AppTheme.mutedText)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _performImport(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            child: Text('Import', style: GoogleFonts.dmSans(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _performImport(BuildContext context) async {
    try {
      final backupService = BackupService();
      final filePath = await backupService.pickFile();
      
      if (filePath == null) return;
      
      final success = await backupService.importData(filePath);
      
      if (success && context.mounted) {
        final provider = Provider.of<TaskProvider>(context, listen: false);
        final messenger = ScaffoldMessenger.of(context);
        await provider.loadData();
        
        if (context.mounted) {
          messenger.showSnackBar(
            AppTheme.customSnackBar(
              message: 'Data imported successfully!',
              context: context,
              icon: Icons.check_circle_outline,
              leftBarColor: AppTheme.success,
            ),
          );
        }
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.customSnackBar(
            message: 'Import failed: Invalid file format',
            context: context,
            icon: Icons.error_outline,
            leftBarColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.customSnackBar(
            message: 'Import failed: $e',
            context: context,
            icon: Icons.error_outline,
            leftBarColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.spaceGrotesk(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your privacy is important to us.',
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              'This app stores your tasks locally on your device. We do not collect or share any personal information.',
              style: GoogleFonts.dmSans(color: AppTheme.mutedText, fontSize: 14),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final uri = Uri.parse(
                  'https://sai-vardhan-portfolio.vercel.app/mita-privacy.html',
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                'Full policy: https://sai-vardhan-portfolio.vercel.app/mita-privacy.html',
                style: GoogleFonts.dmSans(
                  color: AppTheme.accent,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.dmSans(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderEmpty),
              ),
              child: Center(
                child: Text(
                  '⊙',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Mita',
              style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTheme.appVersion,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ddvardhan2@gmail.com',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppTheme.mutedText,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.dmSans(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }

  void _checkForUpdates(BuildContext context) {
    final rc = RemoteConfigService.instance;
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      AppTheme.customSnackBar(
        message: 'Checking for updates…',
        context: context,
        icon: Icons.sync,
        leftBarColor: AppTheme.accent,
        duration: const Duration(seconds: 2),
      ),
    );

    rc.refresh().then((changed) async {
      if (!context.mounted) return;
      // Prefer surfacing an app update over a generic "up to date" toast.
      final shownUpdate =
          await AppUpdateService().showIfNeeded(context);
      if (!context.mounted || shownUpdate) return;
      final msg = changed
          ? 'Updates applied ✓'
          : 'You are up to date';
      messenger.showSnackBar(
        AppTheme.customSnackBar(
          message: msg,
          context: context,
          icon: changed ? Icons.check_circle_outline : Icons.info_outline,
          leftBarColor: changed ? AppTheme.success : AppTheme.mutedText,
        ),
      );
    }).catchError((_) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        AppTheme.customSnackBar(
          message: 'Could not reach update server',
          context: context,
          icon: Icons.error_outline,
          leftBarColor: Colors.redAccent,
        ),
      );
    });
  }

}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;
  final bool locked;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.locked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: locked ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: locked ? AppTheme.background : (iconColor ?? AppTheme.accent).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                locked ? Icons.lock_outline : icon,
                color: locked ? AppTheme.mutedText : (iconColor ?? AppTheme.accent),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: locked ? AppTheme.mutedText : Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppTheme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            if (!locked)
              const Icon(Icons.chevron_right, color: AppTheme.mutedText),
          ],
        ),
      ),
    );
  }
}

class _NotificationToggleTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String prefKey;
  final Color iconColor;

  const _NotificationToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.prefKey,
    this.iconColor = AppTheme.accent,
  });

  @override
  State<_NotificationToggleTile> createState() => _NotificationToggleTileState();
}

class _NotificationToggleTileState extends State<_NotificationToggleTile> {
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await NotificationService().notificationEnabled(widget.prefKey);
    if (mounted) setState(() => _enabled = enabled);
  }

  Future<void> _toggle(bool value) async {
    setState(() => _enabled = value);
    await NotificationService().setNotificationEnabled(widget.prefKey, enabled: value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.icon, color: widget.iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _enabled ? Colors.white : AppTheme.mutedText,
                  ),
                ),
                Text(
                  widget.subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _enabled,
            onChanged: _toggle,
            activeTrackColor: AppTheme.accent,
            activeThumbColor: Colors.white,
            inactiveTrackColor: AppTheme.background,
            inactiveThumbColor: AppTheme.mutedText,
          ),
        ],
      ),
    );
  }
}