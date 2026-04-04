import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budget_tracker_mobile/features/gam3as/application/gam3as_provider.dart';
import 'package:budget_tracker_mobile/features/gam3as/data/gam3a_repository.dart';
import 'package:budget_tracker_mobile/features/gam3as/domain/gam3a.dart';
import 'package:budget_tracker_mobile/features/gam3as/presentation/widgets/gam3a_card.dart';

class MockGam3aRepository extends Mock implements Gam3aRepository {}

final _seedGam3a = Gam3a(
  id: 1,
  name: 'Family Gam3a',
  totalPotPiastres: 8000000,
  monthlyContributionPiastres: 1000000,
  payoutMonth: 5,
  startMonth: 3,
  endMonth: 8,
  payoutReceived: false,
  active: true,
  createdAt: DateTime(2026, 1, 15),
);

Widget _wrap(Widget child, {MockGam3aRepository? mockRepo}) {
  final repo = mockRepo ?? MockGam3aRepository();
  when(() => repo.fetchAll()).thenAnswer((_) async => [_seedGam3a]);
  return ProviderScope(
    overrides: [gam3aRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_seedGam3a);
  });

  testWidgets('1. normal card shows name, formatted pot, contribution, month name', (tester) async {
    await tester.pumpWidget(_wrap(Gam3aCard(gam3a: _seedGam3a)));
    await tester.pump();

    expect(find.text('Family Gam3a'), findsOneWidget);
    expect(find.textContaining('80,000.00'), findsOneWidget);
    expect(find.textContaining('10,000.00'), findsOneWidget);
    expect(find.textContaining('May'), findsOneWidget);
  });

  testWidgets('2. payout badge visible when payoutReceived: true', (tester) async {
    final gam3aWithPayout = Gam3a(
      id: 2,
      name: 'Payout Gam3a',
      totalPotPiastres: 5000000,
      monthlyContributionPiastres: 500000,
      payoutMonth: 3,
      startMonth: 1,
      endMonth: 6,
      payoutReceived: true,
      active: true,
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(_wrap(Gam3aCard(gam3a: gam3aWithPayout)));
    await tester.pump();

    expect(find.text('Received'), findsOneWidget);
  });

  testWidgets('3. edit icon is present', (tester) async {
    await tester.pumpWidget(_wrap(Gam3aCard(gam3a: _seedGam3a)));
    await tester.pump();

    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
  });

  testWidgets('4. delete icon is present', (tester) async {
    await tester.pumpWidget(_wrap(Gam3aCard(gam3a: _seedGam3a)));
    await tester.pump();

    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('5. zero monetary values — no RenderFlex overflow', (tester) async {
    final zeroGam3a = Gam3a(
      id: 3,
      name: 'Zero Gam3a',
      totalPotPiastres: 0,
      monthlyContributionPiastres: 0,
      payoutMonth: 1,
      startMonth: 1,
      endMonth: 1,
      payoutReceived: false,
      active: true,
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(_wrap(Gam3aCard(gam3a: zeroGam3a)));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Zero Gam3a'), findsOneWidget);
  });
}
