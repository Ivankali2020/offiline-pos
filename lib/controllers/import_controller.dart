import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:abpos/data/csv/csv_templates.dart';
import 'package:abpos/data/repositories/import_repository.dart';
import 'package:abpos/models/import_log.dart';
import 'package:abpos/services/app_refresh_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum ImportType {
  categories,
  brands,
  expenseCategories,
  expenses,
  products;

  String get label => switch (this) {
    ImportType.categories => 'Categories',
    ImportType.brands => 'Brands',
    ImportType.expenseCategories => 'Expense Categories',
    ImportType.expenses => 'Expenses',
    ImportType.products => 'Products',
  };

  String get typeName => switch (this) {
    ImportType.categories => 'categories',
    ImportType.brands => 'brands',
    ImportType.expenseCategories => 'expense_categories',
    ImportType.expenses => 'expenses',
    ImportType.products => 'products',
  };
}

class ImportController extends GetxController {
  final CsvImportRepository _repository = CsvImportRepository();

  final RxBool isBusy = false.obs;
  final RxList<ImportLog> history = <ImportLog>[].obs;
  final Rx<ImportLog?> lastResult = Rx<ImportLog?>(null);

  // Default seller id — matches the seeded row
  static const int _sellerId = 1;

  @override
  void onInit() {
    super.onInit();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    history.assignAll(await _repository.findAll());
  }

  // ---------------------------------------------------------------------------
  // Download sample CSV
  // ---------------------------------------------------------------------------

  Future<void> downloadSample(ImportType type) async {
    final context = Get.context;
    RenderBox? box;
    if (context != null && context.mounted) {
      box = context.findRenderObject() as RenderBox?;
    }

    try {
      final content = CsvTemplates.sampleFor(type.typeName);
      final fileName = CsvTemplates.filenameFor(type.typeName);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(content);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'AB POS – $fileName',
          text: 'Sample CSV template for importing ${type.label}.',
          sharePositionOrigin: box != null
              ? (box.localToGlobal(Offset.zero) & box.size)
              : null,
        ),
      );
    } catch (e) {
      Get.snackbar(
        'Download Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Save sample CSV directly to Downloads folder
  // ---------------------------------------------------------------------------

  Future<void> saveToDownloads(ImportType type) async {

    try {
      final content = CsvTemplates.sampleFor(type.typeName);

      final fileName = CsvTemplates.filenameFor(type.typeName);

      final dir = await _resolveDownloadsDirectory();

      await dir.create(recursive: true);

      final file = File('${dir.path}/$fileName');

      await file.writeAsString(content);

      Get.snackbar(
        'Saved to Downloads',

        file.path,

        snackPosition: SnackPosition.BOTTOM,

        duration: const Duration(seconds: 5),

        mainButton: TextButton(
          onPressed: () => Get.back<void>(),

          child: const Text('OK', style: TextStyle(color: Colors.white)),
        ),
      );
    } catch (e) {
      Get.snackbar(
        'Save Failed',

        e.toString(),

        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<Directory> _resolveDownloadsDirectory() async {
    if (Platform.isAndroid) {
      // Directly target the public root Download directory
      return Directory('/storage/emulated/0/Download');
    } else {
      // iOS and other platforms can safely use path_provider
      final directory = await getApplicationDocumentsDirectory();
      return directory;
    }
  }
  // Future<void> saveToDownloads(ImportType type) async {
  //   try {
  //     final fullFileName = CsvTemplates.filenameFor(type.typeName);
  //     final dotIndex = fullFileName.lastIndexOf('.');
  //     final name = dotIndex != -1 ? fullFileName.substring(0, dotIndex) : fullFileName;
  //     final ext = dotIndex != -1 ? fullFileName.substring(dotIndex + 1) : 'csv';

  //     final content = CsvTemplates.sampleFor(type.typeName);
  //     final bytes = Uint8List.fromList(utf8.encode(content));

  //     final path = await FileSaver.instance.saveFile(
  //       name: name,
  //       bytes: bytes,
  //       ext: ext,
  //       mimeType: MimeType.csv,
  //     );

  //     Get.snackbar(
  //       'Saved to Downloads',
  //       path != null && path.isNotEmpty
  //           ? 'File saved successfully: $path'
  //           : 'File saved successfully.',
  //       snackPosition: SnackPosition.BOTTOM,
  //       duration: const Duration(seconds: 5),
  //       mainButton: TextButton(
  //         onPressed: () => Get.back<void>(),
  //         child: const Text('OK', style: TextStyle(color: Colors.white)),
  //       ),
  //     );
  //   } catch (e) {
  //     Get.snackbar(
  //       'Save Failed',
  //       e.toString(),
  //       snackPosition: SnackPosition.BOTTOM,
  //     );
  //   }
  // }

  // ---------------------------------------------------------------------------
  // Pick CSV file and run import
  // ---------------------------------------------------------------------------

  Future<void> runImport(ImportType type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    final path = result?.files.single.path;
    if (path == null || path.trim().isEmpty) return;

    isBusy.value = true;
    try {
      final log = await _doImport(type, path);
      lastResult.value = log;
      await _loadHistory();
      await AppRefreshService.refreshAll();

      final ok = log.successfulRows;
      final total = log.totalRows;
      if (log.status == 'completed') {
        Get.snackbar(
          '${type.label} Imported',
          '$ok of $total rows imported successfully.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Import Issues',
          '$ok of $total rows succeeded. ${log.failedRows} failed.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFDC2626).withValues(alpha: 0.9),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Import Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<ImportLog> _doImport(ImportType type, String path) {
    return switch (type) {
      ImportType.categories => _repository.importCategories(path, _sellerId),
      ImportType.brands => _repository.importBrands(path, _sellerId),
      ImportType.expenseCategories => _repository.importExpenseCategories(path),
      ImportType.expenses => _repository.importExpenses(path),
      ImportType.products => _repository.importProducts(path, _sellerId),
    };
  }
}
