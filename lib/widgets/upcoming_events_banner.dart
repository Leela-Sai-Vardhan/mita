import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../services/remote_config_service.dart';

/// Compact, dismissible banner showing the next upcoming event from the
/// Vercel remote config. It is purely additive: when there are no future
/// events (or the user dismissed it), nothing is rendered.
class UpcomingEventsBanner extends StatefulWidget {
  const UpcomingEventsBanner({super.key});

  @override
  State<UpcomingEventsBanner> createState() => _UpcomingEventsBannerState();
}

class _UpcomingEventsBannerState extends State<UpcomingEventsBanner> {
  static const _dismissPrefix = 'upcoming_event_dismissed_';

  Map<String, dynamic>? _nextEvent;

  @override
  void initState() {
    super.initState();
    _resolveEvent();
  }

  Future<void> _resolveEvent() async {
    final rc = RemoteConfigService.instance;
    final now = DateTime.now();

    final sorted = (rc.upcomingEvents
            .where((e) {
              final date = _parseDate(e['date']);
              return date != null &&
                  !date.isBefore(DateTime(now.year, now.month, now.day));
            })
            .toList()
          ..sort((a, b) =>
              _parseDate(a['date'])!.compareTo(_parseDate(b['date'])!)))
        .take(1)
        .toList();

    if (sorted.isEmpty) {
      if (mounted) setState(() => _nextEvent = null);
      return;
    }

    final event = sorted.first;
    final id = event['id'] as String? ?? event['title'] as String? ?? '';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('$_dismissPrefix$id') ?? false) {
      if (mounted) setState(() => _nextEvent = null);
      return;
    }

    if (mounted) setState(() => _nextEvent = event);
  }

  DateTime? _parseDate(dynamic v) {
    if (v is! String) return null;
    return DateTime.tryParse(v);
  }

  String _relativeLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 7) return 'In $diff days';
    return DateFormat('d MMM').format(date);
  }

  Future<void> _dismiss() async {
    final event = _nextEvent;
    if (event == null) return;
    final id = event['id'] as String? ?? event['title'] as String? ?? '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_dismissPrefix$id', true);
    if (mounted) setState(() => _nextEvent = null);
  }

  @override
  Widget build(BuildContext context) {
    final event = _nextEvent;
    if (event == null) return const SizedBox.shrink();

    final title = event['title'] as String? ?? 'Upcoming';
    final message = event['message'] as String? ?? '';
    final date = _parseDate(event['date']);
    final label = date == null ? '' : _relativeLabel(date);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.accent.withValues(alpha: 0.18),
              AppTheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_available_outlined,
                color: AppTheme.accent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (message.isNotEmpty)
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppTheme.mutedText,
                      ),
                    ),
                ],
              ),
            ),
            if (label.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accent,
                  ),
                ),
              ),
            GestureDetector(
              onTap: _dismiss,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close, size: 16, color: AppTheme.mutedText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
