import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A consistent save/cancel button row for form sheets.
///
/// Matches the rounded corner design used across the app.
class FormActionButtons extends StatelessWidget {
  final String? cancelLabel;
  final String? confirmLabel;
  final VoidCallback? onCancel;
  final VoidCallback onConfirm;
  final bool isDestructive;
  final bool isLoading;
  final IconData? confirmIcon;

  const FormActionButtons({
    super.key,
    this.cancelLabel,
    this.confirmLabel,
    this.onCancel,
    required this.onConfirm,
    this.isDestructive = false,
    this.isLoading = false,
    this.confirmIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isLoading ? null : (onCancel ?? () => Get.back()),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              cancelLabel ?? 'cancel'.tr,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildConfirmButton(context),
        ),
      ],
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: isDestructive ? Colors.red : null,
      foregroundColor: isDestructive ? Colors.white : null,
    );

    final label = Text(
      confirmLabel ?? 'save'.tr,
      style: const TextStyle(fontWeight: FontWeight.w800),
    );

    if (isLoading) {
      return ElevatedButton(
        onPressed: null,
        style: style,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (confirmIcon != null) {
      return ElevatedButton.icon(
        onPressed: onConfirm,
        style: style,
        icon: Icon(confirmIcon, size: 18),
        label: label,
      );
    }

    return ElevatedButton(
      onPressed: onConfirm,
      style: style,
      child: label,
    );
  }
}
