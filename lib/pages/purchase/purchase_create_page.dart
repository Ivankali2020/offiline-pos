import 'package:abpos/controllers/purchase_cart_controller.dart';
import 'package:abpos/controllers/purchase_controller.dart';
import 'package:abpos/models/purchase.dart';
import 'package:abpos/models/purchase_product.dart';
import 'package:abpos/pages/purchase/purchase_detail_page.dart';
import 'package:abpos/routes/app_routes.dart';
import 'package:abpos/widgets/app_bottom_action_bar.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PurchaseCreatePage extends StatefulWidget {
  const PurchaseCreatePage({super.key});

  @override
  State<PurchaseCreatePage> createState() => _PurchaseCreatePageState();
}

class _PurchaseCreatePageState extends State<PurchaseCreatePage> {
  final PurchaseCartController cartController =
      Get.find<PurchaseCartController>();
  final PurchaseController purchaseController = Get.find<PurchaseController>();
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');
  late final TextEditingController _paidController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    cartController.clearCart();
    _paidController = TextEditingController(text: '0');
    _noteController = TextEditingController();
    _paidController.addListener(() {
      cartController.paidAmount.value =
          double.tryParse(_paidController.text) ?? 0;
    });
    _noteController.addListener(() {
      cartController.note.value = _noteController.text;
    });
  }

  @override
  void dispose() {
    _paidController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'New Purchase',
      appBar: const CustomAppBar(
        title: 'New Purchase',
        subtitle: 'Pick products, set cost, and save a pending stock receipt.',
      ),
      bottomNavigationBar: Obx(
        () => AppBottomActionBar(
          summaryLabel: 'Total Purchase',
          summaryValue:
              'MMK ${_currencyFormat.format(cartController.totalAmount)}',
          summaryValueColor: const Color(0xFF0F766E),
          actionLabel: 'Save Purchase',
          onPressed: _savePurchase,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(
              () => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0F766E),
                      const Color(0xFF111827).withValues(alpha: 0.92),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.inventory_2_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cartController.invoiceNumber.value,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${cartController.totalQuantity} items ready for intake',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.86),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'MMK ${_currencyFormat.format(cartController.totalAmount)}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _HeroChip(
                            label: 'Paid',
                            value:
                                'MMK ${_currencyFormat.format(cartController.paidAmount.value)}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _HeroChip(
                            label: 'Due',
                            value:
                                'MMK ${_currencyFormat.format(cartController.dueAmount)}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildPurchaseItemsSection(context),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Payment Setup',
              icon: Icons.payments_outlined,
              child: Column(
                children: [
                  TextField(
                    controller: _paidController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Paid Amount',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Note',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseItemsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                color: theme.colorScheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Purchase Items',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.purchaseProductPicker),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Add Products'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() {
          final items = cartController.items;
          if (items.isEmpty) {
            return _PurchaseItemsEmptyState(
              onAdd: () => Get.toNamed(AppRoutes.purchaseProductPicker),
            );
          }

          return Column(
            children: [
              for (var i = 0; i < items.length; i++)
                _PurchaseItemCard(
                  item: items[i],
                  currencyFormat: _currencyFormat,
                  onDecrease: () => cartController.updateQuantity(i, -1),
                  onIncrease: () => cartController.updateQuantity(i, 1),
                  onEdit: () => _editLineItem(i, items[i]),
                  onRemove: () => cartController.removeItem(items[i]),
                ),
            ],
          );
        }),
      ],
    );
  }

  Future<void> _editLineItem(int index, PurchaseProduct item) async {
    final quantityController = TextEditingController(
      text: item.quantity.toString(),
    );
    final costController = TextEditingController(
      text: item.costPrice.toStringAsFixed(
        item.costPrice.truncateToDouble() == item.costPrice ? 0 : 2,
      ),
    );
    final sellController = TextEditingController(
      text: (item.sellPrice ?? 0).toStringAsFixed(
        (item.sellPrice ?? 0).truncateToDouble() == (item.sellPrice ?? 0)
            ? 0
            : 2,
      ),
    );
    await Get.dialog(
      AlertDialog(
        title: Text('Edit ${item.productName ?? 'Purchase Item'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: costController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Cost Price'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sellController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Sell Price'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final quantity =
                  int.tryParse(quantityController.text.trim()) ?? 0;
              final costPrice = double.tryParse(costController.text.trim());
              final sellPrice = double.tryParse(sellController.text.trim());
              if (quantity > 0 &&
                  costPrice != null &&
                  costPrice >= 0 &&
                  sellPrice != null &&
                  sellPrice >= 0) {
                cartController.updateLine(
                  index,
                  quantity: quantity,
                  costPrice: costPrice,
                  sellPrice: sellPrice,
                );
              }
              Get.back();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePurchase() async {
    if (cartController.items.isEmpty) {
      Get.snackbar('Missing items', 'Pick at least one product first.');
      return;
    }

    final now = cartController.purchaseDate.value.toIso8601String();
    final purchase = Purchase(
      invoiceNumber: cartController.invoiceNumber.value,
      sellerId: 1,
      totalAmount: cartController.totalAmount,
      paidAmount: cartController.paidAmount.value,
      dueAmount: cartController.dueAmount,
      status: 'pending',
      note: cartController.note.value.trim().isEmpty
          ? null
          : cartController.note.value.trim(),
      createdAt: now,
      updatedAt: now,
    );

    final saved = await purchaseController.createPurchase(
      purchase,
      cartController.items.toList(growable: false),
    );
    cartController.clearCart();
    Get.off(() => PurchaseDetailPage(purchase: saved));
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PurchaseItemsEmptyState extends StatelessWidget {
  const _PurchaseItemsEmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.packagePlus,
              color: Color(0xFF0F766E),
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No products selected yet.',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Add Products'),
          ),
        ],
      ),
    );
  }
}

class _PurchaseItemCard extends StatelessWidget {
  const _PurchaseItemCard({
    required this.item,
    required this.currencyFormat,
    required this.onDecrease,
    required this.onIncrease,
    required this.onEdit,
    required this.onRemove,
  });

  final PurchaseProduct item;
  final NumberFormat currencyFormat;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sellPrice = item.sellPrice ?? 0;
    final variantName = item.variantName?.trim();

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName ?? 'Product #${item.productId}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (variantName != null && variantName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          variantName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.72,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _PurchaseIconButton(
                tooltip: 'Edit item',
                icon: LucideIcons.pencil,
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.09,
                ),
                onPressed: onEdit,
              ),
              const SizedBox(width: 6),
              _PurchaseIconButton(
                tooltip: 'Remove item',
                icon: LucideIcons.trash2,
                color: Colors.red,
                backgroundColor: Colors.red.withValues(alpha: 0.08),
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        tooltip: 'Reduce quantity',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: onDecrease,
                        icon: const Icon(
                          LucideIcons.minusCircle,
                          color: Color(0xFF0F766E),
                          size: 18,
                        ),
                      ),
                      Text(
                        '${item.quantity}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Add quantity',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: onIncrease,
                        icon: const Icon(
                          LucideIcons.plusCircle,
                          color: Color(0xFF0F766E),
                          size: 18,
                        ),
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
                    'MMK ${currencyFormat.format(item.costPrice)} cost',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.72,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'MMK ${currencyFormat.format(item.totalCost)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F766E),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PurchaseLineMetric(
                  label: 'Cost',
                  value: 'MMK ${currencyFormat.format(item.costPrice)}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PurchaseLineMetric(
                  label: 'Sell',
                  value: 'MMK ${currencyFormat.format(sellPrice)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PurchaseLineMetric extends StatelessWidget {
  const _PurchaseLineMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.42,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.textTheme.labelSmall?.color?.withValues(alpha: 0.68),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseIconButton extends StatelessWidget {
  const _PurchaseIconButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: color, size: 18),
        onPressed: onPressed,
      ),
    );
  }
}
