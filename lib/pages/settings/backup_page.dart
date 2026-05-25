import 'package:abpos/controllers/backup_controller.dart';
import 'package:abpos/models/export_log.dart';
import 'package:abpos/models/import_log.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  final BackupController controller = Get.put(BackupController());
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy • hh:mm a');

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Backup & Restore',
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: const CustomAppBar(
        title: 'Backup & Restore',
        subtitle: 'Export your SQLite data, restore from backup, or reset the app.',
      ),
      body: Obx(
        () => Stack(
          children: [
            RefreshIndicator(
              onRefresh: controller.loadHistory,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  const _HeroCard(),
                  const SizedBox(height: 16),
                  _ActionCard(
                    icon: LucideIcons.download,
                    color: const Color(0xFF2563EB),
                    title: 'Export Backup',
                    subtitle: 'Copy the full SQLite database into a backup file and share it.',
                    actionLabel: 'Export',
                    onPressed: controller.isBusy.value ? null : _exportBackup,
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: LucideIcons.upload,
                    color: const Color(0xFF0F766E),
                    title: 'Import Backup',
                    subtitle: 'Pick a backup database file and replace local data.',
                    actionLabel: 'Import',
                    onPressed: controller.isBusy.value ? null : _importBackup,
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: LucideIcons.trash2,
                    color: const Color(0xFFDC2626),
                    title: 'Reset All Data',
                    subtitle: 'Delete local data and recreate only required defaults.',
                    actionLabel: 'Reset',
                    isDanger: true,
                    onPressed: controller.isBusy.value ? null : _resetAllData,
                  ),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: 'Export History',
                    subtitle: 'Recent database backup files created on this device.',
                  ),
                  const SizedBox(height: 10),
                  if (controller.exports.isEmpty)
                    const _EmptyHistoryCard(
                      message: 'No backup exports yet.',
                    )
                  else
                    ...controller.exports.asMap().entries.map((entry) {
                      final item = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: entry.key == controller.exports.length - 1 ? 0 : 10,
                        ),
                        child: _ExportHistoryTile(
                          item: item,
                          dateFormat: _dateFormat,
                        ),
                      );
                    }),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: 'Import History',
                    subtitle: 'Recent restore operations and future CSV-ready import logs.',
                  ),
                  const SizedBox(height: 10),
                  if (controller.imports.isEmpty)
                    const _EmptyHistoryCard(
                      message: 'No import history yet.',
                    )
                  else
                    ...controller.imports.asMap().entries.map((entry) {
                      final item = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: entry.key == controller.imports.length - 1 ? 0 : 10,
                        ),
                        child: _ImportHistoryTile(
                          item: item,
                          dateFormat: _dateFormat,
                        ),
                      );
                    }),
                ],
              ),
            ),
            if (controller.isBusy.value)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.12),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportBackup() async {
    final box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin = box != null
        ? (box.localToGlobal(Offset.zero) & box.size)
        : null;

    try {
      final path = await controller.exportBackup();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          text: 'AB POS backup',
          subject: 'AB POS backup',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
      Get.snackbar(
        'Backup exported',
        'Backup file created successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'Export failed',
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _importBackup() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Import backup?'),
        content: const Text(
          'This will replace all current local data with the selected backup file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['db'],
    );
    final selectedPath = result?.files.single.path;
    if (selectedPath == null || selectedPath.trim().isEmpty) return;

    try {
      await controller.importBackup(selectedPath);
      Get.snackbar(
        'Backup imported',
        'Local data was restored successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'Import failed',
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _resetAllData() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text(
          'This deletes local data and recreates a fresh empty app with defaults only.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await controller.resetAllData();
      Get.snackbar(
        'Reset complete',
        'App data was reset to defaults successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'Reset failed',
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.storage_rounded, color: Colors.white),
          ),
          const SizedBox(height: 14),
          Text(
            'Protect your store data',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Export the full database for backup, restore another device from a backup file, or reset local data safely.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onPressed,
    this.isDanger = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onPressed;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: onPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: isDanger
                        ? color.withValues(alpha: 0.14)
                        : color.withValues(alpha: 0.10),
                    foregroundColor: color,
                  ),
                  child: Text(actionLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard({required this.message});

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
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _ExportHistoryTile extends StatelessWidget {
  const _ExportHistoryTile({
    required this.item,
    required this.dateFormat,
  });

  final ExportLog item;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return _HistoryTile(
      icon: LucideIcons.download,
      color: const Color(0xFF2563EB),
      title: item.fileName ?? 'Backup export',
      subtitle:
          '${item.exporter} • ${_formatDate(item.completedAt ?? item.createdAt)}',
      details: item.fileDisk,
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return dateFormat.format(parsed);
  }
}

class _ImportHistoryTile extends StatelessWidget {
  const _ImportHistoryTile({
    required this.item,
    required this.dateFormat,
  });

  final ImportLog item;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return _HistoryTile(
      icon: LucideIcons.upload,
      color: const Color(0xFF0F766E),
      title: item.fileName,
      subtitle:
          '${item.importType} • ${_formatDate(item.completedAt ?? item.createdAt)}',
      details: item.filePath,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: item.status == 'completed'
              ? const Color(0xFF0F766E).withValues(alpha: 0.10)
              : const Color(0xFFDC2626).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          item.status,
          style: TextStyle(
            color: item.status == 'completed'
                ? const Color(0xFF0F766E)
                : const Color(0xFFDC2626),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return dateFormat.format(parsed);
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.details,
    this.trailing,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String details;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
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
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  details,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}
