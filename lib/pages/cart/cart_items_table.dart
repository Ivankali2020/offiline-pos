import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:abpos/controllers/cart_controller.dart';
import 'package:intl/intl.dart';

class CartItemsTable extends StatelessWidget {
  final CartController controller;
  final NumberFormat currencyFormat;

  const CartItemsTable({
    super.key,
    required this.controller,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final theme = Theme.of(context);

      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    'no'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    'name'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Text(
                    'qty'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'price'.tr,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Text(
                    'subtotal'.tr,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 40), // Space for delete icon
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: theme.dividerColor.withValues(alpha: 0.10)),
                right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.10)),
                bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.10)),
              ),
            ),
            child: Column(
              children: controller.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isLast = index == controller.items.length - 1;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(
                            bottom: BorderSide(
                              color: theme.dividerColor.withValues(alpha: 0.08),
                            ),
                          ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 30, child: Text('${index + 1}')),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName ?? 'product_singular'.tr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (item.variantName != null)
                              Text(
                                item.variantName!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                LucideIcons.minusCircle,
                                size: 16,
                                color: Colors.blue,
                              ),
                              onPressed: () =>
                                  controller.updateQuantity(index, -1),
                            ),
                            Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                LucideIcons.plusCircle,
                                size: 16,
                                color: Colors.blue,
                              ),
                              onPressed: () =>
                                  controller.updateQuantity(index, 1),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          currencyFormat.format(item.price),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: Text(
                          currencyFormat.format(item.price * item.quantity),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: IconButton(
                          icon: const Icon(
                            LucideIcons.trash2,
                            size: 16,
                            color: Colors.red,
                          ),
                          onPressed: () => controller.removeItem(item),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    });
  }
}
