import 'package:get/get.dart';
import 'package:abpos/data/repositories/brand_repository.dart';
import 'package:abpos/models/brand.dart';

class BrandController extends GetxController {
  final BrandRepository _repository = BrandRepository();
  final RxList<Brand> brands = <Brand>[].obs;
  final RxString searchQuery = ''.obs;

  List<Brand> get filteredBrands {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return brands;
    return brands.where((brand) {
      final name = brand.name.toLowerCase();
      final description = brand.description?.toLowerCase() ?? '';
      return name.contains(query) || description.contains(query);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadBrands();
  }

  Future<void> loadBrands() async {
    final items = await _repository.findAll();
    brands.assignAll(items);
  }

  Future<void> addBrand(Brand brand) async {
    await _repository.insert(brand);
    await loadBrands();
  }

  Future<void> updateBrand(Brand brand) async {
    await _repository.update(brand);
    await loadBrands();
  }

  Future<void> deleteBrand(int id) async {
    await _repository.delete(id);
    await loadBrands();
  }
}
