import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budget_tracker_mobile/core/network/app_exception.dart';
import 'package:budget_tracker_mobile/features/gam3as/application/gam3as_provider.dart';
import 'package:budget_tracker_mobile/features/gam3as/data/gam3a_repository.dart';
import 'package:budget_tracker_mobile/features/gam3as/domain/gam3a.dart';

class MockGam3aRepository extends Mock implements Gam3aRepository {}

final _sampleGam3a = Gam3a(
  id: 1,
  name: 'Test Gam3a',
  totalPotPiastres: 8000000,
  monthlyContributionPiastres: 1000000,
  payoutMonth: 5,
  startMonth: 1,
  endMonth: 8,
  payoutReceived: false,
  active: true,
  createdAt: DateTime(2026, 1, 15),
);

final _updatedGam3a = Gam3a(
  id: 1,
  name: 'Test Gam3a',
  totalPotPiastres: 8000000,
  monthlyContributionPiastres: 1000000,
  payoutMonth: 6,
  startMonth: 1,
  endMonth: 8,
  payoutReceived: false,
  active: true,
  createdAt: DateTime(2026, 1, 15),
);

ProviderContainer makeContainer(MockGam3aRepository mock) {
  return ProviderContainer(
    overrides: [
      gam3aRepositoryProvider.overrideWithValue(mock),
    ],
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_sampleGam3a);
  });

  group('GamAasNotifier — read states', () {
    test('1. starts as AsyncLoading', () {
      final mock = MockGam3aRepository();
      when(() => mock.fetchAll()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return [_sampleGam3a];
      });

      final container = makeContainer(mock);
      addTearDown(container.dispose);

      final state = container.read(gamAasNotifierProvider);
      expect(state, isA<AsyncLoading>());
    });

    test('2. fetchAll() success transitions to AsyncData with sorted list', () async {
      final mock = MockGam3aRepository();
      when(() => mock.fetchAll()).thenAnswer((_) async => [_sampleGam3a]);

      final container = makeContainer(mock);
      addTearDown(container.dispose);

      final state = await container.read(gamAasNotifierProvider.future);
      expect(state, [_sampleGam3a]);
    });

    test('3. fetchAll() throws and cache empty transitions to AsyncError', () async {
      final mock = MockGam3aRepository();
      when(() => mock.fetchAll()).thenThrow(const NetworkError());

      final container = makeContainer(mock);
      addTearDown(container.dispose);

      await expectLater(
        container.read(gamAasNotifierProvider.future),
        throwsA(isA<NetworkError>()),
      );

      final state = container.read(gamAasNotifierProvider);
      expect(state, isA<AsyncError>());
    });
  });

  group('GamAasNotifier — mutation states', () {
    test('5. add() success: provider state is AsyncData with updated list', () async {
      final mock = MockGam3aRepository();
      when(() => mock.fetchAll()).thenAnswer((_) async => [_sampleGam3a]);
      when(() => mock.create(any())).thenAnswer((_) async => _sampleGam3a);

      final container = makeContainer(mock);
      addTearDown(container.dispose);

      // Wait for initial load
      await container.read(gamAasNotifierProvider.future);

      // Perform add
      await container.read(gamAasNotifierProvider.notifier).add(_sampleGam3a);

      final state = container.read(gamAasNotifierProvider);
      expect(state, isA<AsyncData<List<Gam3a>>>());
      expect(state.value, [_sampleGam3a]);
    });

    test('6. add() network error: provider state is AsyncError', () async {
      final mock = MockGam3aRepository();
      when(() => mock.fetchAll()).thenAnswer((_) async => [_sampleGam3a]);
      when(() => mock.create(any())).thenThrow(const NetworkError());

      final container = makeContainer(mock);
      addTearDown(container.dispose);

      // Wait for initial load
      await container.read(gamAasNotifierProvider.future);

      // Perform add with network error
      await container.read(gamAasNotifierProvider.notifier).add(_sampleGam3a);

      final state = container.read(gamAasNotifierProvider);
      expect(state, isA<AsyncError>());
    });

    test('7. edit() success: provider state is AsyncData with updated list', () async {
      final mock = MockGam3aRepository();
      when(() => mock.fetchAll()).thenAnswer((_) async => [_updatedGam3a]);
      when(() => mock.update(any())).thenAnswer((_) async => _updatedGam3a);

      final container = makeContainer(mock);
      addTearDown(container.dispose);

      await container.read(gamAasNotifierProvider.future);

      await container.read(gamAasNotifierProvider.notifier).edit(_updatedGam3a);

      final state = container.read(gamAasNotifierProvider);
      expect(state, isA<AsyncData<List<Gam3a>>>());
      expect(state.value, [_updatedGam3a]);
    });

    test('8. edit() server error: provider state becomes AsyncError', () async {
      final mock = MockGam3aRepository();
      when(() => mock.fetchAll()).thenAnswer((_) async => [_sampleGam3a]);
      when(() => mock.update(any())).thenThrow(const ServerError(404));

      final container = makeContainer(mock);
      addTearDown(container.dispose);

      await container.read(gamAasNotifierProvider.future);

      await container.read(gamAasNotifierProvider.notifier).edit(_sampleGam3a);

      final state = container.read(gamAasNotifierProvider);
      expect(state, isA<AsyncError>());
    });

    test('9. delete() success: provider state is AsyncData with item removed', () async {
      final mock = MockGam3aRepository();
      when(() => mock.fetchAll()).thenAnswer((_) async => [_sampleGam3a]);
      when(() => mock.delete(any())).thenAnswer((_) async {});
      // After delete, fetchAll returns empty list
      var callCount = 0;
      when(() => mock.fetchAll()).thenAnswer((_) async {
        callCount++;
        return callCount == 1 ? [_sampleGam3a] : [];
      });

      final container = makeContainer(mock);
      addTearDown(container.dispose);

      await container.read(gamAasNotifierProvider.future);

      await container.read(gamAasNotifierProvider.notifier).delete(_sampleGam3a.id);

      final state = container.read(gamAasNotifierProvider);
      expect(state, isA<AsyncData<List<Gam3a>>>());
      expect(state.value, isEmpty);
    });

    test('10. delete() server error: provider state becomes AsyncError', () async {
      final mock = MockGam3aRepository();
      when(() => mock.fetchAll()).thenAnswer((_) async => [_sampleGam3a]);
      when(() => mock.delete(any())).thenThrow(const ServerError(500));

      final container = makeContainer(mock);
      addTearDown(container.dispose);

      await container.read(gamAasNotifierProvider.future);

      await container.read(gamAasNotifierProvider.notifier).delete(_sampleGam3a.id);

      final state = container.read(gamAasNotifierProvider);
      expect(state, isA<AsyncError>());
    });
  });
}
