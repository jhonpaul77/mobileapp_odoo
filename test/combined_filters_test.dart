import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Combined Advanced Search + Date Filter Tests', () {
    // Test data dengan berbagai tanggal
    final testOrders = [
      {
        'id': 1,
        'name': 'SO-001',
        'customerName': 'Customer A',
        'amountTotal': 500000.0,
        'state': 'draft',
        'fuCount': 0,
        'dateOrder': DateTime(2026, 9, 24), // Today
      },
      {
        'id': 2,
        'name': 'SO-002',
        'customerName': 'Customer B',
        'amountTotal': 1500000.0,
        'state': 'sale',
        'fuCount': 2,
        'dateOrder': DateTime(2026, 9, 24), // Today
      },
      {
        'id': 3,
        'name': 'SO-003',
        'customerName': 'Customer C',
        'amountTotal': 750000.0,
        'state': 'sale',
        'fuCount': 0,
        'dateOrder': DateTime(2026, 9, 23), // Yesterday
      },
      {
        'id': 4,
        'name': 'SO-004',
        'customerName': 'Customer A Extended',
        'amountTotal': 2000000.0,
        'state': 'sale',
        'fuCount': 1,
        'dateOrder': DateTime(2026, 9, 22), // This week (Monday)
      },
    ];

    DateTime now = DateTime(2026, 9, 24); // Today adalah Wednesday (weekday 3)
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));
    // Monday of this week: Wednesday 24 - 2 days = Monday 22
    DateTime mondayOfWeek = today.subtract(Duration(days: today.weekday - 1));

    test('Date filter: Today only', () {
      final todayOrders = testOrders
          .where((order) {
            final orderDate = order['dateOrder'] as DateTime;
            final orderDay = DateTime(orderDate.year, orderDate.month, orderDate.day);
            return orderDay.isAtSameMomentAs(today);
          })
          .toList();
      expect(todayOrders.length, 2);
      expect(todayOrders.map((o) => o['name']).toList(), ['SO-001', 'SO-002']);
    });

    test('Date filter: Yesterday only', () {
      final yesterdayOrders = testOrders
          .where((order) {
            final orderDate = order['dateOrder'] as DateTime;
            final orderDay = DateTime(orderDate.year, orderDate.month, orderDate.day);
            return orderDay.isAtSameMomentAs(yesterday);
          })
          .toList();
      expect(yesterdayOrders.length, 1);
      expect(yesterdayOrders.first['name'], 'SO-003');
    });

    test('Date filter: This week', () {
      final thisWeekOrders = testOrders
          .where((order) {
            final orderDate = order['dateOrder'] as DateTime;
            final orderDay = DateTime(orderDate.year, orderDate.month, orderDate.day);
            return orderDay.isAfter(mondayOfWeek.subtract(const Duration(days: 1))) &&
                orderDay.isBefore(today.add(const Duration(days: 1)));
          })
          .toList();
      expect(thisWeekOrders.length, 4); // All orders this week
    });

    test('Combined: Today + Customer Name contains "Customer A"', () {
      final filtered = testOrders
          .where((order) {
            final orderDate = order['dateOrder'] as DateTime;
            final orderDay = DateTime(orderDate.year, orderDate.month, orderDate.day);
            final isToday = orderDay.isAtSameMomentAs(today);
            final customerMatch = (order['customerName'] as String).toLowerCase().contains('customer a');
            return isToday && customerMatch;
          })
          .toList();
      expect(filtered.length, 1);
      expect(filtered.first['name'], 'SO-001');
    });

    test('Combined: Today + Sale status', () {
      final filtered = testOrders
          .where((order) {
            final orderDate = order['dateOrder'] as DateTime;
            final orderDay = DateTime(orderDate.year, orderDate.month, orderDate.day);
            final isToday = orderDay.isAtSameMomentAs(today);
            final isSale = (order['state'] as String).toLowerCase() == 'sale';
            return isToday && isSale;
          })
          .toList();
      expect(filtered.length, 1);
      expect(filtered.first['name'], 'SO-002');
    });

    test('Combined: This week + WA sent', () {
      final filtered = testOrders
          .where((order) {
            final orderDate = order['dateOrder'] as DateTime;
            final orderDay = DateTime(orderDate.year, orderDate.month, orderDate.day);
            final isThisWeek = orderDay.isAfter(mondayOfWeek.subtract(const Duration(days: 1))) &&
                orderDay.isBefore(today.add(const Duration(days: 1)));
            final hasWA = (order['fuCount'] as int) > 0;
            return isThisWeek && hasWA;
          })
          .toList();
      expect(filtered.length, 2);
      expect(filtered.map((o) => o['name']).toList(), ['SO-002', 'SO-004']);
    });

    test('Combined: Today + Price > 1M', () {
      final filtered = testOrders
          .where((order) {
            final orderDate = order['dateOrder'] as DateTime;
            final orderDay = DateTime(orderDate.year, orderDate.month, orderDate.day);
            final isToday = orderDay.isAtSameMomentAs(today);
            final priceAbove1M = (order['amountTotal'] as double) > 1000000;
            return isToday && priceAbove1M;
          })
          .toList();
      expect(filtered.length, 1);
      expect(filtered.first['name'], 'SO-002');
    });

    test('Combined: Yesterday + Sale status + WA not sent', () {
      final filtered = testOrders
          .where((order) {
            final orderDate = order['dateOrder'] as DateTime;
            final orderDay = DateTime(orderDate.year, orderDate.month, orderDate.day);
            final isYesterday = orderDay.isAtSameMomentAs(yesterday);
            final isSale = (order['state'] as String).toLowerCase() == 'sale';
            final noWA = (order['fuCount'] as int) == 0;
            return isYesterday && isSale && noWA;
          })
          .toList();
      expect(filtered.length, 1);
      expect(filtered.first['name'], 'SO-003');
    });

    test('Complex Combined: This week + Sale + WA sent + Price > 500K', () {
      final filtered = testOrders
          .where((order) {
            final orderDate = order['dateOrder'] as DateTime;
            final orderDay = DateTime(orderDate.year, orderDate.month, orderDate.day);
            final isThisWeek = orderDay.isAfter(mondayOfWeek.subtract(const Duration(days: 1))) &&
                orderDay.isBefore(today.add(const Duration(days: 1)));
            final isSale = (order['state'] as String).toLowerCase() == 'sale';
            final hasWA = (order['fuCount'] as int) > 0;
            final priceAbove500K = (order['amountTotal'] as double) > 500000;
            return isThisWeek && isSale && hasWA && priceAbove500K;
          })
          .toList();
      expect(filtered.length, 2);
      expect(filtered.map((o) => o['name']).toList(), ['SO-002', 'SO-004']);
    });

    test('Complex Combined: This week + Customer contains "A" + Price range 500K-1.5M', () {
      const minPrice = 500000.0;
      const maxPrice = 1500000.0;
      final filtered = testOrders
          .where((order) {
            final orderDate = order['dateOrder'] as DateTime;
            final orderDay = DateTime(orderDate.year, orderDate.month, orderDate.day);
            final isThisWeek = orderDay.isAfter(mondayOfWeek.subtract(const Duration(days: 1))) &&
                orderDay.isBefore(today.add(const Duration(days: 1)));
            final customerMatch = (order['customerName'] as String).toLowerCase().contains('a');
            final priceInRange = (order['amountTotal'] as double) >= minPrice && 
                (order['amountTotal'] as double) <= maxPrice;
            return isThisWeek && customerMatch && priceInRange;
          })
          .toList();
      // SO-001 (Customer A, 500K, today) + SO-002 (Customer B, 1.5M, today) -> only SO-001 matches "a"
      // SO-004 (Customer A Extended, 2M, Monday) -> outside price range
      expect(filtered.length, 1);
      expect(filtered.first['name'], 'SO-001');
    });
  });
}
