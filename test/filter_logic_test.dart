import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Advanced Search Filter Logic Tests', () {
    // Test data
    final testOrders = [
      {
        'id': 1,
        'name': 'SO-001',
        'customerName': 'Customer A',
        'amountTotal': 500000.0,
        'state': 'draft',
        'fuCount': 0, // Belum kirim WA
        'dateOrder': '2026-09-24',
      },
      {
        'id': 2,
        'name': 'SO-002',
        'customerName': 'Customer B',
        'amountTotal': 1500000.0,
        'state': 'sale',
        'fuCount': 2, // Sudah kirim WA
        'dateOrder': '2026-09-24',
      },
      {
        'id': 3,
        'name': 'SO-003',
        'customerName': 'Customer C',
        'amountTotal': 750000.0,
        'state': 'sale',
        'fuCount': 0, // Belum kirim WA
        'dateOrder': '2026-09-23',
      },
    ];

    test('Filter by customer name', () {
      final filtered = testOrders
          .where((order) => 
              (order['customerName'] as String).toLowerCase().contains('customer a'))
          .toList();
      expect(filtered.length, 1);
      expect(filtered.first['name'], 'SO-001');
    });

    test('Filter by SO number', () {
      final filtered = testOrders
          .where((order) => 
              (order['name'] as String).toLowerCase().contains('so-002'))
          .toList();
      expect(filtered.length, 1);
      expect(filtered.first['name'], 'SO-002');
    });

    test('Filter by price range - minimum', () {
      const minPrice = 1000000.0;
      final filtered = testOrders
          .where((order) => (order['amountTotal'] as double) >= minPrice)
          .toList();
      expect(filtered.length, 1);
      expect(filtered.first['name'], 'SO-002');
    });

    test('Filter by WA status - sent (fuCount > 0)', () {
      final filtered = testOrders
          .where((order) => (order['fuCount'] as int) > 0)
          .toList();
      expect(filtered.length, 1);
      expect(filtered.first['name'], 'SO-002');
    });

    test('Filter by WA status - not sent (fuCount == 0)', () {
      final filtered = testOrders
          .where((order) => (order['fuCount'] as int) == 0)
          .toList();
      expect(filtered.length, 2);
      expect(filtered.map((o) => o['name']).toList(), ['SO-001', 'SO-003']);
    });

    test('Filter by status - Sale', () {
      final filtered = testOrders
          .where((order) => 
              (order['state'] as String).toLowerCase() == 'sale')
          .toList();
      expect(filtered.length, 2);
      expect(filtered.map((o) => o['name']).toList(), ['SO-002', 'SO-003']);
    });

    test('Filter by status - Draft (Open)', () {
      final filtered = testOrders
          .where((order) => 
              (order['state'] as String).toLowerCase() == 'draft')
          .toList();
      expect(filtered.length, 1);
      expect(filtered.first['name'], 'SO-001');
    });

    test('Combined filter: Sale status + WA sent', () {
      final filtered = testOrders
          .where((order) {
            final isSaleStatus = (order['state'] as String).toLowerCase() == 'sale';
            final hasWASent = (order['fuCount'] as int) > 0;
            return isSaleStatus && hasWASent;
          })
          .toList();
      expect(filtered.length, 1);
      expect(filtered.first['name'], 'SO-002');
    });

    test('Combined filter: Sale status + WA not sent', () {
      final filtered = testOrders
          .where((order) {
            final isSaleStatus = (order['state'] as String).toLowerCase() == 'sale';
            final noWASent = (order['fuCount'] as int) == 0;
            return isSaleStatus && noWASent;
          })
          .toList();
      expect(filtered.length, 1);
      expect(filtered.first['name'], 'SO-003');
    });

    test('Complex filter: Sale + WA not sent + price > 500K', () {
      final filtered = testOrders
          .where((order) {
            final isSaleStatus = (order['state'] as String).toLowerCase() == 'sale';
            final noWASent = (order['fuCount'] as int) == 0;
            final priceAbove500K = (order['amountTotal'] as double) > 500000;
            return isSaleStatus && noWASent && priceAbove500K;
          })
          .toList();
      expect(filtered.length, 1);
      expect(filtered.first['name'], 'SO-003');
    });

    test('Filter with price range (min + max)', () {
      const minPrice = 600000.0;
      const maxPrice = 1000000.0;
      final filtered = testOrders
          .where((order) {
            final total = order['amountTotal'] as double;
            return total >= minPrice && total <= maxPrice;
          })
          .toList();
      expect(filtered.length, 1);
      expect(filtered.first['name'], 'SO-003');
    });
  });
}
