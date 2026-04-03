import 'package:budget_tracker_mobile/features/simulation/domain/monthly_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> buildJson({
    int month = 1,
    String monthName = 'January',
    double opening = 0,
    double inflow = 0,
    double interest = 0,
    double payments = 0,
    double closing = 0,
    double cumulInvested = 0,
    double cumulInterest = 0,
    bool payout = false,
    List<String> payoutGam3as = const <String>[],
  }) {
    return <String, dynamic>{
      'month': month,
      'month_name': monthName,
      'opening_balance': opening,
      'inflow': inflow,
      'interest': interest,
      'payments_out': payments,
      'closing_balance': closing,
      'cumul_invested': cumulInvested,
      'cumul_interest': cumulInterest,
      'is_payout_month': payout,
      'payout_gam3as': payoutGam3as,
    };
  }

  test('converts zero-value row to zero piastres', () {
    final MonthlyRow row = MonthlyRow.fromJson(buildJson());
    expect(row.openingBalancePiastres, 0);
    expect(row.inflowPiastres, 0);
    expect(row.interestPiastres, 0);
  });

  test('converts normal doubles to piastres', () {
    final MonthlyRow row = MonthlyRow.fromJson(
      buildJson(
        opening: 1190.0,
        inflow: 500.25,
        interest: 12.75,
        payments: 300.0,
        closing: 1403.0,
      ),
    );
    expect(row.openingBalancePiastres, 119000);
    expect(row.inflowPiastres, 50025);
    expect(row.interestPiastres, 1275);
    expect(row.paymentsOutPiastres, 30000);
    expect(row.closingBalancePiastres, 140300);
  });

  test('parses payout month with gam3as list', () {
    final MonthlyRow row = MonthlyRow.fromJson(
      buildJson(payout: true, payoutGam3as: const <String>['A', 'B']),
    );
    expect(row.isPayoutMonth, isTrue);
    expect(row.payoutGam3as, const <String>['A', 'B']);
  });

  test('toJson preserves month identity fields', () {
    final MonthlyRow row = MonthlyRow.fromJson(
      buildJson(month: 4, monthName: 'April'),
    );
    final Map<String, dynamic> json = row.toJson();
    expect(json['month'], 4);
    expect(json['month_name'], 'April');
  });

  test('toJson round-trip keeps monetary conversions', () {
    final Map<String, dynamic> source = buildJson(
      opening: 10.1,
      inflow: 20.2,
      interest: 30.3,
      payments: 40.4,
      closing: 50.5,
      cumulInvested: 60.6,
      cumulInterest: 70.7,
    );

    final MonthlyRow first = MonthlyRow.fromJson(source);
    final MonthlyRow second = MonthlyRow.fromJson(first.toJson());

    expect(second.openingBalancePiastres, first.openingBalancePiastres);
    expect(second.inflowPiastres, first.inflowPiastres);
    expect(second.interestPiastres, first.interestPiastres);
    expect(second.paymentsOutPiastres, first.paymentsOutPiastres);
    expect(second.closingBalancePiastres, first.closingBalancePiastres);
    expect(second.cumulInvestedPiastres, first.cumulInvestedPiastres);
    expect(second.cumulInterestPiastres, first.cumulInterestPiastres);
  });

  test('toJson round-trip keeps payout metadata', () {
    final MonthlyRow first = MonthlyRow.fromJson(
      buildJson(payout: true, payoutGam3as: const <String>['G1']),
    );
    final MonthlyRow second = MonthlyRow.fromJson(first.toJson());
    expect(second.isPayoutMonth, isTrue);
    expect(second.payoutGam3as, const <String>['G1']);
  });
}
