import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Pick a PDF file using the browser's native file picker.
/// Returns the file name and bytes, or null if cancelled.
Future<({String name, Uint8List bytes})?> pickPdfFile() async {
  final completer = Completer<({String name, Uint8List bytes})?>();

  final input = web.document.createElement('input') as web.HTMLInputElement;
  input.type = 'file';
  input.accept = '.pdf';

  input.addEventListener(
    'change',
    (web.Event event) {
      final files = input.files;
      if (files != null && files.length > 0) {
        final file = files.item(0)!;
        final reader = web.FileReader();
        reader.addEventListener(
          'load',
          (web.Event event) {
            final arrayBuffer = reader.result as JSArrayBuffer;
            final bytes = arrayBuffer.toDart.asUint8List();
            if (!completer.isCompleted) {
              completer.complete((name: file.name, bytes: bytes));
            }
          }.toJS,
        );
        reader.addEventListener(
          'error',
          (web.Event event) {
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          }.toJS,
        );
        reader.readAsArrayBuffer(file);
      } else {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      }
    }.toJS,
  );

  input.addEventListener(
    'cancel',
    (web.Event event) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }.toJS,
  );

  input.click();

  return completer.future;
}
