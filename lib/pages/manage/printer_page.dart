import 'dart:io';
import 'dart:typed_data';

import 'package:abpos/controllers/printer_controller.dart';
import 'package:abpos/controllers/settings_controller.dart';
import 'package:abpos/models/printer.dart';
import 'package:abpos/services/receipt_printer_utils.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';
import 'package:abpos/widgets/form/custom_dropdown_field.dart';
import 'package:abpos/widgets/form/custom_text_field.dart';
import 'package:abpos/widgets/form/custom_form_sheet.dart';
import 'package:abpos/widgets/form/form_action_buttons.dart';
import 'package:abpos/widgets/thermal_receipt_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:screenshot/screenshot.dart';

class PrinterPage extends StatefulWidget {
  const PrinterPage({super.key});

  @override
  State<PrinterPage> createState() => _PrinterPageState();
}

class _PrinterPageState extends State<PrinterPage> {
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PrinterController>();

    return AppScaffold(
      title: 'printers'.tr,
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: CustomAppBar(
        title: 'printers'.tr,
        subtitle: 'manage_printers_subtitle'.tr,
        leadingIcon: LucideIcons.menu,
        titleWidget: _showSearch
            ? _SearchField(
                controller: _searchController,
                hintText: 'search_printers'.tr,
                onChanged: (value) => controller.searchQuery.value = value,
                onClear: () {
                  _searchController.clear();
                  controller.searchQuery.value = '';
                },
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? LucideIcons.x : LucideIcons.search,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              setState(() {
                if (_showSearch) {
                  _searchController.clear();
                  controller.searchQuery.value = '';
                }
                _showSearch = !_showSearch;
              });
            },
          ),
        ],
      ),
      body: Obx(() {
        final allPrinters = controller.printers.toList(growable: false);
        final printers = controller.filteredPrinters;
        // final defaultCount =
        //     allPrinters.where((p) => p.isDefault).length;
        // final connectedCount =
        //     allPrinters.where((p) => (p.address ?? '').trim().isNotEmpty).length;
        final isSearching = controller.searchQuery.value.trim().isNotEmpty;

        if (allPrinters.isEmpty) {
          return _EmptyPrinters(
            onCreate: () => _showPrinterSheet(context),
            isSearching: false,
          );
        }

        if (printers.isEmpty) {
          return _EmptyPrinters(
            onCreate: () => _showPrinterSheet(context),
            isSearching: isSearching,
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadPrinters,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              // _PrinterOverviewCard(
              //   visibleCount: printers.length,
              //   totalCount: allPrinters.length,
              //   defaultCount: defaultCount,
              //   connectedCount: connectedCount,
              // ),
              // const SizedBox(height: 14),
              ...printers.asMap().entries.map((entry) {
                final index = entry.key;
                final printer = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == printers.length - 1 ? 0 : 12,
                  ),
                  child: _PrinterCard(
                    printer: printer,
                    dateFormat: _dateFormat,
                    onEdit: () =>
                        _showPrinterSheet(context, printer: printer),
                    onDelete: () => _confirmDelete(context, printer),
                    onSetDefault: () => _setDefault(printer),
                    onTestPrint: () => _testPrint(context, printer),
                  ),
                );
              }),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPrinterSheet(context),
        icon: const Icon(LucideIcons.plus),
        label: Text('add_printer'.tr),
      ),
    );
  }

  void _showPrinterSheet(BuildContext context, {Printer? printer}) {
    final controller = Get.find<PrinterController>();
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: printer?.name);
    final addressController = TextEditingController(text: printer?.address);
    String? selectedType = printer?.type;
    bool isDefault = printer?.isDefault ?? false;

    Get.bottomSheet(
      isScrollControlled: true,
      CustomFormSheet(
        title: printer == null ? 'add_printer'.tr : 'edit_printer'.tr,
        subtitle: 'printer_sheet_subtitle'.tr,
        child: Form(
          key: formKey,
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                children: [
                  CustomTextField(
                    controller: nameController,
                    label: 'name'.tr,
                    isRequired: true,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'name_required'.tr
                        : null,
                  ),
                  const SizedBox(height: 14),
                  CustomDropdownField<String>(
                    value: selectedType,
                    label: 'printer_type'.tr,
                    hint: Text('select_printer_type'.tr),
                    items: const [
                      DropdownMenuItem(
                        value: 'bluetooth',
                        child: Text('Bluetooth'),
                      ),
                      DropdownMenuItem(value: 'usb', child: Text('USB')),
                      DropdownMenuItem(value: 'wifi', child: Text('Wi-Fi')),
                      DropdownMenuItem(
                        value: 'network',
                        child: Text('Network'),
                      ),
                    ],
                    onChanged: (value) {
                      setSheetState(() => selectedType = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: addressController,
                    label: 'printer_address'.tr,
                  ),
                  const SizedBox(height: 14),
                  _DefaultToggle(
                    value: isDefault,
                    onChanged: (v) => setSheetState(() => isDefault = v),
                  ),
                  const SizedBox(height: 20),
                  FormActionButtons(
                    onConfirm: () async {
                      if (!formKey.currentState!.validate()) return;
                      final now = DateTime.now().toIso8601String();
                      final nextPrinter = Printer(
                        id: printer?.id,
                        name: nameController.text.trim(),
                        type: selectedType,
                        address: _blankToNull(addressController.text),
                        isDefault: isDefault,
                        createdAt: printer?.createdAt ?? now,
                        updatedAt: now,
                      );

                      if (printer == null) {
                        await controller.addPrinter(nextPrinter);
                      } else {
                        await controller.updatePrinter(nextPrinter);
                      }
                      Get.back();
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Printer printer) {
    final controller = Get.find<PrinterController>();
    final printerId = printer.id;
    if (printerId == null) return;

    Get.bottomSheet(
      CustomFormSheet(
        title: 'delete_printer'.tr,
        subtitle: 'delete_printer_subtitle'.tr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('delete_confirm_name'.tr.replaceAll('@name', printer.name)),
            const SizedBox(height: 20),
            FormActionButtons(
              confirmLabel: 'delete'.tr,
              isDestructive: true,
              onConfirm: () async {
                await controller.deletePrinter(printerId);
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setDefault(Printer printer) async {
    if (printer.id == null || printer.isDefault) return;
    final controller = Get.find<PrinterController>();
    await controller.setDefault(printer.id!);
    Get.snackbar(
      'default_printer_set'.tr,
      'default_printer_set_message'.tr.replaceAll('@name', printer.name),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _testPrint(BuildContext context, Printer printer) {
    final theme = Theme.of(context);

    Get.bottomSheet(
      isScrollControlled: true,
      _TestPrintSheet(
        printer: printer,
        theme: theme,
        onPrint: () => _sendTestPrint(context, printer),
      ),
    );
  }

  Future<void> _sendTestPrint(BuildContext context, Printer printer) async {
    final address = printer.address?.trim() ?? '';
    if (address.isEmpty) {
      Get.snackbar(
        'print_failed'.tr,
        'printer_no_address'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return;
    }

    // Parse host:port — default port 9100
    String host = address;
    int port = 9100;
    if (address.contains(':')) {
      final parts = address.split(':');
      host = parts[0];
      port = int.tryParse(parts[1]) ?? 9100;
    }

    final screenshotController = ScreenshotController();
    final settingsController = Get.find<SettingsController>();
    final settings = settingsController.settings.value;
    final storeName = settings?.storeName?.trim().isNotEmpty == true
        ? settings!.storeName!
        : 'AB POS';
    final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final receiptWidget = ThermalReceiptWidget(
      storeName: storeName,
      receiptHeader: '--- ${'test_print'.tr} ---',
      receiptFooter: 'printer_test_footer'.tr,
      receiptPhone: settings?.receiptPhone ?? '',
      receiptAddress: settings?.receiptAddress ?? '',
      currencyCode: settings?.currencyCode ?? 'MMK',
      invoiceNumber: 'TEST-${DateTime.now().millisecondsSinceEpoch % 100000}',
      status: 'TEST',
      customerName: 'test_customer'.tr,
      customerPhone: '-',
      paymentName: 'CASH',
      dateFormatted: now,
      items: [
        const ReceiptItem(
          name: 'Sample Item A',
          quantity: 1,
          unitPrice: 5000,
          lineTotal: 5000,
        ),
        const ReceiptItem(
          name: 'Sample Item B',
          quantity: 2,
          unitPrice: 3000,
          lineTotal: 6000,
        ),
      ],
      subTotal: '11,000',
      deliveryFees: '0',
      taxLabel: 'tax_rate'.tr,
      taxPrice: '0',
      totalPrice: '11,000',
      givenAmount: '15,000',
      changeAmount: '4,000',
      note: 'printer_test_note'.tr,
      labelInvoice: 'receipt_label_invoice'.tr,
      labelStatus: 'receipt_label_status'.tr,
      labelCustomer: 'receipt_label_customer'.tr,
      labelPhone: 'receipt_label_phone'.tr,
      labelItems: 'receipt_label_items'.tr,
      labelNoItems: 'receipt_label_no_items'.tr,
      labelSubtotal: 'receipt_label_subtotal'.tr,
      labelDelivery: 'receipt_label_delivery'.tr,
      labelTotal: 'receipt_label_total'.tr,
      labelPaid: 'receipt_label_paid'.tr,
      labelChange: 'receipt_label_change'.tr,
      labelPaidBy: 'receipt_label_paid_by'.tr,
      labelNote: 'receipt_label_note'.tr,
      labelThankYou: 'receipt_label_thank_you'.tr,
    );

    try {
      Get.snackbar(
        'test_print_sending'.tr,
        'test_print_sending_message'.tr.replaceAll('@name', printer.name),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      final Uint8List imageBytes =
          await screenshotController.captureFromLongWidget(
        receiptWidget,
        pixelRatio: 1.0,
        delay: const Duration(milliseconds: 100),
      );

      if (imageBytes.isEmpty) {
        throw Exception('Screenshot capture returned empty data');
      }

      final payload = await compileReceiptPayload(imageBytes);

      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
      );
      socket.add(payload);
      await socket.flush();
      await socket.close();

      Get.snackbar(
        'test_print_sent'.tr,
        'test_print_sent_message'.tr.replaceAll('@name', printer.name),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade700,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('Test print error: $e');
      Get.snackbar(
        'print_failed'.tr,
        '$e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

// ──────────────────────────────────────────────────
// Test Print Bottom Sheet
// ──────────────────────────────────────────────────

class _TestPrintSheet extends StatefulWidget {
  const _TestPrintSheet({
    required this.printer,
    required this.theme,
    required this.onPrint,
  });

  final Printer printer;
  final ThemeData theme;
  final Future<void> Function() onPrint;

  @override
  State<_TestPrintSheet> createState() => _TestPrintSheetState();
}

class _TestPrintSheetState extends State<_TestPrintSheet> {
  bool _isPrinting = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final printer = widget.printer;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'test_print'.tr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'test_print_subtitle'.tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.72,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sample receipt preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'AB POS',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '--- ${'test_print'.tr} ---',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const Divider(height: 20),
                    _receiptRow('printer_name_label'.tr, printer.name),
                    _receiptRow('printer_type'.tr, printer.type ?? '-'),
                    _receiptRow(
                      'printer_address'.tr,
                      printer.address ?? '-',
                    ),
                    _receiptRow(
                      'is_default'.tr,
                      printer.isDefault ? 'yes'.tr : 'no_label'.tr,
                    ),
                    const Divider(height: 20),
                    _receiptRow('sample_item'.tr, '1 x 5,000'),
                    _receiptRow('sample_item_2'.tr, '2 x 3,000'),
                    const Divider(height: 20),
                    _receiptRow('total'.tr, '11,000 MMK'),
                    const SizedBox(height: 12),
                    const Text(
                      '*** SAMPLE RECEIPT ***',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Printer info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.printer,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            printer.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (printer.address != null)
                            Text(
                              printer.address!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (printer.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'default'.tr,
                          style: const TextStyle(
                            color: Color(0xFF059669),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isPrinting ? null : () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'close'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isPrinting
                          ? null
                          : () async {
                              setState(() => _isPrinting = true);
                              try {
                                Get.back();
                                await widget.onPrint();
                              } finally {
                                if (mounted) {
                                  setState(() => _isPrinting = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: _isPrinting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(LucideIcons.printer, size: 18),
                      label: Text(
                        _isPrinting ? 'printing'.tr : 'print'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// Overview Card
// ──────────────────────────────────────────────────

// class _PrinterOverviewCard extends StatelessWidget {
//   const _PrinterOverviewCard({
//     required this.visibleCount,
//     required this.totalCount,
//     required this.defaultCount,
//     required this.connectedCount,
//   });

//   final int visibleCount;
//   final int totalCount;
//   final int defaultCount;
//   final int connectedCount;

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(22),
//         gradient: LinearGradient(
//           colors: [
//             const Color(0xFF6366F1),
//             Color.alphaBlend(
//               Colors.white.withValues(alpha: 0.10),
//               const Color(0xFF6366F1),
//             ),
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: const Color(0xFF6366F1).withValues(alpha: 0.18),
//             blurRadius: 18,
//             offset: const Offset(0, 10),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'printer_overview'.tr,
//             style: theme.textTheme.titleLarge?.copyWith(
//               color: Colors.white,
//               fontWeight: FontWeight.w900,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             'printers_in_view'.tr.replaceAll('@count', '$visibleCount'),
//             style: theme.textTheme.bodyMedium?.copyWith(
//               color: Colors.white.withValues(alpha: 0.84),
//             ),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(
//                 child: _PrinterOverviewTile(
//                   label: 'total'.tr,
//                   value: '$totalCount',
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: _PrinterOverviewTile(
//                   label: 'default'.tr,
//                   value: '$defaultCount',
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: _PrinterOverviewTile(
//                   label: 'with_address'.tr,
//                   value: '$connectedCount',
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _PrinterOverviewTile extends StatelessWidget {
//   const _PrinterOverviewTile({required this.label, required this.value});

//   final String label;
//   final String value;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       decoration: BoxDecoration(
//         color: Colors.white.withValues(alpha: 0.13),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               color: Colors.white70,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             value,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.w900,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// ──────────────────────────────────────────────────
// Printer Card
// ──────────────────────────────────────────────────

class _PrinterCard extends StatelessWidget {
  const _PrinterCard({
    required this.printer,
    required this.dateFormat,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
    required this.onTestPrint,
  });

  final Printer printer;
  final DateFormat dateFormat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;
  final VoidCallback onTestPrint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = printer.type?.trim() ?? '';
    final address = printer.address?.trim() ?? '';
    final updatedAt = printer.updatedAt == null
        ? null
        : DateTime.tryParse(printer.updatedAt!);
    final updatedLabel = updatedAt == null
        ? 'no_recent_update'.tr
        : 'updated_at_date'
            .tr
            .replaceAll('@date', dateFormat.format(updatedAt));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onEdit,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: printer.isDefault
                  ? const Color(0xFF059669).withValues(alpha: 0.30)
                  : theme.dividerColor.withValues(alpha: 0.10),
              width: printer.isDefault ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: printer.isDefault
                          ? const Color(0xFF059669).withValues(alpha: 0.12)
                          : const Color(0xFF6366F1).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      LucideIcons.printer,
                      color: printer.isDefault
                          ? const Color(0xFF059669)
                          : const Color(0xFF6366F1),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                printer.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (printer.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669).withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      LucideIcons.checkCircle2,
                                      size: 12,
                                      color: Color(0xFF059669),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'default'.tr,
                                      style: const TextStyle(
                                        color: Color(0xFF059669),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          updatedLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (type.isNotEmpty)
                    _PrinterChip(
                      icon: _typeIcon(type),
                      label: _typeLabel(type),
                    ),
                  if (address.isNotEmpty)
                    _PrinterChip(
                      icon: LucideIcons.mapPin,
                      label: address,
                    ),
                ],
              ),

              const SizedBox(height: 14),

              // Action buttons row
              Row(
                children: [
                  if (!printer.isDefault)
                    _SmallActionButton(
                      icon: LucideIcons.star,
                      label: 'set_default'.tr,
                      color: const Color(0xFFF59E0B),
                      onTap: onSetDefault,
                    ),
                  if (!printer.isDefault) const SizedBox(width: 8),
                  _SmallActionButton(
                    icon: LucideIcons.printerCheck,
                    label: 'test_print'.tr,
                    color: const Color(0xFF6366F1),
                    onTap: onTestPrint,
                  ),
                  const Spacer(),
                  _ActionIconButton(
                    tooltip: 'edit_printer_tooltip'.tr,
                    icon: LucideIcons.pencil,
                    color: theme.colorScheme.primary,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.10),
                    onPressed: onEdit,
                  ),
                  const SizedBox(width: 6),
                  _ActionIconButton(
                    tooltip: 'delete_printer_tooltip'.tr,
                    icon: LucideIcons.trash2,
                    color: Colors.red,
                    backgroundColor: Colors.red.withValues(alpha: 0.08),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bluetooth':
        return LucideIcons.bluetooth;
      case 'usb':
        return LucideIcons.usb;
      case 'wifi':
        return LucideIcons.wifi;
      case 'network':
        return LucideIcons.network;
      default:
        return LucideIcons.printer;
    }
  }

  String _typeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'bluetooth':
        return 'Bluetooth';
      case 'usb':
        return 'USB';
      case 'wifi':
        return 'Wi-Fi';
      case 'network':
        return 'Network';
      default:
        return type;
    }
  }
}

// ──────────────────────────────────────────────────
// Small action button (set default, test print)
// ──────────────────────────────────────────────────

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// Default toggle
// ──────────────────────────────────────────────────

class _DefaultToggle extends StatelessWidget {
  const _DefaultToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: value
            ? const Color(0xFF059669).withValues(alpha: 0.06)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? const Color(0xFF059669).withValues(alpha: 0.20)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(
            value ? LucideIcons.checkCircle2 : LucideIcons.circle,
            size: 20,
            color: value ? const Color(0xFF059669) : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'set_as_default'.tr,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'default_printer_hint'.tr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF059669),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// Shared widgets
// ──────────────────────────────────────────────────

class _PrinterChip extends StatelessWidget {
  const _PrinterChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: theme.colorScheme.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _EmptyPrinters extends StatelessWidget {
  const _EmptyPrinters({required this.onCreate, required this.isSearching});

  final VoidCallback onCreate;
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching ? LucideIcons.searchX : LucideIcons.printer,
                size: 30,
                color: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'no_printers_found'.tr : 'no_printers_yet'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'search_printer_empty_subtitle'.tr
                  : 'printers_empty_subtitle'.tr,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.72,
                ),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            if (isSearching)
              OutlinedButton(
                onPressed: onCreate,
                child: Text('add_printer'.tr),
              )
            else
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(LucideIcons.plus, size: 16),
                label: Text('add_printer'.tr),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.black),
        cursorColor: Colors.black,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(LucideIcons.search, color: Colors.black54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          suffixIcon: IconButton(
            icon: const Icon(LucideIcons.x, color: Colors.black54),
            onPressed: onClear,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
