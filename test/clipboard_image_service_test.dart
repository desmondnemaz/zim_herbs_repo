import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:zim_herbs_repo/core/utils/clipboard_image_service.dart';

void main() {
  group('ClipboardImageService Tests', () {
    test('bytesToXFile produces valid XFile with correct mimeType and name', () {
      final dummyBytes = Uint8List.fromList([1, 2, 3, 4]);
      final xfile = ClipboardImageService.bytesToXFile(dummyBytes, prefix: 'test_paste');

      expect(xfile.name, startsWith('test_paste_'));
      expect(xfile.name, endsWith('.png'));
      expect(xfile.mimeType, 'image/png');
    });
  });
}

