/*
 Created by sonnts996 on 10/10/25.
 Copyright (c) 2025 . All rights reserved.
*/

import 'package:flutter/material.dart';

import '../../interactive_svg.dart';
import 'interactive_selector.dart';

/// Represents a fragment of SVG content associated with an optional selector.
///
/// - [selector] is the `InteractiveSelector` corresponding to this fragment.
///   When `selector` is `null` this entry represents the background / full SVG
///   content (i.e. non-selective base layer).
/// - [svg] contains the raw SVG string fragment to render for this region.
@immutable
class SvgRegion {
  /// Creates a new [SvgRegion] with the given fields.
  const SvgRegion({
    required this.selector,
    required this.svg,
  });

  /// The selector associated with this fragment, or `null` for the background/full SVG.
  final InteractiveSelector? selector;

  /// Raw SVG content for this fragment. This string is intended to be passed to
  /// SvgPicture.string or similar renderers.
  final String svg;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SvgRegion && selector == other.selector && svg == other.svg;

  @override
  int get hashCode => selector.hashCode ^ svg.hashCode;

  /// Returns a copy of this [SvgRegion], replacing any provided fields.
  ///
  /// Leave parameters null to preserve existing values.
  SvgRegion copyWith({
    InteractiveSelector? selector,
    String? svg,
  }) =>
      SvgRegion(
        selector: selector ?? this.selector,
        svg: svg ?? this.svg,
      );

  @override
  String toString() => 'SvgRegion{selector: $selector, svg: $svg}';
}
