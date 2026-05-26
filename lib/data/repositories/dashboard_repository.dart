import 'package:abpos/data/local/db_provider.dart';
import 'package:sqflite/sqflite.dart';

class DashboardTrendPoint {
  const DashboardTrendPoint({
    required this.date,
    required this.orderCount,
    required this.totalSales,
  });

  final DateTime date;
  final int orderCount;
  final double totalSales;
}

class DashboardRepository {
  Future<int> countOrders() async {
    final db = await DBProvider.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) AS count FROM orders');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<double> totalSales() async {
    final db = await DBProvider.instance.database;
    final result = await db.rawQuery(
      'SELECT IFNULL(SUM(total_price), 0) AS total FROM orders',
    );
    if (result.isEmpty || result.first['total'] == null) {
      return 0.0;
    }
    return double.tryParse(result.first['total'].toString()) ?? 0.0;
  }

  Future<double> totalProfit() async {
    final db = await DBProvider.instance.database;
    final result = await db.rawQuery(
      'SELECT IFNULL(SUM(profit), 0) AS total FROM order_products',
    );
    if (result.isEmpty || result.first['total'] == null) {
      return 0.0;
    }
    return double.tryParse(result.first['total'].toString()) ?? 0.0;
  }

  Future<double> totalExpenses() async {
    final db = await DBProvider.instance.database;
    final result = await db.rawQuery(
      "SELECT IFNULL(SUM(amount), 0) AS total FROM expanses WHERE transaction_type = 'capital'",
    );
    if (result.isEmpty || result.first['total'] == null) {
      return 0.0;
    }
    return double.tryParse(result.first['total'].toString()) ?? 0.0;
  }

  Future<int> itemsInStock() async {
    final db = await DBProvider.instance.database;
    final result = await db.rawQuery(
      'SELECT IFNULL(SUM(stock_quantity), 0) AS stock FROM products',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> countProducts() async {
    final db = await DBProvider.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) AS count FROM products');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<DashboardTrendPoint>> orderTrend({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await DBProvider.instance.database;
    final args = <Object?>[];
    final whereClause = _buildDateRangeWhereClause(
      args,
      startDate: startDate,
      endDate: endDate,
    );

    final result = await db.rawQuery('''
      SELECT
        substr(created_at, 1, 10) AS bucket,
        COUNT(*) AS order_count,
        IFNULL(SUM(total_price), 0) AS total_sales
      FROM orders
      $whereClause
      GROUP BY substr(created_at, 1, 10)
      ORDER BY substr(created_at, 1, 10) ASC
      ''', args);

    return result
        .where((row) => row['bucket'] != null)
        .map(
          (row) => DashboardTrendPoint(
            date: DateTime.parse(row['bucket'] as String),
            orderCount: (row['order_count'] as num?)?.toInt() ?? 0,
            totalSales: double.tryParse(row['total_sales'].toString()) ?? 0.0,
          ),
        )
        .toList();
  }

  Future<DateTime?> latestOrderDate() async {
    final db = await DBProvider.instance.database;
    final result = await db.rawQuery(
      'SELECT substr(created_at, 1, 10) AS latest_date FROM orders ORDER BY created_at DESC LIMIT 1',
    );
    if (result.isEmpty || result.first['latest_date'] == null) {
      return null;
    }
    return DateTime.tryParse(result.first['latest_date'].toString());
  }

  String _buildDateRangeWhereClause(
    List<Object?> args, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final where = <String>[];

    if (startDate != null) {
      final normalized = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );
      where.add('substr(created_at, 1, 10) >= ?');
      args.add(_formatSqlDate(normalized));
    }

    if (endDate != null) {
      final normalized = DateTime(endDate.year, endDate.month, endDate.day);
      where.add('substr(created_at, 1, 10) <= ?');
      args.add(_formatSqlDate(normalized));
    }

    if (where.isEmpty) {
      return '';
    }

    return 'WHERE ${where.join(' AND ')}';
  }

  String _formatSqlDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
