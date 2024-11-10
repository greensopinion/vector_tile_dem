import 'dart:io';

final outputDir = Directory('tmp');

Future<File> outputFile(String name) async {
  await outputDir.create(recursive: true);
  return File('${outputDir.path}/$name');
}

Future<File> writeOutput(String name, List<int> bytes) async {
  final file = await outputFile(name);
  await file.writeAsBytes(bytes);
  return file;
}
