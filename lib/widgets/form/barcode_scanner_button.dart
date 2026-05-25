import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerButton extends StatelessWidget {
  final Function(String) onScan;

  const BarcodeScannerButton({super.key, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.qr_code_scanner),
      onPressed: () => _openScanner(context),
    );
  }

  Future<void> _openScanner(BuildContext context) async {
    bool detected = false;
    final result = await Get.dialog<String>(
      AlertDialog(
        content: SizedBox(
          width: 300,
          height: 400,
          child: MobileScanner(
            onDetect: (capture) {
              if (detected) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  detected = true;
                  Get.back(result: code);
                }
              }
            },
          ),
        ),
      ),
    );

    if (result != null) {
      onScan(result);
    }
  }
}
