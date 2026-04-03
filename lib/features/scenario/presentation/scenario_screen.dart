import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ScenarioScreen extends StatelessWidget {
  const ScenarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Scenario Simulator - Coming in Phase F4',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
