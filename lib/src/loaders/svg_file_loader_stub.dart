/// Reports that local files are unavailable on the current platform.
/// Báo lỗi khi nền tảng hiện tại không hỗ trợ file cục bộ.
Future<String> loadSvgFile(String filePath) => Future<String>.error(
      UnsupportedError(
        'InteractiveSvgFileProvider is not supported on this platform.',
      ),
    );
