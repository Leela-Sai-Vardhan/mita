import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../providers/task_provider.dart';
import '../data/models/task_model.dart';
import '../data/database_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/json_storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showSwipeHint = false;
  Task? _hintTask;

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final now = DateTime.now();
        final dateStr = DateFormat('EEEE, d MMM').format(now);

        return SafeArea(
          child: Column(
            children: [
              _buildTopBar(provider, dateStr, context),
              _buildProgressIndicator(provider),
              _buildDeadlineBar(provider),
              Expanded(child: _buildTaskList(provider, context)),
              _buildAddButton(provider, context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(TaskProvider provider, String dateStr, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.isPerfectDay ? 'Perfect Day ✓' : 'Today',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: provider.isPerfectDay ? AppTheme.success : AppTheme.accent,
                ),
              ),
              Text(
                dateStr,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  color: AppTheme.mutedText,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '🔥 ${provider.streak}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => _showMenuSheet(context),
                child: const Icon(Icons.menu, color: AppTheme.mutedText),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(TaskProvider provider) {
    final progress = provider.todayTasks.isEmpty 
        ? 0.0 
        : provider.completedCount / provider.todayTasks.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            provider.isPerfectDay
                ? '${provider.completedCount} of 3 complete!'
                : '${provider.completedCount} of ${provider.todayTasks.length} tasks done',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: provider.isPerfectDay ? AppTheme.success : AppTheme.mutedText,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.surface,
            valueColor: AlwaysStoppedAnimation<Color>(
              provider.isPerfectDay ? AppTheme.success : AppTheme.accent,
            ),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineBar(TaskProvider provider) {
    return Consumer<TaskProvider>(
      builder: (context, prov, child) {
        final percent = prov.timeRemainingPercent;
        final hoursLeft = prov.secondsRemainingToday ~/ 3600;
        final minutesLeft = (prov.secondsRemainingToday % 3600) ~/ 60;
        
        String timeText;
        if (hoursLeft > 0) {
          timeText = '${hoursLeft}h ${minutesLeft}m left';
        } else {
          timeText = '${minutesLeft}m left';
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: percent > 0.25 ? AppTheme.mutedText : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s deadline',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppTheme.mutedText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: percent,
                          backgroundColor: AppTheme.background,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            percent > 0.25 ? AppTheme.success : Colors.orange,
                          ),
                          minHeight: 3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  timeText,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: percent > 0.25 ? AppTheme.success : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskList(TaskProvider provider, BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: 5,
      itemBuilder: (context, index) {
        if (index < provider.todayTasks.length) {
          return _buildTaskCard(provider.todayTasks[index], provider).animate().fadeIn().slideX();
        } else {
          return _buildEmptySlot(index, context, provider);
        }
      },
    );
  }

  Widget _buildTaskCard(Task task, TaskProvider provider) {
    return Dismissible(
      key: Key('task_${task.id}'),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        if (_showSwipeHint && _hintTask?.id == task.id) return true;
        setState(() {
          _showSwipeHint = true;
          _hintTask = task;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() {
            _showSwipeHint = false;
            _hintTask = null;
          });
        });
        return true;
      },
      onDismissed: (direction) async {
        final taskTitle = task.title;
        final taskExtended = task.isExtended;
        final taskCompleted = task.isCompleted;
        final taskCompletedAt = task.completedAt;
        
        await provider.deleteTask(task);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.surface,
              content: const Text('Task deleted', style: TextStyle(color: Colors.white)),
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              action: SnackBarAction(
                label: 'UNDO',
                textColor: AppTheme.accent,
                onPressed: () async {
                  await provider.addTask(
                    taskTitle,
                    isExtended: taskExtended,
                    preCompleted: taskCompleted,
                    preCompletedAt: taskCompletedAt,
                  );
                },
              ),
            ),
          );
        }
      },
      child: GestureDetector(
        onTap: () => provider.toggleTask(task),
        onLongPress: () {
          setState(() {
            _showSwipeHint = true;
            _hintTask = task;
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() {
              _showSwipeHint = false;
              _hintTask = null;
            });
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _showSwipeHint && _hintTask?.id == task.id
                ? AppTheme.accent.withValues(alpha: 0.15)
                : (task.isCompleted 
                    ? AppTheme.doneBackground 
                    : (task.isExtended ? const Color(0xFF1E1A10) : AppTheme.surface)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _showSwipeHint && _hintTask?.id == task.id
                  ? AppTheme.accent
                  : (task.isCompleted 
                      ? AppTheme.doneBorder 
                      : (task.isExtended ? Colors.orange.withValues(alpha: 0.3) : AppTheme.borderEmpty)),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.isCompleted ? AppTheme.success : Colors.transparent,
                      border: Border.all(
                        color: task.isCompleted 
                            ? AppTheme.success 
                            : (task.isExtended ? Colors.orange : AppTheme.mutedText),
                        width: 1.5,
                      ),
                    ),
                    child: task.isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            color: task.isCompleted ? AppTheme.mutedText : Colors.white,
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (task.isExtended && !task.isCompleted)
                          const Row(
                            children: [
                              Icon(Icons.timer_outlined, size: 12, color: Colors.orange),
                              SizedBox(width: 4),
                              Text('Extended task', style: TextStyle(fontSize: 11, color: Colors.orange)),
                            ],
                          ),
                        if (task.recurrence != TaskRecurrence.none && !task.isCompleted)
                          Row(
                            children: [
                              const Icon(Icons.repeat, size: 12, color: AppTheme.accent),
                              const SizedBox(width: 4),
                              Text(
                                _getRecurrenceLabel(task.recurrence),
                                style: GoogleFonts.dmSans(fontSize: 11, color: AppTheme.accent),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              AnimatedOpacity(
                opacity: _showSwipeHint && _hintTask?.id == task.id ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back, color: Colors.white70, size: 20),
                        SizedBox(width: 8),
                        Text('Swipe to delete', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: Colors.white70, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySlot(int index, BuildContext context, TaskProvider provider) {
    final isExtendedSlot = index >= 3;
    return GestureDetector(
      onTap: () => _showAddTaskDialog(context, provider),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExtendedSlot ? Colors.orange.withValues(alpha: 0.2) : AppTheme.borderEmpty,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isExtendedSlot ? Colors.orange.withValues(alpha: 0.3) : AppTheme.borderEmpty,
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isExtendedSlot ? 'Add an extra task...' : 'What matters today?',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                color: isExtendedSlot ? Colors.orange.withValues(alpha: 0.5) : AppTheme.placeholderText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(TaskProvider provider, BuildContext context) {
    List<Widget> children = [];

    if (provider.isFullPerfectDay && provider.todayTasks.length <= 3) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.doneBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.doneBorder),
            ),
            child: Column(
              children: [
                Text(
                  '🎉 All done — great day!',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Streak extended to ${provider.streak} days',
                  style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.mutedText),
                ),
              ],
            ),
          ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
        ),
      );
    }

    if (!provider.canAddTask) {
      children.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderEmpty),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 18, color: AppTheme.mutedText),
              const SizedBox(width: 8),
              Text('Daily limit reached (5 tasks)', style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.mutedText)),
            ],
          ),
        ),
      );
    } else {
      final isExtension = provider.todayTasks.length >= 3;
      final remainingRegular = 3 - provider.todayTasks.where((t) => !t.isExtended).length;
      
      children.add(
        GestureDetector(
          onTap: () => _showAddTaskDialog(context, provider),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isExtension ? Colors.orange : AppTheme.accent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isExtension ? Icons.timer_outlined : Icons.add, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  isExtension 
                      ? 'Add Extra Task (${2 - provider.todayExtensionUsed} left)'
                      : remainingRegular > 0 ? '+ Add Task ($remainingRegular left)' : 'Add Extra Task',
                  style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  void _showAddTaskDialog(BuildContext context, TaskProvider provider) {
    final isExtension = provider.todayTasks.length >= 3;
    final controller = TextEditingController();
    TaskRecurrence selectedRecurrence = TaskRecurrence.none;
    List<int> selectedDays = [];
    bool showSpecificDays = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text(isExtension ? 'Add Extra Task' : 'New Task', style: GoogleFonts.spaceGrotesk(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isExtension) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('This task will have a deadline of end of today',
                              style: GoogleFonts.dmSans(fontSize: 13, color: Colors.orange)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: controller,
                  style: GoogleFonts.dmSans(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter task description',
                    hintStyle: GoogleFonts.dmSans(color: AppTheme.placeholderText),
                    enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.borderEmpty)),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.accent)),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Text('Repeat', style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.mutedText)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderEmpty),
                  ),
                  child: DropdownButton<TaskRecurrence>(
                    value: selectedRecurrence,
                    dropdownColor: AppTheme.surface,
                    style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
                    underline: const SizedBox(),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: TaskRecurrence.none, child: Text('No repeat')),
                      DropdownMenuItem(value: TaskRecurrence.daily, child: Text('Every day')),
                      DropdownMenuItem(value: TaskRecurrence.weekdays, child: Text('Weekdays')),
                      DropdownMenuItem(value: TaskRecurrence.weekends, child: Text('Weekends')),
                      DropdownMenuItem(value: TaskRecurrence.specificDays, child: Text('Custom')),
                    ],
                    onChanged: (v) {
                      setDialogState(() {
                        selectedRecurrence = v ?? TaskRecurrence.none;
                        showSpecificDays = v == TaskRecurrence.specificDays;
                      });
                    },
                  ),
                ),
                if (showSpecificDays) ...[
                  const SizedBox(height: 12),
                  Text('Select days', style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.mutedText)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: List.generate(7, (index) {
                      final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                      final isSelected = selectedDays.contains(index + 1);
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            if (isSelected) {
                              selectedDays.remove(index + 1);
                            } else {
                              selectedDays.add(index + 1);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.accent : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppTheme.accent : AppTheme.borderEmpty,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              dayLabels[index],
                              style: GoogleFonts.dmSans(
                                color: isSelected ? Colors.white : AppTheme.mutedText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.dmSans(color: AppTheme.mutedText)),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  provider.addTask(
                    controller.text,
                    isExtended: isExtension,
                    recurrence: selectedRecurrence,
                    recurrenceDays: selectedRecurrence == TaskRecurrence.specificDays ? selectedDays : null,
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isExtension ? Colors.orange : AppTheme.accent,
              ),
              child: Text('Add', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showMenuSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderEmpty,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _MenuOption(
              icon: Icons.clear_all,
              title: "Clear Today's Tasks",
              subtitle: 'Remove all tasks for today',
              onTap: () {
                Navigator.pop(ctx);
                _showClearTodayDialog(context);
              },
            ),
            _MenuOption(
              icon: Icons.refresh,
              title: 'Reset Streak',
              subtitle: 'Reset current and best streak',
              onTap: () {
                Navigator.pop(ctx);
                _showResetStreakDialog(context);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
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
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
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
        title: Text('Reset Streak?', style: GoogleFonts.spaceGrotesk(color: Colors.white)),
        content: Text(
          'This will reset both current and best streak to 0.',
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
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            child: Text('Reset', style: GoogleFonts.dmSans(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getRecurrenceLabel(TaskRecurrence recurrence) {
    switch (recurrence) {
      case TaskRecurrence.daily:
        return 'Daily';
      case TaskRecurrence.weekdays:
        return 'Weekdays';
      case TaskRecurrence.weekends:
        return 'Weekends';
      case TaskRecurrence.specificDays:
        return 'Custom';
      default:
        return '';
    }
  }
}

class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuOption({required this.icon, required this.title, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.accent, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
                  if (subtitle != null)
                    Text(subtitle!, style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.mutedText)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.mutedText),
          ],
        ),
      ),
    );
  }
}