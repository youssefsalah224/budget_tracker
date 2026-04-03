import 'package:flutter/foundation.dart';

@immutable
class MonthlyRow {
  const MonthlyRow({
    required this.month,
    required this.monthName,
    required this.openingBalancePiastres,
    required this.inflowPiastres,
    required this.interestPiastres,
    required this.paymentsOutPiastres,
    required this.closingBalancePiastres,
    required this.cumulInvestedPiastres,
    required this.cumulInterestPiastres,
    required this.isPayoutMonth,
    required this.payoutGam3as,
  });

  final int month;
  final String monthName;
  final int openingBalancePiastres;
  final int inflowPiastres;
  final int interestPiastres;
  final int paymentsOutPiastres;
  final int closingBalancePiastres;
  final int cumulInvestedPiastres;
  final int cumulInterestPiastres;
  final bool isPayoutMonth;
  final List<String> payoutGam3as;

  static int _toPiastres(dynamic v) => ((v as num).toDouble() * 100).round();

  factory MonthlyRow.fromJson(Map<String, dynamic> json) {
    return MonthlyRow(
      month: json['month'] as int,
      monthName: json['month_name'] as String,
      openingBalancePiastres: _toPiastres(json['opening_balance']),
      inflowPiastres: _toPiastres(json['inflow']),
      interestPiastres: _toPiastres(json['interest']),
      paymentsOutPiastres: _toPiastres(json['payments_out']),
      closingBalancePiastres: _toPiastres(json['closing_balance']),
      cumulInvestedPiastres: _toPiastres(json['cumul_invested']),
      cumulInterestPiastres: _toPiastres(json['cumul_interest']),
      isPayoutMonth: json['is_payout_month'] as bool,
      payoutGam3as: List<String>.from(json['payout_gam3as'] as List<dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'month': month,
      'month_name': monthName,
      'opening_balance': openingBalancePiastres / 100,
      'inflow': inflowPiastres / 100,
      'interest': interestPiastres / 100,
      'payments_out': paymentsOutPiastres / 100,
      'closing_balance': closingBalancePiastres / 100,
      'cumul_invested': cumulInvestedPiastres / 100,
      'cumul_interest': cumulInterestPiastres / 100,
      'is_payout_month': isPayoutMonth,
      'payout_gam3as': payoutGam3as,
    };
  }
}
