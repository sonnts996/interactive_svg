/*
 Created by sonnts996 on 15/10/25.
 Copyright (c) 2025 . All rights reserved.
*/

import '../../interactive_svg.dart';

/// Provides metadata about a parsed SVG region passed to `interactiveBuilder`.
///
/// - [selector] is the `InteractiveSelector` that identifies the region.
/// - [bounds] holds the computed hit-test geometry ([SvgBounds]) for the region,
///   or `null` if bounds have not yet been computed (bounds are typically computed
///   after layout when the rendered size is known).
///
/// Notes:
/// - Because bounds may be null on the initial build, callers that depend on
///   bounds should set `shouldRebuildWhenBoundsCalculated` on the parent widget
///   to true so `interactiveBuilder` will be rebuilt once bounds are available.
class SvgRegionsDetails {
  /// Create a details object associating [selector] with optional [bounds].
  SvgRegionsDetails({
    required this.bounds,
    required this.selector,
  });

  /// The selector for this region.
  final InteractiveSelector selector;

  /// The computed bounds (may be null until layout/bounds calculation completes).
  final SvgBounds? bounds;

  @override
  String toString() =>
      'SvgRegionsDetails{selector: $selector, bounds: $bounds}';
}
