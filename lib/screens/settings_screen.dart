import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:app_settings/app_settings.dart';
import '../core/theme.dart';
import '../providers/task_provider.dart';
import '../data/database_helper.dart';
import '../services/notification_service.dart';
import '../services/backup_service.dart';
import '../services/json_storage_service.dart';

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
                    subtitle: 'Version 1.0.0',
                    onTap: () => _showAboutDialog(context),
                  ),
                  _SettingsTile(
                    icon: Icons.star_outline,
                    title: 'Ad-Free Upgrade',
                    subtitle: 'Coming soon',
                    locked: true,
                    onTap: () {},
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
              final db = DatabaseHelper.instance;
              final allTasks = await db.getAllTasks();
              for (final task in allTasks) {
                if (task.id != null) {
                  await db.deleteTask(task.id!);
                }
              }
              await JsonStorageService().clearJson();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                Provider.of<TaskProvider>(context, listen: false).loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('All data cleared', style: GoogleFonts.dmSans()),
                    backgroundColor: AppTheme.surface,
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
                  SnackBar(
                    content: Text('Streak reset to 0', style: GoogleFonts.dmSans()),
                    backgroundColor: AppTheme.surface,
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
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Daily reminder set for $formattedTime',
                  style: GoogleFonts.dmSans(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.accent,
          behavior: SnackBarBehavior.floating,
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
          SnackBar(
            content: Text('Data exported successfully!', style: GoogleFonts.dmSans()),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e', style: GoogleFonts.dmSans()),
            backgroundColor: Colors.red,
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
        
        messenger.showSnackBar(
          SnackBar(
            content: Text('Data imported successfully!', style: GoogleFonts.dmSans()),
            backgroundColor: AppTheme.success,
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: Invalid file format', style: GoogleFonts.dmSans()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e', style: GoogleFonts.dmSans()),
            backgroundColor: Colors.red,
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
            Text(
              'Full policy: https://sai-vardhan-portfolio.vercel.app/mita-privacy.html',
              style: GoogleFonts.dmSans(
                color: AppTheme.accent,
                fontSize: 14,
                decoration: TextDecoration.underline,
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
              'Version 1.0.0',
              style: GoogleFonts.dmSans(color: AppTheme.mutedText),
            ),
            const SizedBox(height: 8),
            Text(
              'Focus on what matters.\nThree tasks. One day.',
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Made with ❤️',
              style: GoogleFonts.dmSans(color: AppTheme.mutedText, fontSize: 14),
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