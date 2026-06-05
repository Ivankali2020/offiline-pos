import 'package:abpos/data/local/db_provider.dart';
import 'package:abpos/models/order_return.dart';
import 'package:abpos/models/order_return_product.dart';


class OrderReturnRepository {
  Future<List<OrderReturn>> getOrderReturns() async {
    final db = await DBProvider.instance.database;
    final results = await db.rawQuery('''
      SELECT or_ret.*, o.invoice_number as original_invoice_number
      FROM order_returns or_ret
      LEFT JOIN orders o ON or_ret.order_id = o.id
      ORDER BY or_ret.created_at DESC
    ''');
    return results.map((map) => OrderReturn.fromMap(map)).toList();
  }

  Future<OrderReturn?> getOrderReturn(int id) async {
    final db = await DBProvider.instance.database;
    final results = await db.rawQuery('''
      SELECT or_ret.*, o.invoice_number as original_invoice_number
      FROM order_returns or_ret
      LEFT JOIN orders o ON or_ret.order_id = o.id
      WHERE or_ret.id = ?
    ''', [id]);

    if (results.isEmpty) return null;

    final returnProductsResult = await db.rawQuery('''
      SELECT orp.*, p.name as product_name, v.name as variant_name
      FROM order_return_products orp
      LEFT JOIN order_products op ON orp.order_product_id = op.id
      LEFT JOIN products p ON op.product_id = p.id
      LEFT JOIN variants v ON op.variant_id = v.id
      WHERE orp.order_return_id = ?
    ''', [id]);

    final returnProducts = returnProductsResult.map((map) => OrderReturnProduct.fromMap(map)).toList();

    return OrderReturn.fromMap(results.first, returnProducts: returnProducts);
  }

