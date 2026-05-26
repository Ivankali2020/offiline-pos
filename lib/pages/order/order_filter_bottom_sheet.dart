import 'package:abpos/controllers/order_controller.dart';
import 'package:abpos/widgets/app_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class OrderFilterBottomSheet extends StatefulWidget {
  const OrderFilterBottomSheet({super.key, required this.controller});

  final OrderController controller;

  static Future<void> show(BuildContext context, OrderController controller) {
    return AppBottomSheet.show<void>(
      context,
      title: 'filter_orders'.tr,
      subtitle: 'filter_orders_subtitle'.tr,
      trailing: TextButton(
        onPressed: () {
          controller.clearFilters();
          Get.back<void>();
        },
        child: Text('reset'.tr),
      ),
      child: OrderFilterBottomSheet(controller: controller),
    );
  }

  @override
  State<OrderFilterBottomSheet> createState() => _OrderFilterBottomSheetState();
}

class _OrderFilterBottomSheetState extends State<OrderFilterBottomSheet> {
  late final TextEditingController _invoiceController;
  late DateTime? _startDate;
  late DateTime? _endDate;
  late OrderDateFilterPreset? _selectedPreset;
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _invoiceController = TextEditingController(
      text: widget.controller.invoiceFilter.value,
    );
    _startDate = widget.controller.filterStartDate.value;
    _endDate = widget.controller.filterEndDate.value;
    _selectedPreset = widget.controller.selectedDatePreset.value;
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'invoice_number'.tr,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _invoiceController,
          decoration: InputDecoration(
            hintText: 'search_invoice_no'.tr,
            prefixIcon: const Icon(Icons.receipt_long_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'quick_date_filters'.tr,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildPresetChip(OrderDateFilterPreset.today, 'today'.tr),
            _buildPresetChip(OrderDateFilterPreset.thisWeek, 'this_week'.tr),
            _buildPresetChip(OrderDateFilterPreset.thisMonth, 'this_month'.tr),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'custom_date_range'.tr,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_startDate != null || _endDate != null)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                    _selectedPreset = null;
                  });
                },
                icon: const Icon(Icons.clear_rounded, size: 18),
                label: Text('clear_dates'.tr),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DateButton(
                label: 'start_date'.tr,
                value: _formatDate(_startDate),
                icon: Icons.event_available_rounded,
                onTap: () => _pickDate(isStart: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DateButton(
                label: 'end_date'.tr,
                value: _formatDate(_endDate),
                icon: Icons.event_note_rounded,
                onTap: () => _pickDate(isStart: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Get.back<void>(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text('cancel'.tr),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _apply,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: Text('apply_filters'.tr),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetChip(OrderDateFilterPreset preset, String label) {
    final selected = _selectedPreset == preset;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        setState(() {
          _selectedPreset = preset;
          switch (preset) {
            case OrderDateFilterPreset.today:
              _startDate = today;
              _endDate = today;
              break;
            case OrderDateFilterPreset.thisWeek:
              _startDate = today.subtract(Duration(days: now.weekday - 1));
              _endDate = _startDate!.add(const Duration(days: 6));
              break;
            case OrderDateFilterPreset.thisMonth:
              _startDate = DateTime(now.year, now.month, 1);
              _endDate = DateTime(now.year, now.month + 1, 0);
              break;
            case OrderDateFilterPreset.custom:
              break;
          }
        });
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: selected ? Theme.of(context).colorScheme.primary : null,
      ),
      side: BorderSide(
        color: selected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
            : Theme.of(context).dividerColor.withValues(alpha: 0.2),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = (isStart ? _startDate : _endDate) ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      if (isStart) {
        _startDate = DateTime(picked.year, picked.month, picked.day);
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = DateTime(picked.year, picked.month, picked.day);
        if (_startDate != null && _startDate!.isAfter(_endDate!)) {
          _startDate = _endDate;
        }
      }
      _selectedPreset = OrderDateFilterPreset.custom;
    });
  }

  void _apply() {
    widget.controller.updateInvoiceFilter(_invoiceController.text.trim());

    if (_startDate == null && _endDate == null) {
      widget.controller.clearDateFilter();
    } else if (_selectedPreset != null &&
        _selectedPreset != OrderDateFilterPreset.custom) {
      widget.controller.applyDatePreset(_selectedPreset!);
    } else {
      widget.controller.setCustomDateRange(_startDate, _endDate);
    }

    Get.back<void>();
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'select_date'.tr;
    }
    return _dateFormat.format(value);
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
