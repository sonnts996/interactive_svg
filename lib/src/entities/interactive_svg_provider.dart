import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../loaders/svg_file_loader.dart';

/// Supplies raw SVG text to an interactive parser.
/// Cung cấp nội dung SVG thô cho interactive parser.
abstract class InteractiveSvgProvider {
  /// Creates an SVG provider.
  /// Tạo một SVG provider.
  const InteractiveSvgProvider();

  /// Creates a provider from raw SVG [svg].
  /// Tạo provider từ nội dung SVG [svg] thô.
  const factory InteractiveSvgProvider.string(String svg) =
      InteractiveSvgStringProvider;

  /// Creates a provider for an [assetName] in a Flutter asset bundle.
  /// Tạo provider cho [assetName] trong Flutter asset bundle.
  const factory InteractiveSvgProvider.asset(
    String assetName, {
    AssetBundle? bundle,
  }) = InteractiveSvgAssetProvider;

  /// Creates a provider for a local [filePath].
  /// Tạo provider cho [filePath] cục bộ.
  const factory InteractiveSvgProvider.file(String filePath) =
      InteractiveSvgFileProvider;

  /// Creates a provider for an HTTP or HTTPS [url].
  /// Tạo provider cho HTTP hoặc HTTPS [url].
  const factory InteractiveSvgProvider.network(String url) =
      InteractiveSvgNetworkProvider;

  /// Loads the raw SVG text.
  /// Tải nội dung SVG thô.
  Future<String> load(BuildContext context);
}

/// Supplies SVG text that is already available in memory.
/// Cung cấp nội dung SVG đã có sẵn trong bộ nhớ.
@immutable
final class InteractiveSvgStringProvider extends InteractiveSvgProvider {
  /// Creates a provider from raw [svg] text.
  /// Tạo provider từ nội dung [svg] thô.
  const InteractiveSvgStringProvider(this.svg);

  /// Raw SVG text.
  /// Nội dung SVG thô.
  final String svg;

  @override
  Future<String> load(BuildContext context) => SynchronousFuture(svg);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InteractiveSvgStringProvider && other.svg == svg;

  @override
  int get hashCode => svg.hashCode;
}

/// Loads SVG text from a Flutter asset bundle.
/// Tải nội dung SVG từ Flutter asset bundle.
@immutable
final class InteractiveSvgAssetProvider extends InteractiveSvgProvider {
  /// Creates an asset provider for [assetName].
  /// Tạo asset provider cho [assetName].
  const InteractiveSvgAssetProvider(this.assetName, {this.bundle});

  /// Asset key declared by the application or package.
  /// Khóa asset được khai báo bởi ứng dụng hoặc package.
  final String assetName;

  /// Optional explicit bundle; defaults to the nearest bundle in the build
  /// context.
  /// Bundle tùy chọn; mặc định dùng bundle gần nhất trong build context.
  final AssetBundle? bundle;

  @override
  Future<String> load(BuildContext context) =>
      (bundle ?? DefaultAssetBundle.of(context)).loadString(assetName);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InteractiveSvgAssetProvider &&
          other.assetName == assetName &&
          identical(other.bundle, bundle);

  @override
  int get hashCode => Object.hash(assetName, identityHashCode(bundle));
}

/// Loads SVG text from a local file path on platforms with `dart:io` support.
/// Tải nội dung SVG từ đường dẫn file cục bộ trên nền tảng hỗ trợ `dart:io`.
@immutable
final class InteractiveSvgFileProvider extends InteractiveSvgProvider {
  /// Creates a local-file provider for [filePath].
  /// Tạo local-file provider cho [filePath].
  const InteractiveSvgFileProvider(this.filePath);

  /// Local SVG file path.
  /// Đường dẫn file SVG cục bộ.
  final String filePath;

  @override
  Future<String> load(BuildContext context) => loadSvgFile(filePath);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InteractiveSvgFileProvider && other.filePath == filePath;

  @override
  int get hashCode => filePath.hashCode;
}

/// Loads SVG text from an HTTP or HTTPS URL.
/// Tải nội dung SVG từ HTTP hoặc HTTPS URL.
@immutable
final class InteractiveSvgNetworkProvider extends InteractiveSvgProvider {
  /// Creates a network provider for [url].
  /// Tạo network provider cho [url].
  const InteractiveSvgNetworkProvider(this.url);

  /// Absolute HTTP or HTTPS URL of the SVG document.
  /// HTTP hoặc HTTPS URL tuyệt đối của tài liệu SVG.
  final String url;

  @override
  Future<String> load(BuildContext context) {
    final uri = Uri.parse(url);
    // Use Flutter's cross-platform network bundle. / Dùng network bundle đa nền tảng của Flutter.
    return NetworkAssetBundle(uri).loadString(url);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InteractiveSvgNetworkProvider && other.url == url;

  @override
  int get hashCode => url.hashCode;
}
