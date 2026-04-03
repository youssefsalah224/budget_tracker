import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../simulation/application/simulation_provider.dart';
import '../../simulation/domain/simulation_result.dart';
import 'widgets/kpi_card.dart';
import 'widgets/monthly_row_tile.dart';
import 'widgets/stale_data_banner.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SimulationResult> asyncResult = ref.watch(
      simulationNotifierProvider,
    );
    final bool isStale = ref.watch(isStaleProvider);

    return asyncResult.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.error_outline,
                color: AppColors.negative,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                error.toString(),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.invalidate(simulationNotifierProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (SimulationResult result) => Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: <Widget>[
            if (isStale) const SliverToBoxAdapter(child: StaleDataBanner()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    KpiCard(
                      label: 'Total Invested',
                      valueInPiastres: result.kpis.totalInvestedPiastres,
                    ),
                    KpiCard(
                      label: 'Total Interest',
                      valueInPiastres: result.kpis.totalInterestPiastres,
                    ),
                    KpiCard(
                      label: 'Total Payments',
                      valueInPiastres: result.kpis.totalPaymentsOutPiastres,
                    ),
                    KpiCard(
                      label: 'Final Balance',
                      valueInPiastres: result.kpis.finalBalancePiastres,
                    ),
                    KpiCard(
                      label: 'Yield',
                      valueInPiastres: result.kpis.effectiveYieldBps,
                      isBasisPoints: true,
                    ),
                  ],
                ),
              ),
            ),
            SliverList.builder(
              itemCount: result.rows.length,
              itemBuilder: (_, int i) => MonthlyRowTile(row: result.rows[i]),
            ),
          ],
        ),
      ),
    );
  }
}
