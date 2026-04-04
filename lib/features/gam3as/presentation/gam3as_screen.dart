import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../application/gam3as_provider.dart';
import 'widgets/gam3a_card.dart';
import 'widgets/empty_gam3as_view.dart';

class Gam3asScreen extends ConsumerWidget {
  const Gam3asScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(gamAasNotifierProvider);
    final isStale = ref.watch(isGam3asStaleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/gam3as/new'),
        child: const Icon(Icons.add),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.negative, size: 48),
              const SizedBox(height: 16),
              Text(
                e.toString(),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.invalidate(gamAasNotifierProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (list) {
          if (list.isEmpty) return const EmptyGam3asView();
          return Column(
            children: [
              if (isStale)
                MaterialBanner(
                  backgroundColor: AppColors.payout,
                  content: const Text(
                    'Showing cached data \u2014 unable to reach server',
                    style: TextStyle(color: AppColors.background),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => ref.invalidate(gamAasNotifierProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) => Gam3aCard(gam3a: list[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
