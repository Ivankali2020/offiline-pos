import 'package:abpos/data/repositories/printer_repository.dart';
import 'package:abpos/models/printer.dart';
import 'package:get/get.dart';

class PrinterController extends GetxController {
  final PrinterRepository _repository = PrinterRepository();
  final RxList<Printer> printers = <Printer>[].obs;
  final RxString searchQuery = ''.obs;

  List<Printer> get filteredPrinters {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return printers;
    return printers.where((printer) {
      final name = printer.name.toLowerCase();
      final type = printer.type?.toLowerCase() ?? '';
      final address = printer.address?.toLowerCase() ?? '';
      return name.contains(query) ||
          type.contains(query) ||
          address.contains(query);
    }).toList();
  }

  Printer? get defaultPrinter {
    try {
      return printers.firstWhere((p) => p.isDefault);
    } catch (_) {
      return null;
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadPrinters();
  }

  Future<void> loadPrinters() async {
    final items = await _repository.findAll();
    printers.assignAll(items);
  }

  Future<void> addPrinter(Printer printer) async {
    await _repository.insert(printer);
    await loadPrinters();
  }

  Future<void> updatePrinter(Printer printer) async {
    await _repository.update(printer);
    await loadPrinters();
  }

  Future<void> deletePrinter(int id) async {
    await _repository.delete(id);
    await loadPrinters();
  }

  Future<void> setDefault(int id) async {
    await _repository.setDefault(id);
    await loadPrinters();
  }
}
