import 'package:abpos/data/repositories/supplier_repository.dart';
import 'package:abpos/models/supplier.dart';
import 'package:get/get.dart';

class SupplierController extends GetxController {
  final SupplierRepository _repository = SupplierRepository();
  final RxList<Supplier> suppliers = <Supplier>[].obs;
  final RxString searchQuery = ''.obs;

  List<Supplier> get filteredSuppliers {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return suppliers;
    return suppliers.where((supplier) {
      final name = supplier.name.toLowerCase();
      final phone = supplier.phone?.toLowerCase() ?? '';
      final email = supplier.email?.toLowerCase() ?? '';
      final address = supplier.address?.toLowerCase() ?? '';
      return name.contains(query) ||
          phone.contains(query) ||
          email.contains(query) ||
          address.contains(query);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadSuppliers();
  }

  Future<void> loadSuppliers() async {
    final items = await _repository.findAll();
    suppliers.assignAll(items);
  }

  Future<void> addSupplier(Supplier supplier) async {
    await _repository.insert(supplier);
    await loadSuppliers();
  }

  Future<void> updateSupplier(Supplier supplier) async {
    await _repository.update(supplier);
    await loadSuppliers();
  }

  Future<void> deleteSupplier(int id) async {
    await _repository.delete(id);
    await loadSuppliers();
  }
}
