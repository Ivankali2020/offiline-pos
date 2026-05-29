import 'package:abpos/controllers/attribute_controller.dart';
import 'package:abpos/models/attribute.dart';
import 'package:abpos/routes/app_routes.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';
import 'package:abpos/widgets/form/custom_form_sheet.dart';
import 'package:abpos/widgets/form/form_action_buttons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AttributePage extends StatefulWidget {
  const AttributePage({super.key});

  @override
  State<AttributePage> createState() => _AttributePageState();
}

class _AttributePageState extends State<AttributePage> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AttributeController>();

    return AppScaffold(
      title: 'attributes'.tr,
      appBar: CustomAppBar(
        title: 'attributes'.tr,
        subtitle: 'manage_attributes_subtitle'.tr,
        titleWidget: _showSearch
            ? _SearchField(
                controller: _searchController,
                hintText: 'search_attributes'.tr,
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
        final attributes = controller.filteredAttributes;
        if (controller.attributes.isEmpty) {
          return _EmptyAttributes(onCreate: _openCreatePage);
        }
        if (attributes.isEmpty) {
          return Center(child: Text('no_attributes_match'.tr));
        }

        return RefreshIndicator(
          onRefresh: controller.loadAttributes,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: attributes.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final attribute = attributes[index];
              return _AttributeCard(
                attribute: attribute,
                onTap: () => _openEditPage(attribute),
                onEdit: () => _openEditPage(attribute),
                onDelete: () => _confirmDelete(context, attribute, controller),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreatePage,
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  static void _openCreatePage() {
    Get.toNamed(AppRoutes.attributeForm);
  }

  static void _openEditPage(Attribute attribute) {
    Get.toNamed(AppRoutes.attributeForm, arguments: attribute);
  }

  static void _confirmDelete(
    BuildContext context,
    Attribute attribute,
    AttributeController controller,
  ) {
    final attributeId = attribute.id;
    if (attributeId == null) return;

    Get.bottomSheet(
      CustomFormSheet(
        title: 'delete_attribute'.tr,
        subtitle: 'delete_attribute_subtitle'.tr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('delete_attribute_confirm'.trParams({'name': attribute.name})),
            const SizedBox(height: 20),
            FormActionButtons(
              confirmLabel: 'delete'.tr,
              isDestructive: true,
              onConfirm: () {
                controller.deleteAttribute(attributeId);
                Get.back();
              },
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



class _AttributeCard extends StatelessWidget {
  const _AttributeCard({
    required this.attribute,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Attribute attribute;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  LucideIcons.listTree,
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
                      attribute.name.trim().isEmpty
                          ? 'untitled_attribute'.tr
                          : attribute.name.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${'attribute_type'.tr}: ${attribute.type}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'edit'.tr,
                onPressed: onEdit,
                icon: const Icon(LucideIcons.pencil, size: 18),
              ),
              IconButton(
                tooltip: 'delete'.tr,
                onPressed: onDelete,
                icon: const Icon(
                  LucideIcons.trash2,
                  color: Colors.red,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyAttributes extends StatelessWidget {
  const _EmptyAttributes({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.listTree,
                color: theme.colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'no_attributes_found'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'no_attributes_subtitle'.tr,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.72,
                ),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text('add'.tr),
            ),
          ],
        ),
      ),
    );
  }
}


