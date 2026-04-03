import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/cache/cache_service.dart';
import '../data/simulation_repository.dart';
import '../data/simulation_repository_impl.dart';
import '../domain/simulation_result.dart';

part 'simulation_provider.g.dart';

final Provider<SimulationRepository> simulationRepositoryProvider =
    Provider<SimulationRepository>((Ref ref) {
      return SimulationRepositoryImpl();
    });

final Provider<CacheService> cacheServiceProvider = Provider<CacheService>((
  Ref ref,
) {
  return CacheService();
});

final StateProvider<bool> isStaleProvider = StateProvider<bool>(
  (Ref ref) => false,
);

@riverpod
class SimulationNotifier extends _$SimulationNotifier {
  @override
  Future<SimulationResult> build() async {
    ref.read(isStaleProvider.notifier).state = false;
    final SimulationRepository repo = ref.read(simulationRepositoryProvider);
    final CacheService cache = ref.read(cacheServiceProvider);

    try {
      final SimulationResult result = await repo.fetchSimulation();
      await cache.writeSimulation(result);
      return result;
    } catch (_) {
      final SimulationResult? cached = await cache.readSimulation();
      if (cached != null) {
        ref.read(isStaleProvider.notifier).state = true;
        return cached;
      }
      rethrow;
    }
  }
}
