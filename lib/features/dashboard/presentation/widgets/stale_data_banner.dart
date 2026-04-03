import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../simulation/application/simulation_provider.dart';

class StaleDataBanner extends ConsumerWidget {
  const StaleDataBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialBanner(
      backgroundColor: AppColors.payout,
      content: const Text(
        'Showing cached data - unable to reach server',
        style: TextStyle(color: AppColors.background),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => ref.invalidate(simulationNotifierProvider),
          child: const Text(
            'Retry',
            style: TextStyle(color: AppColors.background),
          ),
        ),
      ],
    );
  }
}
