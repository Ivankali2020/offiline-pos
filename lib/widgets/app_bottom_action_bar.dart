import 'package:flutter/material.dart';

class AppBottomActionBar extends StatelessWidget {
  const AppBottomActionBar({
    super.key,
    required this.actionLabel,
    required this.onPressed,
    this.summaryLabel,
    this.summaryValue,
    this.summaryValueColor,
    this.actionIcon,
  });

  final String actionLabel;
  final VoidCallback? onPressed;
  final String? summaryLabel;
  final String? summaryValue;
  final Color? summaryValueColor;
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSummary =
        summaryLabel?.trim().isNotEmpty == true ||
        summaryValue?.trim().isNotEmpty == true;

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
        child: hasSummary
            ? Row(
                children: [
                  Expanded(
                    child: _BottomActionSummary(
                      label: summaryLabel ?? '',
                      value: summaryValue ?? '',
                      valueColor:
                          summaryValueColor ?? theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: _buildButton(context)),
                ],
              )
            : _buildButton(context),
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
    );
    final label = Text(
      actionLabel,
      style: const TextStyle(fontWeight: FontWeight.w800),
    );

    if (actionIcon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        style: style,
        icon: Icon(actionIcon, size: 18),
        label: label,
      );
    }

    return ElevatedButton(onPressed: onPressed, style: style, child: label);
  }
}

class _BottomActionSummary extends StatelessWidget {
  const _BottomActionSummary({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
