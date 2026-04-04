import 'package:flutter_test/flutter_test.dart';
import 'package:budget_tracker_mobile/features/gam3as/domain/gam3a.dart';

void main() {
  const sampleJson = {
    'id': 3,
    'name': 'Family Gam3a',
    'total_pot': 80000.0,
    'monthly_contribution': 10000.0,
    'payout_month': 5,
    'start_month': 3,
    'end_month': 8,
    'payout_received': false,
    'active': true,
    'created_at': '2026-01-15T10:30:00.000Z',
  };

  group('Gam3a.fromJson', () {
    test('1. converts total_pot: 80000.0 to totalPotPiastres: 8000000', () {
      final g = Gam3a.fromJson(sampleJson);
      expect(g.totalPotPiastres, 8000000);
    });

    test(
      '2. converts monthly_contribution: 10000.0 to monthlyContributionPiastres: 1000000',
      () {
        final g = Gam3a.fromJson(sampleJson);
        expect(g.monthlyContributionPiastres, 1000000);
      },
    );

    test('3. parses all required fields correctly', () {
      final g = Gam3a.fromJson(sampleJson);
      expect(g.id, 3);
      expect(g.name, 'Family Gam3a');
      expect(g.payoutMonth, 5);
      expect(g.startMonth, 3);
      expect(g.endMonth, 8);
      expect(g.payoutReceived, false);
      expect(g.active, true);
      expect(g.createdAt, DateTime.parse('2026-01-15T10:30:00.000Z'));
    });

    test('4. payoutReceived: true round-trips correctly', () {
      final json = {...sampleJson, 'payout_received': true};
      final g = Gam3a.fromJson(json);
      expect(g.payoutReceived, true);
    });
  });

  group('Gam3a.toJson', () {
    test(
      '5. emits total_pot as double (piastres / 100) and omits id, active, created_at',
      () {
        final g = Gam3a.fromJson(sampleJson);
        final json = g.toJson();
        expect(json['total_pot'], 80000.0);
        expect(json['monthly_contribution'], 10000.0);
        expect(json.containsKey('id'), false);
        expect(json.containsKey('active'), false);
        expect(json.containsKey('created_at'), false);
      },
    );

    test('6. fromJson -> toJson -> fromJson gives equivalent Gam3a', () {
      final g1 = Gam3a.fromJson(sampleJson);
      final json2 = {
        ...g1.toJson(),
        'id': g1.id,
        'active': g1.active,
        'created_at': g1.createdAt.toIso8601String(),
      };
      final g2 = Gam3a.fromJson(json2);
      expect(g2.id, g1.id);
      expect(g2.name, g1.name);
      expect(g2.totalPotPiastres, g1.totalPotPiastres);
      expect(g2.monthlyContributionPiastres, g1.monthlyContributionPiastres);
      expect(g2.payoutMonth, g1.payoutMonth);
      expect(g2.startMonth, g1.startMonth);
      expect(g2.endMonth, g1.endMonth);
      expect(g2.payoutReceived, g1.payoutReceived);
      expect(g2.active, g1.active);
    });
  });
}
