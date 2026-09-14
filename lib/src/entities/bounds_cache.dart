import 'package:flutter/cupertino.dart';

import '../../interactive_svg.dart';

/// Immutable descriptor used as a cache key for scaled SVG bounds.
///
/// Holds the target widget [size], the [alignment] used when fitting the SVG,
/// and the [fit] mode (BoxFit). Instances are value objects: equality and
/// hashCode are based on the three fields so they can be used as map keys.
@immutable
class BoundsCachedData {
  /// Create a cache key for scaled bounds.
  ///
  /// Default values represent an empty size and standard fitting of the
  /// SVG: top-left alignment and `BoxFit.contain`.
  const BoundsCachedData({
    this.size = Size.zero,
    this.alignment = Alignment.topLeft,
    this.fit = BoxFit.contain,
  });

  /// The target render size for which bounds were computed.
  final Size size;

  /// The alignment used when fitting the SVG into [size].
  final Alignment alignment;

  /// The BoxFit mode used to scale the SVG when producing the cached bounds.
  final BoxFit fit;

  @override
  String toString() =>
      'BoundsCachedData(size: $size, alignment: $alignment, fit: $fit)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BoundsCachedData &&
        other.size == size &&
        other.alignment == alignment &&
        other.fit == fit;
  }

  @override
  int get hashCode => size.hashCode ^ alignment.hashCode ^ fit.hashCode;
}

/// Simple in-memory cache for scaled SVG bounds.
///
/// Keys are [BoundsCachedData] (size + fit + alignment) and values are
/// [BoundsList]. The cache also tracks the last-used key in [_currentCached]
/// to support quick `data` lookup in consumers that want the most recent result.
class BoundsCache {
  final Map<BoundsCachedData, BoundsList> _cache = {};

  BoundsCachedData? _currentCached;

  /// The most recently stored/cache key's value.
  ///
  /// Returns the cached [BoundsList] for the last key written via
  /// `operator []=` or `null` if nothing has been cached yet.
  BoundsList? get current =>
      _currentCached != null ? this[_currentCached!] : null;

  /// Store [value] under [key] and mark [key] as the most recent.
  ///
  /// This updates the in-memory cache and also advances the "current" pointer
  /// so subsequent reads via [current] will return the newly stored value.
  void operator []=(BoundsCachedData key, BoundsList value) {
    _currentCached = key;
    _cache[key] = value;
  }

  /// Retrieve the cached [BoundsList] for [key].
  ///
  /// Returns `null` if there is no entry for the provided key.
  BoundsList? operator [](BoundsCachedData key) => _cache[key];

  /// Clear all cached entries and reset the "current" pointer.
  ///
  /// After calling this, [current] will return `null`.
  void clear() {
    _currentCached = null;
    _cache.clear();
  }
}
