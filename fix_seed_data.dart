import 'dart:io';
import 'lib/data/local/db_seed.dart';
import 'lib/data/local/db_seed_orders.dart';
import 'dart:convert';

void main() {
  var productIds = DBSeed.products.map((p) => p['id']).toSet();
  var orderIds = DBSeedOrders.orders.map((o) => o['id']).toSet();
  var variantIds = DBSeed.variants != null ? DBSeed.variants.map((v) => v['id']).toSet() : <int>{};

  var validOrderProducts = DBSeedOrders.orderProducts.where((op) {
    if (!orderIds.contains(op['order_id'])) return false;
    if (!productIds.contains(op['product_id'])) return false;
    // We ignore variant check if variant_id is null, but we could check it
    return true;
  }).toList();

  print('Original order_products: ${DBSeedOrders.orderProducts.length}');
  print('Valid order_products: ${validOrderProducts.length}');
  
  var file = File('lib/data/local/db_seed_orders.dart');
  
  var sb = StringBuffer();
  sb.writeln('class DBSeedOrders {');
  
  // write orders
  sb.writeln('  static const List<Map<String, dynamic>> orders = [');
  for (var o in DBSeedOrders.orders) {
    sb.writeln('    ${jsonEncode(o)},');
  }
  sb.writeln('  ];');

  // write valid orderProducts
  sb.writeln('  static const List<Map<String, dynamic>> orderProducts = [');
  for (var op in validOrderProducts) {
    sb.writeln('    ${jsonEncode(op)},');
  }
  sb.writeln('  ];');
  
  sb.writeln('}');
  
  file.writeAsStringSync(sb.toString());
  print('Done rewriting db_seed_orders.dart');
}
