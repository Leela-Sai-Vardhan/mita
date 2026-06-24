import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/task_provider.dart';
import '../providers/stats_provider.dart';
import '../widgets/stats/overview_tab.dart';
import '../widgets/stats/focus_tab.dart';
import '../widgets/stats/tasks_tab.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _showWeeklySummary = false;

  @override
  void initState() {
    super.initState();
    _checkWeeklySummary();
  }

  Future<void> _checkWeeklySummary() async {
    final provider = context.read<TaskProvider>();
    final shouldShow = provider.shouldShowWeeklySummary();
    final alreadyShown = await provider.hasWeeklySummaryBeenShown();
    if (mounted) {
      setState(() {
        _showWeeklySummary = shouldShow && !alreadyShown;
      });
    }
  }

  void _dismissWeeklySummary() async {
    final provider = context.read<TaskProvider>();
    await provider.markWeeklySummaryShown();
    if (mounted) {
      setState(() {
        _showWeeklySummary = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StatsProvider()..loadStats(),
      child: Builder(
        builder: (context) {
          final statsProvider = context.watch<StatsProvider>();
          final taskProvider = context.watch<TaskProvider>();

          return SafeArea(
            child: DefaultTabController(
              length: 3,
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          Text(
                            'Stats',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          if (taskProvider.shouldShowWeeklySummary())
                            IconButton(
                              icon: const Icon(Icons.refresh,
                                  color: AppTheme.mutedText, size: 20),
                              onPressed: () =>
                                  setState(() => _showWeeklySummary = true),
                              tooltip: 'Show weekly summary',
                            ),
                        ],
                      ),
                    ),
                    TabBar(
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Focus'),
                        Tab(text: 'Tasks'),
                      ],
                      indicatorColor: AppTheme.accent,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppTheme.mutedText,
                      labelStyle: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 13),
                      indicatorSize: TabBarIndicatorSize.tab,
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          OverviewTab(
                            taskProvider: taskProvider,
                            statsProvider: statsProvider,
                            showWeeklySummary: _showWeeklySummary,
                            onDismissWeeklySummary: _dismissWeeklySummary,
                          ),
                          FocusTab(statsProvider: statsProvider),
                          TasksTab(statsProvider: statsProvider),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
