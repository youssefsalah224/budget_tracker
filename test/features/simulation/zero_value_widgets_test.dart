import 'package:budget_tracker_mobile/features/dashboard/presentation/widgets/kpi_card.dart';
import 'package:budget_tracker_mobile/features/dashboard/presentation/widgets/monthly_row_tile.dart';
import 'package:budget_tracker_mobile/features/simulation/domain/monthly_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MonthlyRowTile renders zero values without exceptions', (
    WidgetTester tester,
  ) async {
    const MonthlyRow row = MonthlyRow(
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
    );

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox())),
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MonthlyRowTile(row: row)),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('KpiCard renders zero value without exceptions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: KpiCard(label: 'Total Invested', valueInPiastres: 0),
        ),
      ),
    );
    expect(find.textContaining('EGP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
