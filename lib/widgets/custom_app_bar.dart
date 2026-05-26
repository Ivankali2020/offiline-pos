import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.backgroundColor,
    this.onBackPressed,
    this.leadingIcon,
    this.showDrawerButton = false,
    this.titleWidget,
    this.actions,
    this.iconColor,
    this.actionIconColor,
  });

  final String title;
  final String? subtitle;
  final Color? backgroundColor;
  final VoidCallback? onBackPressed;
  final IconData? leadingIcon;
  final bool showDrawerButton;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Color? iconColor;
  final Color? actionIconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedIconColor = iconColor ?? theme.colorScheme.onSurface;
    final resolvedActionIconColor =
        actionIconColor ?? theme.colorScheme.primary;

    return AppBar(
      leading: IconButton(
        icon: Icon(
          showDrawerButton
              ? (leadingIcon ?? LucideIcons.settings)
              : LucideIcons.chevronLeft,
          color: resolvedIconColor,
        ),
        onPressed: showDrawerButton
            ? () => Scaffold.of(context).openDrawer()
            : (onBackPressed ?? Get.back),
      ),
      title:
          titleWidget ??
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (subtitle != null &&
                  subtitle!.isNotEmpty &&
                  MediaQuery.of(context).size.width >= 600)
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
          ),
      actions: actions,
      backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
      iconTheme: IconThemeData(color: resolvedIconColor),
      actionsIconTheme: IconThemeData(color: resolvedActionIconColor),
      elevation: 0,
      scrolledUnderElevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
