import 'package:budget_tracker_mobile/features/simulation/domain/simulation_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> buildRow(int month) {
    return <String, dynamic>{
      'month': month,
      'month_name': 'Month $month',
      'opening_balance': 0.0,
      'inflow': 0.0,
      'interest': 0.0,
      'payments_out': 0.0,
      'closing_balance': 0.0,
      'cumul_invested': 0.0,
      'cumul_interest': 0.0,
      'is_payout_month': false,
      'payout_gam3as': <String>[],
    };
  }

  Map<String, dynamic> buildResponse() {
    return <String, dynamic>{
      'rows': List<Map<String, dynamic>>.generate(
        12,
        (int i) => buildRow(i + 1),
      ),
      'kpis': <String, dynamic>{
        'total_invested': 119000.0,
        'total_interest': 4920.38,
        'total_payments_out': 106500.0,
        'final_balance': 17420.38,
        'effective_yield': 4.13,
      },
    };
  }

  test('parses response with 12 rows and kpis', () {
    final SimulationResult result = SimulationResult.fromJson(buildResponse());
    expect(result.rows.length, 12);
    expect(result.kpis.effectiveYieldBps, 413);
  });

  test('keeps row ordering and month values', () {
    final SimulationResult result = SimulationResult.fromJson(buildResponse());
    expect(result.rows.first.month, 1);
    expect(result.rows.last.month, 12);
  });

  test('fromJson toJson fromJson preserves equivalent data', () {
    final SimulationResult first = SimulationResult.fromJson(buildResponse());
    final SimulationResult second = SimulationResult.fromJson(first.toJson());
    expect(second.rows.length, first.rows.length);
    expect(second.kpis.totalInvestedPiastres, first.kpis.totalInvestedPiastres);
    expect(second.rows[5].monthName, first.rows[5].monthName);
  });
}
