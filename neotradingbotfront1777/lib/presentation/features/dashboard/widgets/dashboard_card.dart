import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final String? warningMessage;

  const DashboardCard({
    required this.title,
    required this.icon,
    required this.child,
    super.key,
    this.warningMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header della Card
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AutoSizeText(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                    color: AppTheme.textColor,
                  ),
                  maxLines: 1,
                ),
              ),
              if ((warningMessage ?? '').isNotEmpty) ...[
                const SizedBox(width: 8),
                const Tooltip(
                  message: 'Avviso operativo',
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.warningColor,
                    size: 18,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          // Contenuto della Card
          child,
        ],
      ),
    );
  }
}
