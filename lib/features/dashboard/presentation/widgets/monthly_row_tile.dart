import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../simulation/domain/monthly_row.dart';

class MonthlyRowTile extends StatelessWidget {
  const MonthlyRowTile({super.key, required this.row});

  final MonthlyRow row;

  static final NumberFormat _currencyFormat = NumberFormat('#,##0.00');

  String _money(int piastres) =>
      'EGP ${_currencyFormat.format(piastres / 100)}';

  @override
  Widget build(BuildContext context) {
    final Color tileColor = row.isPayoutMonth
        ? AppColors.payout.withValues(alpha: 0.2)
        : Colors.transparent;

    return Container(
      color: tileColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  row.monthName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (row.isPayoutMonth)
                const Chip(
                  label: Text('Payout'),
                  backgroundColor: AppColors.payout,
                  labelStyle: TextStyle(color: AppColors.background),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: <Widget>[
              _MetricText(
                label: 'Inflow',
                value: _money(row.inflowPiastres),
                color: row.inflowPiastres > 0
                    ? AppColors.positive
                    : AppColors.textSecondary,
              ),
              _MetricText(
                label: 'Interest',
                value: _money(row.interestPiastres),
                color: row.interestPiastres > 0
                    ? AppColors.positive
                    : AppColors.textSecondary,
              ),
              _MetricText(
                label: 'Payments',
                value: _money(row.paymentsOutPiastres),
                color: AppColors.negative,
              ),
              _MetricText(
                label: 'Closing',
                value: _money(row.closingBalancePiastres),
                color: row.closingBalancePiastres < 0
                    ? AppColors.negative
                    : AppColors.textPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricText extends StatelessWidget {
  const _MetricText({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: '$label: ',
        style: const TextStyle(color: AppColors.textSecondary),
        children: <InlineSpan>[
          TextSpan(
            text: value,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
