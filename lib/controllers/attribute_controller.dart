import 'package:get/get.dart';
import 'package:abpos/data/repositories/attribute_repository.dart';
import 'package:abpos/models/attribute.dart';
import 'package:abpos/models/attribute_value.dart';

class AttributeController extends GetxController {
  final AttributeRepository _repository = AttributeRepository();
  final RxList<Attribute> attributes = <Attribute>[].obs;
  final RxList<AttributeValue> values = <AttributeValue>[].obs;
  final RxInt selectedAttributeId = RxInt(-1);
  final RxString searchQuery = ''.obs;

  List<Attribute> get filteredAttributes {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return attributes;
    return attributes.where((a) {
      return a.name.toLowerCase().contains(query) ||
          a.type.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadAttributes();
  }

  Future<void> loadAttributes() async {
    final items = await _repository.findAll();
    attributes.assignAll(items);
  }

  Future<void> selectAttribute(int id) async {
    selectedAttributeId.value = id;
    final items = await _repository.findValuesByAttributeId(id);
    values.assignAll(items);
  }

  Future<List<AttributeValue>> loadValuesForAttribute(int id) {
    return _repository.findValuesByAttributeId(id);
  }

  Future<int> addAttribute(Attribute attribute) async {
    final id = await _repository.insert(attribute);
    await loadAttributes();
    return id;
  }

  Future<void> updateAttribute(Attribute attribute) async {
    await _repository.update(attribute);
    await loadAttributes();
  }

  Future<void> deleteAttribute(int id) async {
    await _repository.delete(id);
    await loadAttributes();
    if (selectedAttributeId.value == id) {
      selectedAttributeId.value = -1;
      values.clear();
    }
  }

  Future<void> addAttributeValue(AttributeValue value) async {
    await _repository.insertValue(value);
    if (selectedAttributeId.value == value.attributeId) {
      await selectAttribute(value.attributeId);
    }
  }

  Future<void> updateAttributeValue(AttributeValue value) async {
    await _repository.updateValue(value);
    if (selectedAttributeId.value == value.attributeId) {
      await selectAttribute(value.attributeId);
    }
  }

  Future<void> deleteAttributeValue(int id) async {
    await _repository.deleteValue(id);
    if (selectedAttributeId.value >= 0) {
      await selectAttribute(selectedAttributeId.value);
    }
  }

  Future<void> saveAttributeWithValues({
    required Attribute attribute,
    required List<AttributeValue> values,
    required List<int> deletedValueIds,
  }) async {
    final now = DateTime.now().toIso8601String();
    final attributeId = attribute.id == null
        ? await _repository.insert(
            Attribute(
              sellerId: attribute.sellerId,
              name: attribute.name,
              type: attribute.type,
              createdAt: now,
              updatedAt: now,
            ),
          )
        : attribute.id!;

    if (attribute.id != null) {
      await _repository.update(
        Attribute(
          id: attribute.id,
          sellerId: attribute.sellerId,
          name: attribute.name,
          type: attribute.type,
          createdAt: attribute.createdAt,
          updatedAt: now,
        ),
      );
    }

    for (final id in deletedValueIds) {
      await _repository.deleteValue(id);
    }

    for (final value in values) {
      final cleanValue = value.value.trim();
      if (cleanValue.isEmpty) continue;

      final nextValue = AttributeValue(
        id: value.id,
        attributeId: attributeId,
        value: cleanValue,
        colorCode: value.colorCode?.trim().isEmpty == true
            ? null
            : value.colorCode?.trim(),
        createdAt: value.createdAt ?? now,
        updatedAt: now,
      );

      if (value.id == null) {
        await _repository.insertValue(nextValue);
      } else {
        await _repository.updateValue(nextValue);
      }
    }

    await loadAttributes();
    if (selectedAttributeId.value == attributeId) {
      await selectAttribute(attributeId);
    }
  }
}
