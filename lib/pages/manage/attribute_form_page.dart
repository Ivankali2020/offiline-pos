import 'package:abpos/controllers/attribute_controller.dart';
import 'package:abpos/models/attribute.dart';
import 'package:abpos/models/attribute_value.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';
import 'package:abpos/widgets/form/custom_text_field.dart';
import 'package:abpos/widgets/form/form_action_buttons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AttributeFormPage extends StatefulWidget {
  const AttributeFormPage({super.key});

  @override
  State<AttributeFormPage> createState() => _AttributeFormPageState();
}

class _AttributeFormPageState extends State<AttributeFormPage> {
  static const _textType = 'text';
  static const _colorType = 'color';

  final _formKey = GlobalKey<FormState>();
  final AttributeController _controller = Get.find<AttributeController>();
  final TextEditingController _nameController = TextEditingController();
  final List<_ValueDraft> _valueDrafts = [];
  final List<int> _deletedValueIds = [];

  Attribute? _editingAttribute;
  String _selectedType = _textType;
  bool _isLoading = true;
  bool _isSaving = false;

  bool get _isEdit => _editingAttribute != null;

  @override
  void initState() {
    super.initState();
    _editingAttribute = Get.arguments as Attribute?;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final attribute = _editingAttribute;
    if (attribute != null) {
      _nameController.text = attribute.name.trim();
      _selectedType = attribute.type.trim().toLowerCase() == _colorType
          ? _colorType
          : _textType;

      final values = await _controller.loadValuesForAttribute(attribute.id!);
      _valueDrafts.addAll(values.map(_ValueDraft.fromValue));
    }

    if (_valueDrafts.isEmpty) {
      _valueDrafts.add(_ValueDraft.empty());
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final draft in _valueDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);
    final attribute = Attribute(
      id: _editingAttribute?.id,
      sellerId: _editingAttribute?.sellerId ?? 1,
      name: _nameController.text.trim(),
      type: _selectedType,
      createdAt: _editingAttribute?.createdAt,
      updatedAt: _editingAttribute?.updatedAt,
    );

    final values = _valueDrafts
        .map(
          (draft) => draft.toValue(
            attribute.id ?? 0,
            includeColorCode: _selectedType == _colorType,
          ),
        )
        .where((value) => value.value.trim().isNotEmpty)
        .toList();

    await _controller.saveAttributeWithValues(
      attribute: attribute,
      values: values,
      deletedValueIds: _deletedValueIds,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    Get.back();
    Get.snackbar('success'.tr, 'saved_successfully'.tr);
  }

  void _addValueRow() {
    setState(() => _valueDrafts.add(_ValueDraft.empty()));
  }

  void _removeValueRow(int index) {
    final draft = _valueDrafts.removeAt(index);
    if (draft.id != null) {
      _deletedValueIds.add(draft.id!);
    }
    draft.dispose();

    if (_valueDrafts.isEmpty) {
      _valueDrafts.add(_ValueDraft.empty());
    }
    setState(() {});
  }

  Future<void> _pickColor(_ValueDraft draft) async {
    final selected = await Get.bottomSheet<Color>(
      _ColorPickerSheet(initialColor: _parseColor(draft.colorController.text)),
      isScrollControlled: true,
    );

    if (selected == null) return;
    draft.colorController.text = _formatColor(selected);
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? 'edit_attribute'.tr : 'new_attribute'.tr;

    return AppScaffold(
      title: title,
      appBar: CustomAppBar(
        title: title,
        subtitle: 'attribute_form_subtitle'.tr,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
              ),
            ),
          ),
          child: FormActionButtons(
            confirmIcon: LucideIcons.save,
            isLoading: _isSaving,
            onConfirm: _save,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                children: [
                  _SectionCard(
                    title: 'attribute_details'.tr,
                    icon: LucideIcons.listTree,
                    child: Column(
                      children: [
                        CustomTextField(
                          controller: _nameController,
                          label: 'name'.tr,
                          isRequired: true,
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? 'required_field'.tr
                              : null,
                        ),
                        const SizedBox(height: 14),
                        _AttributeTypeRadioGroup(
                          selectedType: _selectedType,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _selectedType = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'attribute_values'.tr,
                    icon: LucideIcons.rows3,
                    trailing: IconButton(
                      tooltip: 'add'.tr,
                      onPressed: _addValueRow,
                      icon: const Icon(LucideIcons.plusCircle),
                    ),
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < _valueDrafts.length;
                          index++
                        )
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: index == _valueDrafts.length - 1 ? 0 : 12,
                            ),
                            child: _ValueEditorRow(
                              draft: _valueDrafts[index],
                              showColorCode: _selectedType == _colorType,
                              onPickColor: () =>
                                  _pickColor(_valueDrafts[index]),
                              onRemove: () => _removeValueRow(index),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ValueDraft {
  _ValueDraft({
    this.id,
    this.createdAt,
    required String value,
    required String colorCode,
  }) : valueController = TextEditingController(text: value),
       colorController = TextEditingController(text: colorCode);

  factory _ValueDraft.empty() {
    return _ValueDraft(value: '', colorCode: '');
  }

  factory _ValueDraft.fromValue(AttributeValue value) {
    return _ValueDraft(
      id: value.id,
      createdAt: value.createdAt,
      value: value.value,
      colorCode: value.colorCode ?? '',
    );
  }

  final int? id;
  final String? createdAt;
  final TextEditingController valueController;
  final TextEditingController colorController;

  AttributeValue toValue(int attributeId, {required bool includeColorCode}) {
    return AttributeValue(
      id: id,
      attributeId: attributeId,
      value: valueController.text.trim(),
      colorCode: includeColorCode ? colorController.text.trim() : null,
      createdAt: createdAt,
    );
  }

  void dispose() {
    valueController.dispose();
    colorController.dispose();
  }
}

String _formatColor(Color color) {
  final value = color.toARGB32() & 0xFFFFFF;
  return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

Color? _parseColor(String rawValue) {
  final value = rawValue.trim().replaceFirst('#', '');
  if (value.length != 6) return null;
  final colorInt = int.tryParse('FF$value', radix: 16);
  return colorInt == null ? null : Color(colorInt);
}

class _AttributeTypeRadioGroup extends StatelessWidget {
  const _AttributeTypeRadioGroup({
    required this.selectedType,
    required this.onChanged,
  });

  final String selectedType;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              'attribute_type'.tr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(
                  alpha: 0.72,
                ),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          RadioGroup<String>(
            groupValue: selectedType,
            onChanged: onChanged,
            child: Column(
              children: [
                RadioListTile<String>(
                  value: _AttributeFormPageState._textType,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('text'.tr),
                ),
                RadioListTile<String>(
                  value: _AttributeFormPageState._colorType,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('color'.tr),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ValueEditorRow extends StatelessWidget {
  const _ValueEditorRow({
    required this.draft,
    required this.showColorCode,
    required this.onPickColor,
    required this.onRemove,
  });

  final _ValueDraft draft;
  final bool showColorCode;
  final VoidCallback onPickColor;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: draft.valueController,
                  label: 'attribute_value'.tr,
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'delete'.tr,
                onPressed: onRemove,
                icon: const Icon(LucideIcons.trash2, color: Colors.red),
              ),
            ],
          ),
          if (showColorCode) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                InkWell(
                  onTap: onPickColor,
                  borderRadius: BorderRadius.circular(12),
                  child: _ColorPreview(controller: draft.colorController),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomTextField(
                    controller: draft.colorController,
                    label: 'color_code'.tr,
                    readOnly: true,
                    onTap: onPickColor,
                    suffixIcon: IconButton(
                      icon: const Icon(LucideIcons.palette, size: 18),
                      onPressed: onPickColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ColorPreview extends StatelessWidget {
  const _ColorPreview({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final color = _parseColor(value.text);
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color ?? Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.30),
            ),
          ),
          child: color == null
              ? const Icon(LucideIcons.palette, size: 18)
              : null,
        );
      },
    );
  }
}

class _ColorPickerSheet extends StatefulWidget {
  const _ColorPickerSheet({this.initialColor});

  final Color? initialColor;

  @override
  State<_ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<_ColorPickerSheet> {
  static const _colors = [
    Color(0xFF111827),
    Color(0xFF6B7280),
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFF59E0B),
    Color(0xFFEAB308),
    Color(0xFF84CC16),
    Color(0xFF22C55E),
    Color(0xFF14B8A6),
    Color(0xFF06B6D4),
    Color(0xFF3B82F6),
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFA855F7),
    Color(0xFFEC4899),
    Color(0xFFF43F5E),
  ];

  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor ?? _colors.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'color_code'.tr,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colors.map((color) {
                final isSelected =
                    color.toARGB32() == _selectedColor.toARGB32();
                return InkWell(
                  onTap: () => setState(() => _selectedColor = color),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.onSurface
                            : theme.dividerColor.withValues(alpha: 0.16),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            LucideIcons.check,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            FormActionButtons(
              onConfirm: () => Get.back(result: _selectedColor),
            ),
          ],
        ),
      ),
    );
  }
}
