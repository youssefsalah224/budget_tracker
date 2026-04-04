import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../application/gam3as_provider.dart';
import '../../domain/gam3a.dart';

class Gam3aCard extends ConsumerWidget {
  const Gam3aCard({super.key, required this.gam3a});
  final Gam3a gam3a;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');
    final totalPotEgp = gam3a.totalPotPiastres / 100;
    final monthlyEgp = gam3a.monthlyContributionPiastres / 100;
    final payoutMonthName = DateFormat('MMMM').format(DateTime(2026, gam3a.payoutMonth));

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    gam3a.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (gam3a.payoutReceived)
                  const Chip(
                    label: Text(
                      'Received',
                      style: TextStyle(
                        color: AppColors.background,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: AppColors.payout,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Total Pot: EGP ${currencyFormat.format(totalPotEgp)}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            Text(
              'Monthly: EGP ${currencyFormat.format(monthlyEgp)}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            Text(
              'Payout: $payoutMonthName',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            Text(
              'Range: Month ${gam3a.startMonth} \u2013 ${gam3a.endMonth}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.blue,
                  ),
                  onPressed: () => context.push('/gam3as/edit', extra: gam3a),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.negative,
                  ),
                  onPressed: () => _confirmDelete(context, ref),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Gam3a?'),
        content: Text('Remove "${gam3a.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.negative,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(gamAasNotifierProvider.notifier).delete(gam3a.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }
}
