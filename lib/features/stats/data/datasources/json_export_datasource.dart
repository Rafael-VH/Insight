import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

abstract class JsonExportDataSource {
  Future<String> writeJsonFile(String fileName, String jsonString);
  Future<String> readJsonFile(String filePath);
}

class JsonExportDataSourceImpl implements JsonExportDataSource {
  @override
  Future<String> writeJsonFile(String fileName, String jsonString) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(jsonString, encoding: utf8, flush: true);
    return file.path;
  }

  @override
  Future<String> readJsonFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('El archivo no existe', filePath);
    }
    final size = await file.length();
    if (size == 0) {
      throw FileSystemException('El archivo está vacío', filePath);
    }
    return file.readAsString(encoding: utf8);
  }
}
