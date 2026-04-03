import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.valueInPiastres,
    this.isBasisPoints = false,
  });

  final String label;
  final int valueInPiastres;
  final bool isBasisPoints;

  static final NumberFormat _currencyFormat = NumberFormat('#,##0.00');

  String _formattedValue() {
    if (isBasisPoints) {
      return '${(valueInPiastres / 100).toStringAsFixed(2)}%';
    }
    return 'EGP ${_currencyFormat.format(valueInPiastres / 100)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formattedValue(),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
