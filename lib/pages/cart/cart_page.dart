import 'package:abpos/controllers/cart_controller.dart';
import 'package:abpos/routes/app_routes.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'cart_items_table.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartController controller = Get.find<CartController>();

  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;

    return AppScaffold(
      title: 'pos_sale'.tr,
      appBar: CustomAppBar(
        title: 'pos_sale'.tr,
        subtitle: 'Create a compact sale invoice and checkout quickly.',
        // backgroundColor: pageBackground,
      ),
      // backgroundColor: pageBackground,
      bottomNavigationBar: Obx(
        () => _CartBottomBar(
          currencyFormat: _currencyFormat,
          total: controller.subTotal,
          quantity: controller.totalQuantity,
          isEnabled: controller.items.isNotEmpty,
          onPressed: () => Get.toNamed(AppRoutes.checkout),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(
              () => _CartInsightRow(
                currencyFormat: _currencyFormat,
                totalItems: controller.totalQuantity,
                subTotal: controller.subTotal,
                customerName: controller.customerName.value,
              ),
            ),
            const SizedBox(height: 14),
            _buildAddItemsCard(context),
            const SizedBox(height: 18),
            _buildItemsHeader(context),
            const SizedBox(height: 12),
            Obx(() {
              if (controller.items.isEmpty) {
                return _buildEmptyState(context);
              }

              if (isWide) {
                return Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Column(
                    children: [
                      CartItemsTable(
                        controller: controller,
                        currencyFormat: _currencyFormat,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.04),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${controller.totalQuantity} ${'qty'.tr}',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'MMK ${_currencyFormat.format(controller.subTotal)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: controller.items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return _CartItemCard(
                    itemName: item.productName ?? 'Product',
                    variantName: item.variantName,
                    quantity: item.quantity,
                    unitPrice: item.price,
                    totalPrice: item.price * item.quantity,
                    currencyFormat: _currencyFormat,
                    onDecrease: () => controller.updateQuantity(index, -1),
                    onIncrease: () => controller.updateQuantity(index, 1),
                    onDelete: () => controller.removeItem(item),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAddItemsCard(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => Get.toNamed(AppRoutes.productPicker),
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                LucideIcons.plusCircle,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'add_items'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Browse products and add them to the cart quickly.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.75,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'items'.tr,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Obx(
          () => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${controller.totalQuantity} ${'qty'.tr}',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.shoppingBasket,
              size: 28,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'cart_is_empty'.tr,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start by adding some products to build this sale.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartInsightRow extends StatelessWidget {
  const _CartInsightRow({
    required this.currencyFormat,
    required this.totalItems,
    required this.subTotal,
    required this.customerName,
  });

  final NumberFormat currencyFormat;
  final int totalItems;
  final double subTotal;
  final String customerName;

  @override
  Widget build(BuildContext context) {
    final customer = customerName.trim().isEmpty
        ? 'Walk-in'
        : customerName.trim();

    return Row(
      children: [
        Expanded(
          child: _CartMiniStat(
            title: 'Items',
            value: '$totalItems',
            icon: Icons.shopping_bag_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CartMiniStat(
            title: 'Subtotal',
            value: 'MMK ${currencyFormat.format(subTotal)}',
            icon: Icons.payments_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CartMiniStat(
            title: 'Customer',
            value: customer,
            icon: Icons.person_outline_rounded,
          ),
        ),
      ],
    );
  }
}

class _CartMiniStat extends StatelessWidget {
  const _CartMiniStat({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.itemName,
    required this.variantName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.currencyFormat,
    required this.onDecrease,
    required this.onIncrease,
    required this.onDelete,
  });

  final String itemName;
  final String? variantName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final NumberFormat currencyFormat;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if ((variantName ?? '').trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          variantName!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.72),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    LucideIcons.trash2,
                    color: Colors.red,
                    size: 18,
                  ),
                  onPressed: onDelete,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          LucideIcons.minusCircle,
                          size: 18,
                          color: Colors.blue,
                        ),
                        onPressed: onDecrease,
                      ),
                      Text(
                        '$quantity',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          LucideIcons.plusCircle,
                          size: 18,
                          color: Colors.blue,
                        ),
                        onPressed: onIncrease,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'MMK ${currencyFormat.format(unitPrice)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.72,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'MMK ${currencyFormat.format(totalPrice)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartBottomBar extends StatelessWidget {
  const _CartBottomBar({
    required this.currencyFormat,
    required this.total,
    required this.quantity,
    required this.isEnabled,
    required this.onPressed,
  });

  final NumberFormat currencyFormat;
  final double total;
  final int quantity;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.08)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$quantity ${'qty'.tr}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.72,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'MMK ${currencyFormat.format(total)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ElevatedButton(
                onPressed: isEnabled ? onPressed : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'next_step'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
