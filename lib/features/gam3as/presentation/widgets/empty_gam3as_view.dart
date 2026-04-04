import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class EmptyGam3asView extends StatelessWidget {
  const EmptyGam3asView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            color: AppColors.textSecondary,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Gam3as yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start by adding your first Gam3a',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/gam3as/new'),
            child: const Text('Add your first Gam3a'),
          ),
        ],
      ),
    );
  }
}
