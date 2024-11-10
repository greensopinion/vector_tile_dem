import 'dart:typed_data';

import 'package:image/image.dart' as img;

img.Image decodePng(Uint8List bytes) {
  final image = img.PngDecoder().decode(bytes);
  if (image == null) {
    throw 'No image in raw data';
  }
  return image;
}
