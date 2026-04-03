import 'package:flutter/foundation.dart';

import 'kpis.dart';
import 'monthly_row.dart';

@immutable
class SimulationResult {
  const SimulationResult({required this.rows, required this.kpis});

  final List<MonthlyRow> rows;
  final Kpis kpis;

  factory SimulationResult.fromJson(Map<String, dynamic> json) {
    return SimulationResult(
      rows: (json['rows'] as List<dynamic>)
          .map((dynamic e) => MonthlyRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      kpis: Kpis.fromJson(json['kpis'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'rows': rows.map((MonthlyRow r) => r.toJson()).toList(),
      'kpis': kpis.toJson(),
    };
  }
}
