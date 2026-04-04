import 'package:flutter/foundation.dart';

@immutable
class Gam3a {
  const Gam3a({
    required this.id,
    required this.name,
    required this.totalPotPiastres,
    required this.monthlyContributionPiastres,
    required this.payoutMonth,
    required this.startMonth,
    required this.endMonth,
    required this.payoutReceived,
    required this.active,
    required this.createdAt,
  });

  final int id;
  final String name;
  final int totalPotPiastres;
  final int monthlyContributionPiastres;
  final int payoutMonth;
  final int startMonth;
  final int endMonth;
  final bool payoutReceived;
  final bool active;
  final DateTime createdAt;

  static int _toPiastres(dynamic v) => ((v as num).toDouble() * 100).round();

  factory Gam3a.fromJson(Map<String, dynamic> json) {
    return Gam3a(
      id: json['id'] as int,
      name: json['name'] as String,
      totalPotPiastres: _toPiastres(json['total_pot']),
      monthlyContributionPiastres: _toPiastres(json['monthly_contribution']),
      payoutMonth: json['payout_month'] as int,
      startMonth: json['start_month'] as int,
      endMonth: json['end_month'] as int,
      payoutReceived: json['payout_received'] as bool,
      active: json['active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// toJson is used for POST/PUT request bodies — omits id, active, createdAt
  Map<String, dynamic> toJson() => {
    'name': name,
    'total_pot': totalPotPiastres / 100,
    'monthly_contribution': monthlyContributionPiastres / 100,
    'payout_month': payoutMonth,
    'start_month': startMonth,
    'end_month': endMonth,
    'payout_received': payoutReceived,
  };
}
