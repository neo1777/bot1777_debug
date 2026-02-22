import 'package:flutter/material.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';

class SettingsSectionCard extends StatelessWidget {
  final List<Widget> children;

  const SettingsSectionCard({required this.children, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
