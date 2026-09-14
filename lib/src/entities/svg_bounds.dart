/*
 Created by sonnts996 on 15/10/25.
 Copyright (c) 2025 . All rights reserved.
*/

import 'dart:ui';

import '../../interactive_svg.dart';

/// Represents the hit-testable geometry for a parsed SVG region.
///
/// Contains the raw [Path] used for hit testing and the associated
/// [InteractiveSelector] that identifies the region in the SVG.
///
/// Usage notes:
/// - [path] should be in the same coordinate space as the rendered SVG content
///   (i.e. already transformed according to viewBox / fit / alignment).
/// - The [getVisibleBounds] getter returns an axis-aligned bounding rect computed from the
///   visible portion of [path] (sampling-based approximation).
/// - Use [contains] to perform a fast membership test; it first checks a quick
///   bounding-box containment before invoking the potentially expensive
///   path.contains test.
class SvgBounds {
  /// Create a new [SvgBounds] for [selector] backed by [path].
  const SvgBounds({
    required this.path,
    required this.selector,
  });

  /// The geometric path used for hit testing.
  final Path path;

  /// The selector that identifies the SVG region this path corresponds to.
  final InteractiveSelector selector;

  /// Axis-aligned bounding rectangle that encloses the visible points of [path].
  ///
  /// This is computed from `path.visibleBounds` and may be an approximation
  /// (sampling-based). It is useful for fast bounding-box checks before more
  /// expensive path containment tests.
  Rect getVisibleBounds() => path.visibleBounds;

  /// Axis-aligned bounding rectangle that encloses the entire [path].
  ///
  /// This is computed from `path.getBounds()` and may include empty
  /// areas if the path has holes or non-visible segments.
  /// Use [getVisibleBounds] for a tighter fit around visible content.
  Rect getBounds() => path.getBounds();

  /// Returns true when [point] is inside the region represented by this path.
  ///
  /// The implementation performs a quick bounding-rect test first (cheap),
  /// then calls the more expensive `path.contains` when necessary.
  bool contains(Offset point) {
    // Quick bounding rect check before expensive contains()
    if (path.getBounds().contains(point)) {
      return path.contains(point);
    }
    return false;
  }

  /// Creates a copy of this [SvgBounds] with the provided fields replaced.
  ///
  /// Useful for performing local modifications without mutating the original
  /// instance. Any parameter left null will preserve the corresponding value
  /// from the original.
  SvgBounds copyWith({
    Path? path,
    InteractiveSelector? selector,
  }) =>
      SvgBounds(
        path: path ?? this.path,
        selector: selector ?? this.selector,
      );

  @override
  String toString() => 'SvgBounds{path: $path, selector: $selector}';
}
