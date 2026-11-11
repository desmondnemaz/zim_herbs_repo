
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pasteboard/pasteboard.dart';

/// Helper service for retrieving images directly from the system clipboard
/// (e.g. screenshots from Win+Shift+S, copied browser images, WhatsApp images).
class ClipboardImageService {
  /// Reads raw image bytes from the system clipboard.
  /// Returns `null` if the clipboard is empty or does not contain image data.
  static Future<Uint8List?> getClipboardImage() async {
    try {
      final bytes = await Pasteboard.image;
      if (bytes != null && bytes.isNotEmpty) {
        return bytes;
      }
    } catch (e) {
      debugPrint('[ClipboardImageService] Error reading clipboard image: $e');
    }
    return null;
  }

  /// Converts image bytes to an [XFile] compatible with upload repositories.
  static XFile bytesToXFile(Uint8List bytes, {String prefix = 'herb_image'}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${prefix}_$timestamp.png';
    return XFile.fromData(
      bytes,
      name: fileName,
      mimeType: 'image/png',
    );
  }
}

