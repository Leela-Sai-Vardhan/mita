import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppTheme.accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppTheme.mutedText,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class StatRow extends StatelessWidget {
  final String label1;
  final String value1;
  final String label2;
  final String value2;
  final Color? value1Color;
  final Color? value2Color;

  const StatRow({
    super.key,
    required this.label1,
    required this.value1,
    required this.label2,
    required this.value2,
    this.value1Color,
    this.value2Color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(label: label1, value: value1, valueColor: value1Color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(label: label2, value: value2, valueColor: value2Color),
        ),
      ],
    );
  }
}

class RewardButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData icon;

  const RewardButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon = Icons.play_arrow,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderEmpty),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppTheme.mutedText,
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
}