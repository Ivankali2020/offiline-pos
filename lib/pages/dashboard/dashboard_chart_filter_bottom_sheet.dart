import 'package:abpos/controllers/dashboard_controller.dart';
import 'package:abpos/widgets/app_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class DashboardChartFilterBottomSheet extends StatefulWidget {
  const DashboardChartFilterBottomSheet({super.key, required this.controller});

  final DashboardController controller;

  static Future<void> show(
    BuildContext context,
    DashboardController controller,
  ) {
    return AppBottomSheet.show<void>(
      context,
      title: 'filter_order_chart'.tr,
      subtitle: 'filter_order_chart_subtitle'.tr,
      trailing: TextButton(
        onPressed: () async {
          await controller.clearChartFilter();
          Get.back<void>();
        },
        child: Text('reset'.tr),
      ),
      child: DashboardChartFilterBottomSheet(controller: controller),
    );
  }

  @override
  State<DashboardChartFilterBottomSheet> createState() =>
      _DashboardChartFilterBottomSheetState();
}

class _DashboardChartFilterBottomSheetState
    extends State<DashboardChartFilterBottomSheet> {
  late DateTime? _startDate;
  late DateTime? _endDate;
  late DashboardDateFilterPreset? _selectedPreset;
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _startDate = widget.controller.chartStartDate.value;
    _endDate = widget.controller.chartEndDate.value;
    _selectedPreset = widget.controller.chartSelectedPreset.value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
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
            _buildPresetChip(DashboardDateFilterPreset.today, 'today'.tr),
            _buildPresetChip(DashboardDateFilterPreset.thisWeek, 'this_week'.tr),
            _buildPresetChip(DashboardDateFilterPreset.thisMonth, 'this_month'.tr),
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

  Widget _buildPresetChip(DashboardDateFilterPreset preset, String label) {
    final selected = _selectedPreset == preset;
    final theme = Theme.of(context);

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        setState(() {
          _selectedPreset = preset;
          switch (preset) {
            case DashboardDateFilterPreset.today:
              _startDate = today;
              _endDate = today;
              break;
            case DashboardDateFilterPreset.thisWeek:
              _startDate = today.subtract(Duration(days: now.weekday - 1));
              _endDate = _startDate!.add(const Duration(days: 6));
              break;
            case DashboardDateFilterPreset.thisMonth:
              _startDate = DateTime(now.year, now.month, 1);
              _endDate = DateTime(now.year, now.month + 1, 0);
              break;
            case DashboardDateFilterPreset.custom:
              break;
          }
        });
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.16),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: selected ? theme.colorScheme.primary : null,
      ),
      side: BorderSide(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.2)
            : theme.dividerColor.withValues(alpha: 0.2),
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
      _selectedPreset = DashboardDateFilterPreset.custom;
    });
  }

  Future<void> _apply() async {
    if (_startDate == null && _endDate == null) {
      await widget.controller.clearChartFilter();
    } else if (_selectedPreset != null &&
        _selectedPreset != DashboardDateFilterPreset.custom) {
      await widget.controller.applyChartDatePreset(_selectedPreset!);
    } else {
      await widget.controller.setCustomChartDateRange(_startDate, _endDate);
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
