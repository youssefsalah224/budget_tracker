import 'dart:async';

import 'package:budget_tracker_mobile/core/cache/cache_service.dart';
import 'package:budget_tracker_mobile/core/network/app_exception.dart';
import 'package:budget_tracker_mobile/features/simulation/application/simulation_provider.dart';
import 'package:budget_tracker_mobile/features/simulation/data/simulation_repository.dart';
import 'package:budget_tracker_mobile/features/simulation/domain/kpis.dart';
import 'package:budget_tracker_mobile/features/simulation/domain/monthly_row.dart';
import 'package:budget_tracker_mobile/features/simulation/domain/simulation_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSimulationRepository extends Mock implements SimulationRepository {}

class MockCacheService extends Mock implements CacheService {}

class FakeSimulationResult extends Fake implements SimulationResult {}

void main() {
  late MockSimulationRepository repo;
  late MockCacheService cache;

  SimulationResult sampleResult() {
    return const SimulationResult(
      rows: <MonthlyRow>[
        MonthlyRow(
          month: 1,
          monthName: 'January',
          openingBalancePiastres: 0,
          inflowPiastres: 0,
          interestPiastres: 0,
          paymentsOutPiastres: 0,
          closingBalancePiastres: 0,
          cumulInvestedPiastres: 0,
          cumulInterestPiastres: 0,
          isPayoutMonth: false,
          payoutGam3as: <String>[],
        ),
      ],
      kpis: Kpis(
        totalInvestedPiastres: 0,
        totalInterestPiastres: 0,
        totalPaymentsOutPiastres: 0,
        finalBalancePiastres: 0,
        effectiveYieldBps: 0,
      ),
    );
  }

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: <Override>[
        simulationRepositoryProvider.overrideWithValue(repo),
        cacheServiceProvider.overrideWithValue(cache),
      ],
    );
  }

  setUp(() {
    repo = MockSimulationRepository();
    cache = MockCacheService();
  });

  setUpAll(() {
    registerFallbackValue(FakeSimulationResult());
  });

  group('SimulationNotifier', () {
    test('starts in loading state', () async {
      final Completer<SimulationResult> completer =
          Completer<SimulationResult>();
      when(() => repo.fetchSimulation()).thenAnswer((_) => completer.future);
      when(() => cache.writeSimulation(any())).thenAnswer((_) async {});

      final ProviderContainer container = makeContainer();
      addTearDown(container.dispose);

      final ProviderSubscription<AsyncValue<SimulationResult>> sub = container
          .listen(
            simulationNotifierProvider,
            (_, __) {},
            fireImmediately: true,
          );
      addTearDown(sub.close);

      expect(sub.read(), isA<AsyncLoading<SimulationResult>>());

      completer.complete(sampleResult());
      await container.read(simulationNotifierProvider.future);
    });

    test('transitions to data on success and writes cache', () async {
      final SimulationResult result = sampleResult();
      when(() => repo.fetchSimulation()).thenAnswer((_) async => result);
      when(() => cache.writeSimulation(any())).thenAnswer((_) async {});

      final ProviderContainer container = makeContainer();
      addTearDown(container.dispose);

      final SimulationResult value = await container.read(
        simulationNotifierProvider.future,
      );
      expect(value.rows.length, 1);
      verify(() => cache.writeSimulation(result)).called(1);
      expect(
        container.read(simulationNotifierProvider),
        isA<AsyncData<SimulationResult>>(),
      );
      expect(container.read(isStaleProvider), isFalse);
    });

    test('transitions to error when no cache', () async {
      when(() => repo.fetchSimulation()).thenThrow(const NetworkError());
      when(() => cache.readSimulation()).thenAnswer((_) async => null);

      final ProviderContainer container = makeContainer();
      addTearDown(container.dispose);

      await expectLater(
        () => container.read(simulationNotifierProvider.future),
        throwsA(isA<NetworkError>()),
      );
      expect(
        container.read(simulationNotifierProvider),
        isA<AsyncError<SimulationResult>>(),
      );
      expect(container.read(isStaleProvider), isFalse);
    });

    test('returns cached data and sets isStale when fetch fails', () async {
      final SimulationResult cached = sampleResult();
      when(() => repo.fetchSimulation()).thenThrow(const TimeoutError());
      when(() => cache.readSimulation()).thenAnswer((_) async => cached);

      final ProviderContainer container = makeContainer();
      addTearDown(container.dispose);

      final SimulationResult value = await container.read(
        simulationNotifierProvider.future,
      );
      expect(value.rows.length, 1);
      expect(container.read(isStaleProvider), isTrue);
      expect(
        container.read(simulationNotifierProvider),
        isA<AsyncData<SimulationResult>>(),
      );
    });
  });
}