  Future<OrderReturn> createOrderReturn(OrderReturn orderReturn, List<OrderReturnProduct> returnProducts) async {
    final db = await DBProvider.instance.database;
    return await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      
      double totalRefund = returnProducts.fold(0.0, (sum, item) => sum + item.totalRefundAmount);
      
      final existing = await txn.query('order_returns', where: 'invoice_number = ?', whereArgs: [orderReturn.invoiceNumber]);
      String finalInvoiceNumber = orderReturn.invoiceNumber;
      if (existing.isNotEmpty) {
         finalInvoiceNumber = '${orderReturn.invoiceNumber}-${DateTime.now().millisecondsSinceEpoch}';
      }

      final map = orderReturn.toMap();
      map.remove('id');
      map['created_at'] = now;
      map['updated_at'] = now;
      map['total_refund_amount'] = totalRefund;
      map['invoice_number'] = finalInvoiceNumber;

      final id = await txn.insert('order_returns', map);

      // Adjust parent order totals: subtract total refund from order.total_price
      final orderRes = await txn.query('orders', where: 'id = ?', whereArgs: [orderReturn.orderId]);
      if (orderRes.isNotEmpty) {
        final currentOrderTotal = (orderRes.first['total_price'] as num?)?.toDouble() ?? 0.0;
        final updatedOrderTotal = (currentOrderTotal - totalRefund) < 0 ? 0.0 : (currentOrderTotal - totalRefund);
        await txn.update(
          'orders',
          {
            'total_price': updatedOrderTotal,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [orderReturn.orderId],
        );
      }

      for (var product in returnProducts) {
        final opResult = await txn.query(
          'order_products',
          where: 'id = ?',
          whereArgs: [product.orderProductId],
        );

        if (opResult.isNotEmpty) {
          final opFirst = opResult.first;
          final currentQty = (opFirst['quantity'] as num?)?.toInt() ?? 0;
          final newQty = currentQty - product.quantity;

          final opProfit = (opFirst['profit'] as num?)?.toDouble() ?? 0.0;
          final unitProfit = currentQty > 0 ? (opProfit / currentQty) : 0.0;
          final profitDelta = unitProfit * product.quantity;
          final newProfit = (opProfit - profitDelta) < 0 ? 0.0 : (opProfit - profitDelta);

          await txn.update(
            'order_products',
            {
              'quantity': newQty < 0 ? 0 : newQty,
              'total_refunded_amount': ((opFirst['total_refunded_amount'] as num?)?.toDouble() ?? 0.0) + product.totalRefundAmount,
              'profit': newProfit,
              'updated_at': now,
            },
            where: 'id = ?',
            whereArgs: [product.orderProductId],
          );
        }

        final productMap = product.toMap();
        productMap.remove('id');
        productMap['order_return_id'] = id;
        productMap['created_at'] = now;
        productMap['updated_at'] = now;
        await txn.insert('order_return_products', productMap);

        if (product.isRestocked) {
           final opResult = await txn.query('order_products', where: 'id = ?', whereArgs: [product.orderProductId]);
           if (opResult.isNotEmpty) {
             final productId = opResult.first['product_id'] as int;
             final variantId = opResult.first['variant_id'] as int?;

             if (variantId != null) {
                await txn.rawUpdate('UPDATE variants SET stock_quantity = stock_quantity + ? WHERE id = ?', [product.quantity, variantId]);
             } else {
                await txn.rawUpdate('UPDATE products SET stock_quantity = stock_quantity + ? WHERE id = ?', [product.quantity, productId]);
             }
           }
        }
      }

      return OrderReturn(
        id: id,
        invoiceNumber: finalInvoiceNumber,
        orderId: orderReturn.orderId,
        sellerId: orderReturn.sellerId,
        totalRefundAmount: totalRefund,
        restockingDecision: orderReturn.restockingDecision,
        paymentSlip: orderReturn.paymentSlip,
        createdAt: DateTime.parse(now),
        updatedAt: DateTime.parse(now),
        returnProducts: returnProducts,
      );
    });
  }

  Future<void> deleteOrderReturn(int id) async {
    final db = await DBProvider.instance.database;
    await db.transaction((txn) async {
      // Revert restocked products
      final returnProducts = await txn.query('order_return_products', where: 'order_return_id = ?', whereArgs: [id]);
      for (var rp in returnProducts) {
         final opResult = await txn.query('order_products', where: 'id = ?', whereArgs: [rp['order_product_id']]);
         if (opResult.isNotEmpty) {
            final opFirst = opResult.first;
            final currentQty = (opFirst['quantity'] as num?)?.toInt() ?? 0;
            final qty = rp['quantity'] as int;

            final opProfit = (opFirst['profit'] as num?)?.toDouble() ?? 0.0;
            final unitProfit = currentQty > 0 ? (opProfit / currentQty) : 0.0;
            final profitDelta = unitProfit * qty;
            final newProfit = opProfit + profitDelta;

            await txn.update(
              'order_products',
              {
                'quantity': currentQty + qty,
                'total_refunded_amount': ((opFirst['total_refunded_amount'] as num?)?.toDouble() ?? 0.0) - ((rp['total_refund_amount'] as num?)?.toDouble() ?? 0.0),
                'profit': newProfit,
                'updated_at': DateTime.now().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [rp['order_product_id']],
            );
         }

         if (rp['is_restocked'] == 1) {
            if (opResult.isNotEmpty) {
              final productId = opResult.first['product_id'] as int;
              final variantId = opResult.first['variant_id'] as int?;
              final qty = rp['quantity'] as int;

              if (variantId != null) {
                 await txn.rawUpdate('UPDATE variants SET stock_quantity = stock_quantity - ? WHERE id = ?', [qty, variantId]);
              } else {
                 await txn.rawUpdate('UPDATE products SET stock_quantity = stock_quantity - ? WHERE id = ?', [qty, productId]);
              }
            }
         }
      }
      
      await txn.delete('order_return_products', where: 'order_return_id = ?', whereArgs: [id]);
      // Restore parent order totals: add back the refund amount
      final orRow = await txn.query('order_returns', where: 'id = ?', whereArgs: [id]);
      if (orRow.isNotEmpty) {
        final orderId = orRow.first['order_id'] as int?;
        final refundAmount = (orRow.first['total_refund_amount'] as num?)?.toDouble() ?? 0.0;
        if (orderId != null && refundAmount != 0.0) {
          final orderRes = await txn.query('orders', where: 'id = ?', whereArgs: [orderId]);
          if (orderRes.isNotEmpty) {
            final currentOrderTotal = (orderRes.first['total_price'] as num?)?.toDouble() ?? 0.0;
            final updatedOrderTotal = currentOrderTotal + refundAmount;
            await txn.update(
              'orders',
              {
                'total_price': updatedOrderTotal,
                'updated_at': DateTime.now().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [orderId],
            );
          }
        }
      }

      await txn.delete('order_returns', where: 'id = ?', whereArgs: [id]);
    });
  }
}
