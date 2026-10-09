import 'dart:io';

/// Loads raw SVG text from [filePath].
/// Tải nội dung SVG thô từ [filePath].
Future<String> loadSvgFile(String filePath) => File(filePath).readAsString();
