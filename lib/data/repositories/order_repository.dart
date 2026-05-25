import 'package:abpos/data/local/db_provider.dart';
import 'package:abpos/models/order.dart';
import 'package:abpos/models/order_product.dart';

class OrderRepository {
  Future<List<Order>> findAll() async {
    final db = await DBProvider.instance.database;
    final maps = await db.query('orders', orderBy: 'created_at DESC');
    return maps.map((map) => Order.fromMap(map)).toList();
  }

  Future<List<OrderProduct>> findProductsByOrderId(int orderId) async {
    final db = await DBProvider.instance.database;
    final maps = await db.rawQuery(
      '''
      SELECT
        op.*, 
        p.name AS product_name,
        v.name AS variant_name
      FROM order_products op
      LEFT JOIN products p ON p.id = op.product_id
      LEFT JOIN variants v ON v.id = op.variant_id
      WHERE op.order_id = ?
      ORDER BY op.id ASC
      ''',
      [orderId],
    );

    return maps.map((map) => OrderProduct.fromMap(map)).toList();
  }

  Future<int> insert(Order order) async {
    final db = await DBProvider.instance.database;
    return await db.insert('orders', order.toMap());
  }

  Future<int> insertOrderProduct(OrderProduct orderProduct, int orderId) async {
    final db = await DBProvider.instance.database;
    final data = orderProduct.toMap();
    data['order_id'] = orderId;
    return await db.insert('order_products', data);
  }

  Future<int> saveOrderWithProducts(
    Order order,
    List<OrderProduct> products,
  ) async {
    final db = await DBProvider.instance.database;
    return await db.transaction((txn) async {
      final orderId = await txn.insert('orders', order.toMap());
      for (final item in products) {
        final itemMap = item.toMap();
        itemMap['order_id'] = orderId;
        await txn.insert('order_products', itemMap);

        // Reduce stock quantity
        if (item.variantId != null) {
          await txn.rawUpdate(
            'UPDATE variants SET stock_quantity = MAX(0, stock_quantity - ?) WHERE id = ?',
            [item.quantity, item.variantId],
          );
        } else {
          await txn.rawUpdate(
            'UPDATE products SET stock_quantity = MAX(0, stock_quantity - ?) WHERE id = ?',
            [item.quantity, item.productId],
          );
        }
      }
      return orderId;
    });
  }
}
