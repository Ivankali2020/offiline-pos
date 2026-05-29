import 'package:abpos/controllers/supplier_controller.dart';
import 'package:abpos/models/supplier.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';
import 'package:abpos/widgets/form/custom_text_field.dart';
import 'package:abpos/widgets/form/custom_form_sheet.dart';
import 'package:abpos/widgets/form/form_action_buttons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SupplierPage extends StatefulWidget {
  const SupplierPage({super.key});

  @override
  State<SupplierPage> createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> {
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
    final controller = Get.find<SupplierController>();
    final bool isPicker = Get.arguments?['isPicker'] ?? false;

    return AppScaffold(
      title: 'suppliers'.tr,
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: CustomAppBar(
        title: 'suppliers'.tr,
        subtitle: 'manage_suppliers_subtitle'.tr,
        leadingIcon: isPicker ? LucideIcons.chevronLeft : LucideIcons.menu,
        onBackPressed: isPicker ? () => Get.back() : null,
        titleWidget: _showSearch
            ? _SearchField(
                controller: _searchController,
                hintText: 'search_suppliers'.tr,
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
        final allSuppliers = controller.suppliers.toList(growable: false);
        final suppliers = controller.filteredSuppliers;
        final phoneCount = allSuppliers
            .where((supplier) => (supplier.phone ?? '').trim().isNotEmpty)
            .length;
        final emailCount = allSuppliers
            .where((supplier) => (supplier.email ?? '').trim().isNotEmpty)
            .length;
        final isSearching = controller.searchQuery.value.trim().isNotEmpty;

        if (allSuppliers.isEmpty) {
          return _EmptySuppliers(
            onCreate: () => _showSupplierSheet(context),
            isSearching: false,
          );
        }

        if (suppliers.isEmpty) {
          return _EmptySuppliers(
            onCreate: () => _showSupplierSheet(context),
            isSearching: isSearching,
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadSuppliers,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _SupplierOverviewCard(
                visibleCount: suppliers.length,
                totalCount: allSuppliers.length,
                phoneCount: phoneCount,
                emailCount: emailCount,
              ),
              const SizedBox(height: 14),
              ...suppliers.asMap().entries.map((entry) {
                final index = entry.key;
                final supplier = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == suppliers.length - 1 ? 0 : 12,
                  ),
                  child: _SupplierCard(
                    supplier: supplier,
                    dateFormat: _dateFormat,
                    pickerLabel: isPicker ? 'tap_to_select'.tr : null,
                    onTap: isPicker ? () => Get.back(result: supplier) : null,
                    onEdit: () =>
                        _showSupplierSheet(context, supplier: supplier),
                    onDelete: () => _confirmDelete(context, supplier),
                  ),
                );
              }),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSupplierSheet(context),
        icon: const Icon(LucideIcons.plus),
        label: Text('add_supplier'.tr),
      ),
    );
  }

  void _showSupplierSheet(BuildContext context, {Supplier? supplier}) {
    final controller = Get.find<SupplierController>();
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: supplier?.name);
    final phoneController = TextEditingController(text: supplier?.phone);
    final emailController = TextEditingController(text: supplier?.email);
    final addressController = TextEditingController(text: supplier?.address);

    Get.bottomSheet(
      isScrollControlled: true,
      CustomFormSheet(
        title: supplier == null ? 'add_supplier'.tr : 'edit_supplier'.tr,
        subtitle: 'supplier_sheet_subtitle'.tr,
        child: Form(
          key: formKey,
          child: Column(
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
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: phoneController,
                      label: 'phone'.tr,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: CustomTextField(
                      controller: emailController,
                      label: 'email'.tr,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: addressController,
                label: 'address_about'.tr,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              FormActionButtons(
                onConfirm: () async {
                  if (!formKey.currentState!.validate()) return;
                  final now = DateTime.now().toIso8601String();
                  final nextSupplier = Supplier(
                    id: supplier?.id,
                    name: nameController.text.trim(),
                    phone: _blankToNull(phoneController.text),
                    email: _blankToNull(emailController.text),
                    address: _blankToNull(addressController.text),
                    createdAt: supplier?.createdAt ?? now,
                    updatedAt: now,
                  );

                  if (supplier == null) {
                    await controller.addSupplier(nextSupplier);
                  } else {
                    await controller.updateSupplier(nextSupplier);
                  }
                  Get.back();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Supplier supplier) {
    final controller = Get.find<SupplierController>();
    final supplierId = supplier.id;
    if (supplierId == null) return;

    Get.bottomSheet(
      CustomFormSheet(
        title: 'delete_supplier'.tr,
        subtitle: 'delete_supplier_subtitle'.tr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('delete_confirm_name'.tr.replaceAll('@name', supplier.name)),
            const SizedBox(height: 20),
            FormActionButtons(
              confirmLabel: 'delete'.tr,
              isDestructive: true,
              onConfirm: () async {
                await controller.deleteSupplier(supplierId);
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _SupplierOverviewCard extends StatelessWidget {
  const _SupplierOverviewCard({
    required this.visibleCount,
    required this.totalCount,
    required this.phoneCount,
    required this.emailCount,
  });

  final int visibleCount;
  final int totalCount;
  final int phoneCount;
  final int emailCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            Color.alphaBlend(
              Colors.white.withValues(alpha: 0.10),
              theme.colorScheme.primary,
            ),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'supplier_overview'.tr,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'suppliers_in_view'.tr.replaceAll('@count', '$visibleCount'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SupplierOverviewTile(
                  label: 'total'.tr,
                  value: '$totalCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SupplierOverviewTile(
                  label: 'with_phone'.tr,
                  value: '$phoneCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SupplierOverviewTile(
                  label: 'with_email'.tr,
                  value: '$emailCount',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SupplierOverviewTile extends StatelessWidget {
  const _SupplierOverviewTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({
    required this.supplier,
    required this.onEdit,
    required this.onDelete,
    required this.dateFormat,
    this.onTap,
    this.pickerLabel,
  });

  final Supplier supplier;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final DateFormat dateFormat;
  final VoidCallback? onTap;
  final String? pickerLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phone = supplier.phone?.trim() ?? '';
    final email = supplier.email?.trim() ?? '';
    final address = supplier.address?.trim() ?? '';
    final updatedAt = supplier.updatedAt == null
        ? null
        : DateTime.tryParse(supplier.updatedAt!);
    final updatedLabel = updatedAt == null
        ? 'no_recent_update'.tr
        : 'updated_at_date'.tr.replaceAll('@date', dateFormat.format(updatedAt));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.10),
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
                      color: theme.colorScheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      LucideIcons.truck,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplier.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
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
                  _ActionIconButton(
                    tooltip: 'edit_supplier_tooltip'.tr,
                    icon: LucideIcons.pencil,
                    color: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.10,
                    ),
                    onPressed: onEdit,
                  ),
                  const SizedBox(width: 6),
                  _ActionIconButton(
                    tooltip: 'delete_supplier_tooltip'.tr,
                    icon: LucideIcons.trash2,
                    color: Colors.red,
                    backgroundColor: Colors.red.withValues(alpha: 0.08),
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (phone.isNotEmpty)
                    _SupplierChip(icon: LucideIcons.phone, label: phone),
                  if (email.isNotEmpty)
                    _SupplierChip(icon: LucideIcons.mail, label: email),
                  if (pickerLabel != null)
                    _SupplierChip(
                      icon: LucideIcons.mousePointerClick,
                      label: pickerLabel!,
                    ),
                ],
              ),
              if (address.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.35,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    address,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SupplierChip extends StatelessWidget {
  const _SupplierChip({required this.icon, required this.label});

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

class _EmptySuppliers extends StatelessWidget {
  const _EmptySuppliers({required this.onCreate, required this.isSearching});

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
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching ? LucideIcons.searchX : LucideIcons.truck,
                size: 30,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'no_suppliers_found'.tr : 'no_suppliers_yet'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'search_supplier_empty_subtitle'.tr
                  : 'suppliers_empty_subtitle'.tr,
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
                child: Text('add_supplier'.tr),
              )
            else
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(LucideIcons.plus, size: 16),
                label: Text('add_supplier'.tr),
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
