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
      title: 'backup_restore'.tr,
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: CustomAppBar(
        title: 'backup_restore'.tr,
        subtitle: 'backup_restore_subtitle'.tr,
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
                    title: 'export_backup'.tr,
                    subtitle: 'export_backup_subtitle'.tr,
                    actionLabel: 'export_caps'.tr,
                    onPressed: controller.isBusy.value ? null : _exportBackup,
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: LucideIcons.upload,
                    color: const Color(0xFF0F766E),
                    title: 'import_backup'.tr,
                    subtitle: 'import_backup_subtitle'.tr,
                    actionLabel: 'import_caps'.tr,
                    onPressed: controller.isBusy.value ? null : _importBackup,
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: LucideIcons.trash2,
                    color: const Color(0xFFDC2626),
                    title: 'reset_all_data'.tr,
                    subtitle: 'reset_all_data_subtitle'.tr,
                    actionLabel: 'reset_caps'.tr,
                    isDanger: true,
                    onPressed: controller.isBusy.value ? null : _resetAllData,
                  ),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: 'export_history'.tr,
                    subtitle: 'export_history_subtitle'.tr,
                  ),
                  const SizedBox(height: 10),
                  if (controller.exports.isEmpty)
                    _EmptyHistoryCard(
                      message: 'no_backup_exports_yet'.tr,
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
                    title: 'import_history'.tr,
                    subtitle: 'import_history_subtitle'.tr,
                  ),
                  const SizedBox(height: 10),
                  if (controller.imports.isEmpty)
                    _EmptyHistoryCard(
                      message: 'no_import_history_yet'.tr,
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
        'backup_exported'.tr,
        'backup_file_created_success'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'export_failed'.tr,
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _importBackup() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('import_backup_confirm'.tr),
        content: Text(
          'import_backup_warning'.tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: Text('import_caps'.tr),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['db'],
    );
    final selectedPath = file?.path;
    if (selectedPath == null || selectedPath.trim().isEmpty) return;

    try {
      await controller.importBackup(selectedPath);
      Get.snackbar(
        'backup_imported'.tr,
        'local_data_restored_success'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'import_failed'.tr,
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _resetAllData() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('reset_all_data_confirm'.tr),
        content: Text(
          'reset_all_data_warning'.tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('reset_caps'.tr),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await controller.resetAllData();
      Get.snackbar(
        'reset_complete'.tr,
        'app_data_reset_success'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'reset_failed'.tr,
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
            'protect_store_data'.tr,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'protect_store_data_subtitle'.tr,
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
      title: item.fileName ?? 'backup_export'.tr,
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
