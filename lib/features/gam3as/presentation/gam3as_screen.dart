import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class Gam3asScreen extends StatelessWidget {
  const Gam3asScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Gam3as - Coming in Phase F2',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
