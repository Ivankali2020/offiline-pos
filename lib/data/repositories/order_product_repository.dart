import 'package:abpos/data/local/db_provider.dart';
import 'package:abpos/models/order_product.dart';

class OrderProductRepository {
  Future<List<OrderProduct>> findAll({
    DateTime? startDate,
    DateTime? endDate,
    String? search,
  }) async {
    final db = await DBProvider.instance.database;
    final args = <Object?>[];
    final where = <String>[];

    if (startDate != null) {
      final normalized = DateTime(startDate.year, startDate.month, startDate.day);
      where.add('substr(o.created_at, 1, 10) >= ?');
      args.add(_formatDate(normalized));
    }

    if (endDate != null) {
      final normalized = DateTime(endDate.year, endDate.month, endDate.day);
      where.add('substr(o.created_at, 1, 10) <= ?');
      args.add(_formatDate(normalized));
    }

    if (search != null && search.trim().isNotEmpty) {
      where.add('LOWER(p.name) LIKE ?');
      args.add('%${search.trim().toLowerCase()}%');
    }

    final whereClause = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';

    final maps = await db.rawQuery(
      '''
      SELECT
        op.*,
        p.name AS product_name,
        v.name AS variant_name
      FROM order_products op
      LEFT JOIN products p ON p.id = op.product_id
      LEFT JOIN variants v ON v.id = op.variant_id
      LEFT JOIN orders o ON o.id = op.order_id
      $whereClause
      ORDER BY o.created_at DESC
      ''',
      args,
    );

    return maps.map((map) => OrderProduct.fromMap(map)).toList();
  }

  String _formatDate(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
