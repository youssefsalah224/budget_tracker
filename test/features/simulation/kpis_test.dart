import 'package:budget_tracker_mobile/features/simulation/domain/kpis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> buildJson({
    double totalInvested = 119000.0,
    double totalInterest = 4920.38,
    double totalPayments = 106500.0,
    double finalBalance = 17420.38,
    double yield = 4.13,
  }) {
    return <String, dynamic>{
      'total_invested': totalInvested,
      'total_interest': totalInterest,
      'total_payments_out': totalPayments,
      'final_balance': finalBalance,
      'effective_yield': yield,
    };
  }

  test('converts all monetary values to piastres', () {
    final Kpis kpis = Kpis.fromJson(buildJson());
    expect(kpis.totalInvestedPiastres, 11900000);
    expect(kpis.totalInterestPiastres, 492038);
    expect(kpis.totalPaymentsOutPiastres, 10650000);
    expect(kpis.finalBalancePiastres, 1742038);
  });

  test('converts effective yield to basis points', () {
    final Kpis kpis = Kpis.fromJson(buildJson(yield: 4.13));
    expect(kpis.effectiveYieldBps, 413);
  });

  test('toJson emits percentage and currency as decimal values', () {
    final Kpis kpis = Kpis.fromJson(buildJson(yield: 3.5));
    final Map<String, dynamic> json = kpis.toJson();
    expect(json['total_invested'], 119000.0);
    expect(json['effective_yield'], 3.5);
  });

  test('fromJson toJson fromJson keeps equivalent values', () {
    final Kpis first = Kpis.fromJson(
      buildJson(totalInterest: 100.01, yield: 2.75),
    );
    final Kpis second = Kpis.fromJson(first.toJson());
    expect(second.totalInterestPiastres, first.totalInterestPiastres);
    expect(second.effectiveYieldBps, first.effectiveYieldBps);
    expect(second.finalBalancePiastres, first.finalBalancePiastres);
  });
}
