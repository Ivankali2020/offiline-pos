import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:abpos/controllers/settings_controller.dart';
import 'package:abpos/controllers/update_controller.dart';
import 'package:abpos/models/settings.dart';
import 'package:abpos/routes/app_routes.dart';
import 'package:abpos/widgets/app_bottom_sheet.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';
import 'package:abpos/widgets/form/custom_text_field.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _receiptPhoneController = TextEditingController();
  final TextEditingController _receiptAddressController =
      TextEditingController();
  final TextEditingController _currencyCodeController = TextEditingController();
  final TextEditingController _currencySymbolController =
      TextEditingController();
  final TextEditingController _taxRateController = TextEditingController();
  final TextEditingController _receiptHeaderController =
      TextEditingController();
  final TextEditingController _receiptFooterController =
      TextEditingController();

  Worker? _settingsWorker;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
    final controller = Get.find<SettingsController>();
    _settingsWorker = ever<Settings?>(controller.settings, (settings) {
      if (!mounted) return;
      _populateControllers(settings);
    });
  }

  void _loadCurrentSettings() {
    final controller = Get.find<SettingsController>();
    _populateControllers(controller.settings.value);
  }

  void _populateControllers(Settings? settings) {
    if (settings == null) return;

    _storeNameController.text = settings.storeName ?? '';
    _receiptPhoneController.text = settings.receiptPhone ?? '';
    _receiptAddressController.text = settings.receiptAddress ?? '';
    _currencyCodeController.text = settings.currencyCode;
    _currencySymbolController.text = settings.currencySymbol;
    _taxRateController.text = settings.taxRate.toStringAsFixed(2);
    _receiptHeaderController.text = settings.receiptHeader ?? '';
    _receiptFooterController.text = settings.receiptFooter ?? '';
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _receiptPhoneController.dispose();
    _receiptAddressController.dispose();
    _currencyCodeController.dispose();
    _currencySymbolController.dispose();
    _taxRateController.dispose();
    _receiptHeaderController.dispose();
    _receiptFooterController.dispose();
    _settingsWorker?.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = Get.find<SettingsController>();
    final currentSettings = controller.settings.value;

    final newSettings = Settings(
      id: currentSettings?.id,
      sellerId: currentSettings?.sellerId ?? 1,
      storeName: _storeNameController.text.trim(),
      receiptPhone: _receiptPhoneController.text.trim(),
      receiptAddress: _receiptAddressController.text.trim(),
      currencyCode: _currencyCodeController.text.trim(),
      currencySymbol: _currencySymbolController.text.trim(),
      taxRate: double.tryParse(_taxRateController.text) ?? 0.0,
      receiptHeader: _receiptHeaderController.text.trim(),
      receiptFooter: _receiptFooterController.text.trim(),
      defaultPaymentId: currentSettings?.defaultPaymentId,
      createdAt: currentSettings?.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
    );

    await controller.saveSettings(newSettings);
    Get.snackbar('success'.tr, 'saved_successfully'.tr);
  }

  void _showLanguageDialog() {
    final currentLocale = Get.locale ?? const Locale('en', 'US');
    final localeOptions = const [Locale('en', 'US'), Locale('my', 'MM')];

    AppBottomSheet.show<void>(
      context,
      title: 'language'.tr,
      subtitle: 'language_subtitle'.tr,
      child: Column(
        children: localeOptions.map((locale) {
          final isSelected = locale.languageCode == currentLocale.languageCode;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LanguageOptionTile(
              flag: locale.languageCode == 'en' ? '🇺🇸' : '🇲🇲',
              title: locale.languageCode == 'en' ? 'English' : 'Myanmar',
              subtitle: locale.languageCode == 'en'
                  ? 'english_subtitle'.tr
                  : 'myanmar_subtitle'.tr,
              isSelected: isSelected,
              onTap: () {
                Get.updateLocale(locale);
                Get.back<void>();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'settings'.tr,
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: CustomAppBar(
        title: 'settings'.tr,
        subtitle: 'settings_subtitle'.tr,
        leadingIcon: LucideIcons.settings,
        actions: [
          IconButton(
            icon: Icon(
              LucideIcons.languages,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: _showLanguageDialog,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0x14000000))),
          ),
          child: ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'save'.tr,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeroCard(),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'store_info'.tr,
                subtitle: 'store_info_subtitle'.tr,
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _storeNameController,
                      label: 'store_name'.tr,
                      isRequired: true,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'required_field'.tr
                          : null,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _receiptPhoneController,
                      label: 'receipt_phone'.tr,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _receiptAddressController,
                      label: 'receipt_address'.tr,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),

              // const SizedBox(height: 16),
              // _buildSectionCard(
              //   title: 'localization'.tr,
              //   subtitle:
              //       'Control how prices and tax are displayed on sales screens.',
              //   child: Column(
              //     children: [
              //       LayoutBuilder(
              //         builder: (context, constraints) {
              //           final isCompact = constraints.maxWidth < 640;
              //           final fields = [
              //             Expanded(
              //               child: CustomTextField(
              //                 controller: _currencyCodeController,
              //                 label: 'currency_code'.tr,
              //                 isRequired: true,
              //               ),
              //             ),
              //             const SizedBox(width: 14),
              //             Expanded(
              //               child: CustomTextField(
              //                 controller: _currencySymbolController,
              //                 label: 'currency_symbol'.tr,
              //                 isRequired: true,
              //               ),
              //             ),
              //           ];

              //           if (isCompact) {
              //             return Column(
              //               children: [
              //                 fields[0],
              //                 const SizedBox(height: 14),
              //                 fields[2],
              //               ],
              //             );
              //           }

              //           return Row(children: fields);
              //         },
              //       ),
              //       const SizedBox(height: 14),
              //       CustomTextField(
              //         controller: _taxRateController,
              //         label: 'tax_rate'.tr,
              //         keyboardType: TextInputType.number,
              //       ),
              //     ],
              //   ),
              // ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'receipt'.tr,
                subtitle: 'receipt_subtitle'.tr,
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _receiptHeaderController,
                      label: 'receipt_header'.tr,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _receiptFooterController,
                      label: 'receipt_footer'.tr,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'backup_restore'.tr,
                subtitle: 'backup_restore_subtitle'.tr,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.backup_table_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    'open_backup_tools'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text('open_backup_tools_subtitle'.tr),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Get.toNamed(AppRoutes.backup),
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'import_data'.tr,
                subtitle: 'import_data_subtitle'.tr,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.upload_file_rounded,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  title: Text(
                    'open_import_tools'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text('open_import_tools_subtitle'.tr),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Get.toNamed(AppRoutes.csvImport),
                ),
              ),
              const SizedBox(height: 16),
              _buildUpdateCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateCard() {
    final updateController = Get.find<UpdateController>();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'app_update'.tr,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'app_update_subtitle'.tr,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Obx(() {
                if (updateController.updateAvailable.value) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'update_available'.tr,
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
          const SizedBox(height: 18),
          Obx(() => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: updateController.updateAvailable.value
                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: updateController.isChecking.value
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child:
                              CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Icon(
                          Icons.system_update_rounded,
                          color: updateController.updateAvailable.value
                              ? const Color(0xFF10B981)
                              : Theme.of(context).colorScheme.primary,
                        ),
                ),
                title: Text(
                  'check_for_update'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${'current_version'.tr}: ${updateController.currentVersion.value}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  if (updateController.updateAvailable.value) {
                    updateController.showUpdateDialog();
                  } else {
                    updateController.checkForUpdate().then((_) {
                      updateController.showUpdateDialog();
                    });
                  }
                },
              )),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF1F2937)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'store_setup'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _storeNameController.text.trim().isEmpty
                ? 'settings'.tr
                : _storeNameController.text.trim(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'store_setup_subtitle'.tr,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String flag;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(flag, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.grey.shade400,
                    width: 1.6,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
