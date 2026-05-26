import 'dart:io';

import 'package:abpos/controllers/cart_controller.dart';
import 'package:abpos/controllers/order_controller.dart';
import 'package:abpos/controllers/payment_controller.dart';
import 'package:abpos/models/payment.dart';
import 'package:abpos/pages/order/order_detail_page.dart';
import 'package:abpos/routes/app_routes.dart';
import 'package:abpos/widgets/app_bottom_action_bar.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';
import 'package:abpos/widgets/form/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final CartController controller = Get.find<CartController>();
  final OrderController orderController = Get.find<OrderController>();
  final PaymentController paymentController = Get.find<PaymentController>();
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _shippingController;
  late TextEditingController _receivedController;
  late TextEditingController _discountController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _shippingController = TextEditingController(
      text: controller.deliveryFees.value.toStringAsFixed(0),
    );
    _receivedController = TextEditingController(
      text: controller.receivedAmount.value > 0
          ? controller.receivedAmount.value.toStringAsFixed(0)
          : '',
    );
    _discountController = TextEditingController(
      text: controller.discountValue.value.toStringAsFixed(0),
    );
    _noteController = TextEditingController(text: controller.note.value);

    _shippingController.addListener(() {
      controller.deliveryFees.value =
          double.tryParse(_shippingController.text.trim()) ?? 0.0;
    });
    _receivedController.addListener(() {
      controller.receivedAmount.value =
          double.tryParse(_receivedController.text.trim()) ?? 0.0;
    });
    _discountController.addListener(() {
      controller.discountValue.value =
          double.tryParse(_discountController.text.trim()) ?? 0.0;
    });
    _noteController.addListener(() {
      controller.note.value = _noteController.text;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensurePaymentSelection();
    });
  }

  @override
  void dispose() {
    _shippingController.dispose();
    _receivedController.dispose();
    _discountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pageBackground = Color.alphaBlend(
      theme.colorScheme.primary.withValues(alpha: 0.04),
      theme.colorScheme.surface,
    );

    return AppScaffold(
      title: 'checkout'.tr,
      includeDrawer: false,
      backgroundColor: pageBackground,
      appBar: CustomAppBar(
        title: 'checkout'.tr,
        subtitle: 'checkout_subtitle'.tr,
        actions: [
          IconButton(
            onPressed: () => Get.toNamed(AppRoutes.payments),
            icon: Icon(
              Icons.account_balance_wallet_outlined,
              color: theme.colorScheme.primary,
            ),
            tooltip: 'Payments',
          ),
        ],
      ),
      bottomNavigationBar: Obx(
        () => AppBottomActionBar(
          summaryLabel: 'total'.tr,
          summaryValue: 'MMK ${_currencyFormat.format(controller.totalAmount)}',
          summaryValueColor: theme.colorScheme.primary,
          actionLabel: 'complete_sale'.tr,
          actionIcon: LucideIcons.badgeCheck,
          onPressed: _completeSale,
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(
                () => _CheckoutHero(
                  currencyFormat: _currencyFormat,
                  totalAmount: controller.totalAmount,
                  subTotal: controller.subTotal,
                  dueAmount: controller.dueAmount,
                  totalQuantity: controller.totalQuantity,
                ),
              ),
              const SizedBox(height: 16),
              _CheckoutSectionCard(
                title: 'order_summary'.tr,
                icon: Icons.receipt_long_rounded,
                child: Column(
                  children: [
                    _buildSummaryRow('subtotal'.tr, controller.subTotal),
                    Obx(
                      () => _buildSummaryRow(
                        'discount'.tr,
                        -controller.discountAmount,
                        color: Colors.red.shade600,
                      ),
                    ),
                    _buildSummaryRow('tax'.tr, controller.taxAmount),
                    Obx(
                      () => _buildSummaryRow(
                        'shipping_fees'.tr,
                        controller.deliveryFees.value,
                      ),
                    ),
                    const Divider(height: 24),
                    Obx(
                      () => _buildSummaryRow(
                        'total'.tr,
                        controller.totalAmount,
                        isBold: true,
                        fontSize: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _CheckoutSectionCard(
                title: 'payment_setup'.tr,
                icon: Icons.account_balance_wallet_outlined,
                child: Column(
                  children: [
                    _CompactPaymentSelector(
                      selectedPaymentId: controller.selectedPaymentId,
                      selectedPaymentAccountId:
                          controller.selectedPaymentAccountId,
                      onManagePayments: () => Get.toNamed(AppRoutes.payments),
                      onSelectPayment: (payment) {
                        controller.selectPayment(payment.id ?? 0);
                        final accounts = paymentController.accountsForPayment(
                          payment.id,
                        );
                        if (accounts.length == 1) {
                          controller.selectPaymentAccount(accounts.first.id);
                        }
                      },
                      onSelectAccount: controller.selectPaymentAccount,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'shipping_fees'.tr,
                            controller: _shippingController,
                            keyboardType: TextInputType.number,
                            suffixIcon: const Icon(LucideIcons.truck, size: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: 'received_amount'.tr,
                            controller: _receivedController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            isRequired: true,
                            validator: (value) {
                              final amount = double.tryParse(
                                (value ?? '').trim(),
                              );
                              if (amount == null || amount <= 0) {
                                return 'received_amount_error'.tr;
                              }
                              return null;
                            },
                            suffixIcon: const Icon(
                              LucideIcons.banknote,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _QuickAmountChips(
                      totalAmount: controller.totalAmount,
                      currencyFormat: _currencyFormat,
                      onSelectAmount: (amount) {
                        _receivedController.text = amount.toStringAsFixed(0);
                        controller.receivedAmount.value = amount;
                      },
                    ),
                    const SizedBox(height: 14),
                    _QuickDiscountChips(
                      onApplyPercent: (value) {
                        controller.isPercentageDiscount.value = true;
                        controller.discountValue.value = value.toDouble();
                        _discountController.text = value.toString();
                      },
                      onApplyFlat: (value) {
                        controller.isPercentageDiscount.value = false;
                        controller.discountValue.value = value.toDouble();
                        _discountController.text = value.toString();
                      },
                      onClear: () {
                        controller.discountValue.value = 0;
                        _discountController.text = '0';
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'discount'.tr,
                            controller: _discountController,
                            keyboardType: TextInputType.number,
                            suffixIcon: const Icon(
                              LucideIcons.percent,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Obx(
                          () => Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.06,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ToggleButtons(
                              isSelected: [
                                !controller.isPercentageDiscount.value,
                                controller.isPercentageDiscount.value,
                              ],
                              onPressed: (index) =>
                                  controller.isPercentageDiscount.value =
                                      index == 1,
                              borderRadius: BorderRadius.circular(12),
                              constraints: const BoxConstraints(
                                minHeight: 48,
                                minWidth: 52,
                              ),
                              children: const [
                                Text(
                                  'Ks',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '%',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Obx(() {
                final due = controller.dueAmount;
                final isOverpaid = due < 0;
                final label = isOverpaid ? 'change_amount'.tr : 'due_amount'.tr;
                final amount = isOverpaid ? -due : due;
                final color = isOverpaid
                    ? Colors.green.shade700
                    : (due > 0
                          ? Colors.orange.shade800
                          : Colors.green.shade700);

                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: color.withValues(alpha: 0.20)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'payment_status'.tr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: color.withValues(alpha: 0.92),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'MMK ${_currencyFormat.format(amount)}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              _CheckoutSectionCard(
                title: 'payment_proof'.tr,
                icon: Icons.image_outlined,
                child: Obx(
                  () => _PaymentImageSection(
                    imagePath: controller.paymentImagePath.value,
                    onPickFromGallery: () =>
                        _pickPaymentImage(ImageSource.gallery),
                    onPickFromCamera: () =>
                        _pickPaymentImage(ImageSource.camera),
                    onRemove: () => controller.setPaymentImagePath(null),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _CheckoutSectionCard(
                title: 'additional_note'.tr,
                icon: Icons.sticky_note_2_outlined,
                child: CustomTextField(
                  label: 'note'.tr,
                  maxLines: 2,
                  controller: _noteController,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPaymentImage(ImageSource source) async {
    final file = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) return;
    controller.setPaymentImagePath(file.path);
  }

  void _ensurePaymentSelection() {
    final published = paymentController.publishedPayments;
    if (published.isEmpty) return;

    final selected = published.any(
      (payment) => payment.id == controller.selectedPaymentId.value,
    );
    if (!selected) {
      controller.selectPayment(published.first.id ?? 0);
      final accounts = paymentController.accountsForPayment(published.first.id);
      if (accounts.length == 1) {
        controller.selectPaymentAccount(accounts.first.id);
      }
    }
  }

  Future<void> _completeSale() async {
    if (!_formKey.currentState!.validate()) return;

    final publishedPayments = paymentController.publishedPayments;
    if (publishedPayments.isEmpty) {
      Get.snackbar(
        'payment_required'.tr,
        'create_payment_first'.tr,
      );
      return;
    }

    final selectedPayment = _findSelectedPayment(publishedPayments);
    if (selectedPayment == null) {
      Get.snackbar(
        'payment_required'.tr,
        'choose_payment_error'.tr,
      );
      return;
    }

    final selectedAccounts = paymentController.accountsForPayment(
      selectedPayment.id,
    );
    if (selectedAccounts.isNotEmpty &&
        controller.selectedPaymentAccountId.value == null) {
      Get.snackbar(
        'account_required'.tr,
        'choose_payment_account'.tr.replaceAll('@name', selectedPayment.name),
      );
      return;
    }

    final receivedAmount =
        double.tryParse(_receivedController.text.trim()) ?? 0;
    if (receivedAmount <= 0) {
      Get.snackbar(
        'received_amount_required'.tr,
        'received_amount_error'.tr,
      );
      return;
    }

    final savedOrder = await orderController.checkout(
      controller.items.toList(),
      customerName: controller.customerName.value,
      customerPhone: controller.customerPhone.value,
      subTotal: controller.subTotal,
      deliveryFees: controller.deliveryFees.value,
      totalPrice: controller.totalAmount,
      tax: controller.taxRate,
      taxPrice: controller.taxAmount,
      givenAmount: controller.receivedAmount.value,
      changeAmount: controller.dueAmount < 0 ? -controller.dueAmount : 0,
      paymentId: controller.selectedPaymentId.value,
      paymentAccountId: controller.selectedPaymentAccountId.value,
      note: controller.note.value,
      imagePath: controller.paymentImagePath.value,
    );

    controller.clearCart();
    Get.snackbar('success'.tr, 'order_completed'.tr);
    Get.off(() => OrderDetailPage(order: savedOrder));
  }

  Payment? _findSelectedPayment(List<Payment> publishedPayments) {
    for (final payment in publishedPayments) {
      if (payment.id == controller.selectedPaymentId.value) {
        return payment;
      }
    }
    return null;
  }

  Widget _buildSummaryRow(
    String label,
    double value, {
    bool isBold = false,
    double fontSize = 14,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            'MMK ${_currencyFormat.format(value)}',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutHero extends StatelessWidget {
  const _CheckoutHero({
    required this.currencyFormat,
    required this.totalAmount,
    required this.subTotal,
    required this.dueAmount,
    required this.totalQuantity,
  });

  final NumberFormat currencyFormat;
  final double totalAmount;
  final double subTotal;
  final double dueAmount;
  final int totalQuantity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            Color.alphaBlend(
              Colors.white.withValues(alpha: 0.08),
              theme.colorScheme.primary,
            ),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
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
                child: const Icon(Icons.payments_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'checkout'.tr,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalQuantity ${'qty'.tr} ${'ready_to_finalize'.tr}',
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
            'MMK ${currencyFormat.format(totalAmount)}',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _CheckoutHeroChip(
                  label: 'subtotal'.tr,
                  value: 'MMK ${currencyFormat.format(subTotal)}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CheckoutHeroChip(
                  label: dueAmount < 0 ? 'change_amount'.tr : 'due_amount'.tr,
                  value:
                      'MMK ${currencyFormat.format(dueAmount < 0 ? -dueAmount : dueAmount)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckoutSectionCard extends StatelessWidget {
  const _CheckoutSectionCard({
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
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
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

class _CompactPaymentSelector extends StatelessWidget {
  const _CompactPaymentSelector({
    required this.selectedPaymentId,
    required this.selectedPaymentAccountId,
    required this.onManagePayments,
    required this.onSelectPayment,
    required this.onSelectAccount,
  });

  final RxInt selectedPaymentId;
  final RxnInt selectedPaymentAccountId;
  final VoidCallback onManagePayments;
  final ValueChanged<Payment> onSelectPayment;
  final ValueChanged<int?> onSelectAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paymentController = Get.find<PaymentController>();

    return Obx(() {
      final payments = paymentController.publishedPayments;
      final selectedAccounts = paymentController.accountsForPayment(
        selectedPaymentId.value,
      );

      if (payments.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'no_payment_methods'.tr,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onManagePayments,
                    child: Text('open_payments'.tr),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'create_payment_first'.tr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.72,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      final hasSelectedPayment = payments.any(
        (payment) => payment.id == selectedPaymentId.value,
      );
      if (!hasSelectedPayment) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onSelectPayment(payments.first);
          final accounts = paymentController.accountsForPayment(
            payments.first.id,
          );
          if (accounts.length == 1) {
            onSelectAccount(accounts.first.id);
          }
        });
      }

      final hasSelectedAccount = selectedAccounts.any(
        (account) => account.id == selectedPaymentAccountId.value,
      );
      if (!hasSelectedAccount && selectedPaymentAccountId.value != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onSelectAccount(null);
        });
      }

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Payment & Account',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onManagePayments,
                  icon: const Icon(LucideIcons.settings2, size: 16),
                  label: const Text('Manage'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: payments.map((payment) {
                return _ChoiceChip(
                  label: payment.name,
                  icon: Icons.payments_outlined,
                  selected: selectedPaymentId.value == payment.id,
                  onTap: () => onSelectPayment(payment),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            if (selectedAccounts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'No account linked to this payment. You can still continue, or add one from Payments.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.74,
                    ),
                  ),
                ),
              )
            else ...[
              Text(
                'Select account',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.72,
                  ),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedAccounts.map((account) {
                  return _ChoiceChip(
                    label: '${account.name} - ${account.number}',
                    icon: Icons.account_balance_outlined,
                    selected: selectedPaymentAccountId.value == account.id,
                    onTap: () => onSelectAccount(account.id),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAmountChips extends StatelessWidget {
  const _QuickAmountChips({
    required this.totalAmount,
    required this.currencyFormat,
    required this.onSelectAmount,
  });

  final double totalAmount;
  final NumberFormat currencyFormat;
  final ValueChanged<double> onSelectAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (totalAmount <= 0) {
      return const SizedBox.shrink();
    }

    final suggestions = <double>{totalAmount};
    final next1000 = (totalAmount / 1000).ceil() * 1000.0;
    if (next1000 > totalAmount) suggestions.add(next1000);
    final next5000 = (totalAmount / 5000).ceil() * 5000.0;
    if (next5000 > totalAmount) suggestions.add(next5000);
    final next10000 = (totalAmount / 10000).ceil() * 10000.0;
    if (next10000 > totalAmount) suggestions.add(next10000);

    final list = suggestions.toList()..sort();

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: list.map((amount) {
          return ActionChip(
            label: Text('MMK ${currencyFormat.format(amount)}'),
            onPressed: () => onSelectAmount(amount),
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
            side: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
            labelStyle: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PaymentImageSection extends StatelessWidget {
  const _PaymentImageSection({
    required this.imagePath,
    required this.onPickFromGallery,
    required this.onPickFromCamera,
    required this.onRemove,
  });

  final String? imagePath;
  final VoidCallback onPickFromGallery;
  final VoidCallback onPickFromCamera;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: onPickFromGallery,
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text('Gallery'),
            ),
            OutlinedButton.icon(
              onPressed: onPickFromCamera,
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: const Text('Camera'),
            ),
            if (imagePath != null)
              TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Remove'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (imagePath == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
              ),
            ),
            child: Text(
              'Optional. Upload a payment slip or receipt image if this sale needs proof.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(
                  alpha: 0.76,
                ),
              ),
            ),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(imagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.black.withValues(alpha: 0.04),
                        alignment: Alignment.center,
                        child: const Text('Preview unavailable'),
                      );
                    },
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: IconButton(
                        onPressed: onRemove,
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _QuickDiscountChips extends StatelessWidget {
  const _QuickDiscountChips({
    required this.onApplyPercent,
    required this.onApplyFlat,
    required this.onClear,
  });

  final ValueChanged<int> onApplyPercent;
  final ValueChanged<int> onApplyFlat;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _DiscountChip(label: '5%', onTap: () => onApplyPercent(5)),
          _DiscountChip(label: '10%', onTap: () => onApplyPercent(10)),
          _DiscountChip(label: '15%', onTap: () => onApplyPercent(15)),
          _DiscountChip(label: '500 Ks', onTap: () => onApplyFlat(500)),
          _DiscountChip(label: '1000 Ks', onTap: () => onApplyFlat(1000)),
          ActionChip(
            avatar: const Icon(Icons.restart_alt_rounded, size: 16),
            label: const Text('Clear'),
            onPressed: onClear,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          ),
        ],
      ),
    );
  }
}

class _DiscountChip extends StatelessWidget {
  const _DiscountChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
      side: BorderSide(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
      ),
      labelStyle: TextStyle(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _CheckoutHeroChip extends StatelessWidget {
  const _CheckoutHeroChip({required this.label, required this.value});

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
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
