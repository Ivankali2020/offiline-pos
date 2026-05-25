import 'package:abpos/controllers/import_controller.dart';
import 'package:abpos/models/import_log.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// ---------------------------------------------------------------------------
// Import type UI config
// ---------------------------------------------------------------------------
class _TypeConfig {
  const _TypeConfig({
    required this.type,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
  final ImportType type;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
}

const _typeConfigs = <_TypeConfig>[
  _TypeConfig(
    type: ImportType.products,
    icon: LucideIcons.package,
    color: Color(0xFF2563EB),
    title: 'Products',
    subtitle:
        'name, sku, sell_price, buy_price, stock_quantity, category_name, brand_name, is_active',
  ),
  _TypeConfig(
    type: ImportType.categories,
    icon: LucideIcons.layoutGrid,
    color: Color(0xFF7C3AED),
    title: 'Categories',
    subtitle: 'name, description, is_sub_category (0 or 1)',
  ),
  _TypeConfig(
    type: ImportType.brands,
    icon: LucideIcons.tag,
    color: Color(0xFF0F766E),
    title: 'Brands',
    subtitle: 'name, description',
  ),
  _TypeConfig(
    type: ImportType.expenseCategories,
    icon: LucideIcons.folderOpen,
    color: Color(0xFFD97706),
    title: 'Expense Categories',
    subtitle: 'name, icon',
  ),
  _TypeConfig(
    type: ImportType.expenses,
    icon: LucideIcons.receiptText,
    color: Color(0xFFDC2626),
    title: 'Expenses',
    subtitle:
        'category_name, amount, description, payment_method, date (YYYY-MM-DD)',
  ),
];

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------
class ImportPage extends StatelessWidget {
  const ImportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ImportController());

    return AppScaffold(
      title: 'Import Data',
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: const CustomAppBar(
        title: 'Import Data',
        subtitle: 'Bulk-import your data from CSV files.',
      ),
      body: Obx(() {
        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                Get.find<ImportController>();
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  const _HeroCard(),
                  const SizedBox(height: 16),
                  ..._typeConfigs.map(
                    (cfg) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ImportCard(config: cfg, controller: controller),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (controller.lastResult.value != null) ...[
                    _ResultCard(log: controller.lastResult.value!),
                    const SizedBox(height: 20),
                  ],
                  _SectionHeader(
                    title: 'Import History',
                    subtitle:
                        'Recent CSV import operations and row-level results.',
                  ),
                  const SizedBox(height: 10),
                  if (controller.history.isEmpty)
                    const _EmptyCard(message: 'No imports yet.')
                  else
                    ...controller.history.asMap().entries.map((entry) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom:
                              entry.key == controller.history.length - 1
                                  ? 0
                                  : 10,
                        ),
                        child: _HistoryTile(log: entry.value),
                      );
                    }),
                ],
              ),
            ),
            if (controller.isBusy.value)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.14),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero card
// ---------------------------------------------------------------------------
class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF1F2937)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              LucideIcons.fileUp,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Bulk Import',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Download a sample CSV, fill in your data, then import it here.\n'
            'Products are updated if a matching name or SKU already exists.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.80),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Per-type import card
// ---------------------------------------------------------------------------
class _ImportCard extends StatelessWidget {
  const _ImportCard({required this.config, required this.controller});
  final _TypeConfig config;
  final ImportController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: config.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(config.icon, color: config.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  config.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                // Single row — 3 equal-width buttons
                Row(
                  children: [
                    // 1. Share sample via share sheet
                    Expanded(
                      child: _SmallButton(
                        icon: LucideIcons.share2,
                        label: 'Share',
                        color: config.color,
                        outlined: true,
                        onPressed: controller.isBusy.value
                            ? null
                            : () => controller.downloadSample(config.type),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 2. Save CSV directly to Downloads folder
                    Expanded(
                      child: _SmallButton(
                        icon: LucideIcons.folderDown,
                        label: 'Download',
                        color: const Color(0xFF0F766E),
                        outlined: true,
                        onPressed: controller.isBusy.value
                            ? null
                            : () => controller.saveToDownloads(config.type),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 3. Pick a CSV file and run import
                    Expanded(
                      child: _SmallButton(
                        icon: LucideIcons.upload,
                        label: 'Import',
                        color: config.color,
                        outlined: false,
                        onPressed: controller.isBusy.value
                            ? null
                            : () => controller.runImport(config.type),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Result card (shown after import)
// ---------------------------------------------------------------------------
class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.log});
  final ImportLog log;

  @override
  Widget build(BuildContext context) {
    final isOk = log.status == 'completed';
    final accent = isOk ? const Color(0xFF0F766E) : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOk ? LucideIcons.checkCircle : LucideIcons.alertCircle,
                color: accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isOk ? 'Import Complete' : 'Import Finished with Issues',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _statRow('Type', log.importType),
          _statRow('Total rows', '${log.totalRows}'),
          _statRow('Successful', '${log.successfulRows}'),
          if (log.failedRows > 0) _statRow('Failed / Skipped', '${log.failedRows}'),
          if (log.errorMessage != null && log.errorMessage!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              log.errorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
          Text(value, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small Button Widget for Import Cards
// ---------------------------------------------------------------------------
class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.outlined,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: onPressed != null
                ? color.withValues(alpha: 0.5)
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
            width: 1.2,
          ),
          foregroundColor: color,
          disabledForegroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
          backgroundColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: onPressed != null
                  ? color
                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade400),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: onPressed != null
                    ? color
                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade400),
              ),
            ),
          ],
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
          disabledForegroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty card
// ---------------------------------------------------------------------------
class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// History tile
// ---------------------------------------------------------------------------
class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.log});
  final ImportLog log;

  static final DateFormat _fmt = DateFormat('dd MMM yyyy • hh:mm a');

  IconData _iconFor(String type) => switch (type) {
    'products' => LucideIcons.package,
    'categories' => LucideIcons.layoutGrid,
    'brands' => LucideIcons.tag,
    'expense_categories' => LucideIcons.folderOpen,
    'expenses' => LucideIcons.receiptText,
    _ => LucideIcons.fileText,
  };

  Color _colorFor(String type) => switch (type) {
    'products' => const Color(0xFF2563EB),
    'categories' => const Color(0xFF7C3AED),
    'brands' => const Color(0xFF0F766E),
    'expense_categories' => const Color(0xFFD97706),
    'expenses' => const Color(0xFFDC2626),
    _ => const Color(0xFF6B7280),
  };

  String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return _fmt.format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final isOk = log.status == 'completed';
    final color = _colorFor(log.importType);
    final statusColor = isOk ? const Color(0xFF0F766E) : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconFor(log.importType), size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.fileName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${log.importType.replaceAll('_', ' ')} • ${_formatDate(log.completedAt ?? log.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${log.successfulRows} / ${log.totalRows} rows ok'
                  '${log.failedRows > 0 ? '  •  ${log.failedRows} skipped' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
                if (log.errorMessage != null &&
                    log.errorMessage!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    log.errorMessage!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isOk ? 'done' : 'issues',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
