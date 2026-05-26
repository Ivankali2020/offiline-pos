import 'lib/data/local/db_seed.dart';
import 'lib/data/local/db_seed_orders.dart';

void main() {
  var productIds = DBSeed.products.map((p) => p['id']).toSet();
  print('Total products: ${productIds.length}');
  print('Max product id: ${productIds.isEmpty ? "none" : productIds.reduce((a,b) => a > b ? a : b)}');
  print('Contains 748: ${productIds.contains(748)}');
  
  var orderIds = DBSeedOrders.orders.map((o) => o['id']).toSet();
  print('Total orders: ${orderIds.length}');
  print('Contains 306: ${orderIds.contains(306)}');
}
