import 'package:abpos/controllers/order_return_controller.dart';
import 'package:abpos/models/order.dart';
import 'package:abpos/models/order_product.dart';
import 'package:abpos/models/order_return_product.dart';
import 'package:abpos/services/app_refresh_service.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class OrderReturnFormPage extends StatefulWidget {
  const OrderReturnFormPage({super.key});

  @override
  State<OrderReturnFormPage> createState() => _OrderReturnFormPageState();
}

class _OrderReturnFormPageState extends State<OrderReturnFormPage> {
  late final Order order;
  late final List<OrderProduct> products;
  final _controller = Get.put(OrderReturnController());

  final Map<int, int> _returnQuantities = {};
  final Map<int, bool> _isRestocked = {};
  final Map<int, TextEditingController> _reasonControllers = {};

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    order = args['order'] as Order;
    products = args['products'] as List<OrderProduct>;

    for (var p in products) {
      _returnQuantities[p.id!] = 0;
      _isRestocked[p.id!] = true;
      _reasonControllers[p.id!] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var c in _reasonControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _totalRefund {
    double total = 0;
    for (var p in products) {
      final qty = _returnQuantities[p.id!] ?? 0;
      if (qty > 0) {
        total += p.price * qty;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat('#,##0', 'en_US');

    return AppScaffold(
      title: 'create_return'.tr,
      appBar: CustomAppBar(
        title: 'create_return'.tr,
        subtitle: order.invoiceNumber,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final id = product.id!;
                final returnQty = _returnQuantities[id] ?? 0;
                final price = product.price;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.productName ?? 'Unknown',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (product.variantName != null)
                          Text(
                            product.variantName!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        const SizedBox(height: 8),
                        Text(
                          '${'price'.tr}: ${numberFormat.format(price)} MMK',
                        ),
                        Text('${'ordered_qty'.tr}: ${product.quantity}'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text('return_qty'.tr),
                            const Spacer(),
                            IconButton(
                              onPressed: returnQty > 0
                                  ? () {
                                      setState(() {
                                        _returnQuantities[id] = returnQty - 1;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              '$returnQty',
                              style: theme.textTheme.titleMedium,
                            ),
                            IconButton(
                              onPressed: returnQty < product.quantity
                                  ? () {
                                      setState(() {
                                        _returnQuantities[id] = returnQty + 1;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                        if (returnQty > 0) ...[
                          const SizedBox(height: 8),
                          SwitchListTile(
                            title: Text('restock_item'.tr),
                            value: _isRestocked[id] ?? true,
                            onChanged: (val) {
                              setState(() {
                                _isRestocked[id] = val;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                          TextField(
                            controller: _reasonControllers[id],
                            decoration: InputDecoration(
                              labelText: 'reason'.tr,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'total_refund'.tr,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        '${numberFormat.format(_totalRefund)} MMK',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: const Color(0xFFF43F5E),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isSubmitting || _totalRefund <= 0
                        ? null
                        : _submitReturn,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: const Color(0xFFF43F5E),
                      foregroundColor: Colors.white,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text('confirm_return'.tr),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReturn() async {
    setState(() => _isSubmitting = true);

    List<OrderReturnProduct> returnProducts = [];
    for (var p in products) {
      final qty = _returnQuantities[p.id!] ?? 0;
      if (qty > 0) {
        final price = p.price;
        returnProducts.add(
          OrderReturnProduct(
            orderReturnId: 0,
            orderProductId: p.id!,
            quantity: qty,
            unitRefundAmount: price,
            totalRefundAmount: price * qty,
            isRestocked: _isRestocked[p.id!] ?? true,
            individualReason: _reasonControllers[p.id!]?.text,
          ),
        );
      }
    }

    final result = await _controller.createReturnFromOrder(
      order,
      returnProducts,
    );

    setState(() => _isSubmitting = false);

    if (result != null) {
      await AppRefreshService.refreshAll();
      Get.back();
      Get.snackbar(
        'success'.tr,
        'return_created'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
