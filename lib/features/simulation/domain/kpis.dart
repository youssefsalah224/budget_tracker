import 'package:flutter/foundation.dart';

@immutable
class Kpis {
  const Kpis({
    required this.totalInvestedPiastres,
    required this.totalInterestPiastres,
    required this.totalPaymentsOutPiastres,
    required this.finalBalancePiastres,
    required this.effectiveYieldBps,
  });

  final int totalInvestedPiastres;
  final int totalInterestPiastres;
  final int totalPaymentsOutPiastres;
  final int finalBalancePiastres;
  final int effectiveYieldBps;

  static int _toPiastres(dynamic v) => ((v as num).toDouble() * 100).round();

  factory Kpis.fromJson(Map<String, dynamic> json) {
    return Kpis(
      totalInvestedPiastres: _toPiastres(json['total_invested']),
      totalInterestPiastres: _toPiastres(json['total_interest']),
      totalPaymentsOutPiastres: _toPiastres(json['total_payments_out']),
      finalBalancePiastres: _toPiastres(json['final_balance']),
      effectiveYieldBps: _toPiastres(json['effective_yield']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'total_invested': totalInvestedPiastres / 100,
      'total_interest': totalInterestPiastres / 100,
      'total_payments_out': totalPaymentsOutPiastres / 100,
      'final_balance': finalBalancePiastres / 100,
      'effective_yield': effectiveYieldBps / 100,
    };
  }
}
