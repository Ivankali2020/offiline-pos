import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;

/// Compiles a PNG-encoded `Uint8List` image (captured by the `screenshot`
/// package's `captureFromLongWidget`) into a fully-formed ESC/POS command
/// byte-array ready for transmission over a TCP socket on port 9100.
///
/// **Pipeline:**
/// 1. Hardware reset (`generator.reset()`).
/// 2. Decode the PNG and raster the bitmap (`generator.imageRaster()`).
/// 3. Beep the printer buzzer twice.
/// 4. Open the 24 V cash drawer via the RJ-11 kick connector (pin 2).
/// 5. Feed paper and execute a partial cut.
/// 6. Return the concatenated `List<int>` byte buffer.
///
/// [pngBytes] – PNG-encoded image data from `ScreenshotController`.
Future<List<int>> compileReceiptPayload(Uint8List pngBytes) async {
  // ── 0. Load the printer capability profile ────────────────────────────
  final profile = await CapabilityProfile.load();
  final generator = Generator(PaperSize.mm80, profile);

  // Accumulator for the final byte payload.
  final List<int> payload = [];

  // ── 1. Hardware reset ─────────────────────────────────────────────────
  // Clears any stale state left in the printer's receive buffer.
  payload.addAll(generator.reset());

  // ── 2. Decode PNG → rasterize ─────────────────────────────────────────
  // The `screenshot` package returns PNG-encoded bytes. Decode them into
  // an `img.Image` that `esc_pos_utils` can raster-print.
  final img.Image? decoded = img.decodePng(pngBytes);
  if (decoded == null) {
    throw ArgumentError('Failed to decode PNG image data');
  }

  // `imageRaster` converts the image into the ESC/POS GS v 0 raster-bit
  // command sequence, which is the most widely supported raster mode
  // across thermal printer firmware variants.
  payload.addAll(generator.imageRaster(decoded));

  // ── 3. Beep twice ─────────────────────────────────────────────────────
  // ESC B n1 n2  —  n1 = number of beeps, n2 = duration (×100 ms each).
  // Not every printer supports this; unsupported models silently ignore it.
  payload.addAll(<int>[0x1B, 0x42, 0x02, 0x02]);

  // ── 4. Open the cash drawer ───────────────────────────────────────────
  // ESC p m t1 t2
  //   m  = 0x00 → pin 2 (drawer kick connector)
  //   t1 = 0x19 (25 × 2 ms = 50 ms ON pulse)
  //   t2 = 0x78 (120 × 2 ms = 240 ms OFF pulse)
  payload.addAll(<int>[0x1B, 0x70, 0x00, 0x19, 0x78]);

  // ── 5. Feed + partial cut ─────────────────────────────────────────────
  // Feed a few lines so the cut lands below the printed content, then
  // issue a partial-cut command (leaves a small strip attached).
  payload.addAll(generator.feed(4));
  payload.addAll(generator.cut(mode: PosCutMode.partial));

  return payload;
}
