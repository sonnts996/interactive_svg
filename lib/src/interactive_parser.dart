/*
 Created by sonnts996 on 15/10/25.
 Copyright (c) 2025 . All rights reserved.
*/

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../interactive_svg.dart';
import 'parsers/bounds_parser_utilities.dart';

/// Concrete [InteractiveParserDelegate] that loads an SVG asset and extracts
/// interactive regions and hit-test bounds according to provided [InteractiveSelector]s.
///
/// This implementation parses the SVG XML (via [loadAssets]) and exposes:
/// - `parseSvg()` to produce per-selector SVG fragments (the base SVG is stored under `null`),
/// - `parseSvgBounds()` to compute unscaled path bounds in the SVG's internal coordinate
///   system (viewBox). To obtain device/widget-space bounds you must call
///   [scaleSvgBounds] with a target [Size], [BoxFit], and [Alignment].
///
/// Usage:
/// 1. Call [loadAssets] with a BuildContext to load and parse the SVG asset (reads viewBox).
/// 2. Call [parseSvg] to obtain per-selector SVG fragments.
/// 3. Call [parseSvgBounds] to obtain path-based bounds (in SVG coordinates).
class InteractiveParser extends InteractiveParserDelegate {
  /// Creates an [InteractiveParser] with the given [asset] and [selectors].
  InteractiveParser({required this.asset, this.selectors = const []});

  /// The SVG asset path to load.
  final String asset;

  /// The list of selectors defining interactive regions.C
  final Iterable<InteractiveSelector> selectors;

  InteractiveParseContext? _currentContext;

  /// The current parsing context, including the XML document and viewBox.
  InteractiveParseContext? get currentContext => _currentContext;

  bool _lock = false;

  @override
  bool get hasTouchableItem => selectors.any(
        (e) =>
            e.type == InteractiveType.touchable ||
            e.type == InteractiveType.boundsOnly,
      );

  /// Loads the SVG asset and parses its XML document.
  ///
  /// This method must be awaited before calling [parseSvg] or [parseSvgBounds].
  @override
  Future<void> loadAssets(BuildContext context) async {
    if (_lock) {
      return;
    }
    _lock = true;
    try {
      final svgString = await DefaultAssetBundle.of(context).loadString(asset);
      final document = XmlDocument.parse(svgString);
      final svg = document.findElements('svg').firstOrNull;
      _currentContext = InteractiveParseContext(root: svg, document: document);
      _parseViewBox(_currentContext!);
    } catch (e) {
      rethrow;
    } finally {
      _lock = false;
    }
  }

  void _parseViewBox(InteractiveParseContext context) {
    if (context.root == null) {
      return;
    }
    final viewBox = context.root!.getAttribute('viewBox');
    if (viewBox == null) {
      return;
    }
    // Parse viewBox to get dimensions
    final viewBoxParts =
        viewBox.split(' ').map((s) => double.tryParse(s) ?? 0).toList();
    if (viewBoxParts.length == 4) {
      final rect = Rect.fromLTWH(
        viewBoxParts[0],
        viewBoxParts[1],
        viewBoxParts[2],
        viewBoxParts[3],
      );
      _currentContext = context.copyWith(viewBox: rect);
    }
  }

  /// Parses the SVG and extracts regions based on the provided selectors.
  ///
  /// Returns a [RegionList] mapping each selector to an [SvgRegion]. The entry with key
  /// `null` contains the full/base SVG content (with the selected groups removed).
  /// Note: callers must call [loadAssets] prior to calling this method.
  @override
  RegionList parseSvg() {
    assert(!_lock, 'Please call loadAssets first and wait until it completes.');

    final context_ = _currentContext;
    assert(context_ != null, 'Please call loadAssets first.');
    assert(context_!.document != null, 'Please call loadAssets first.');
    assert(context_!.root != null, 'Please call loadAssets first.');

    final regions = RegionList();
    final context = context_!;

    /// Avoid editing on the original document
    final document = context.document!.copy();
    final root = context.root!.copy();

    for (final selector in selectors) {
      final group = selector(document);
      if (group == null) {
        continue;
      }
      group.remove();
      final region = _convertLayerToSvg(selector, group, root);
      regions[selector] = region;
    }
    regions[null] = SvgRegion(selector: null, svg: document.toString());
    return regions;
  }

  /// Converts a specific SVG layer to an [SvgRegion] for the given [selector].
  ///
  /// Returns an [SvgRegion] containing the SVG string for the selected layer.
  SvgRegion _convertLayerToSvg(
    InteractiveSelector selector,
    XmlNode layer,
    XmlElement root,
  ) {
    final defs =
        layer.getElement('defs') == null ? root.getElement('defs') : null;
    final element = XmlElement(
      root.name.copy(),
      root.attributes.map((e) => e.copy()).toList(),
      [if (defs != null) defs.copy(), layer.copy()],
      root.isSelfClosing,
    );
    return SvgRegion(selector: selector, svg: element.toString());
  }

  /// Parses the SVG and returns a map of selector -> [SvgBounds] (path) for touchable items.
  ///
  /// The returned paths are expressed in the SVG document coordinate space (the viewBox).
  /// This method does not perform widget-size scaling; to convert these bounds into
  /// widget/render coordinates call [scaleSvgBounds] with a target `size`, `fit` and
  /// `alignment`. Only selectors with `type == InteractiveType.touchable` or
  /// `type == InteractiveType.boundsOnly` are considered. If a selector's group is
  /// not found or no valid path can be constructed, that selector is skipped.
  @override
  BoundsList parseSvgBounds() {
    assert(!_lock, 'Please call loadAssets first and wait until it completes.');

    final context_ = _currentContext;
    assert(context_ != null, 'Please call loadAssets first.');
    assert(context_!.document != null, 'Please call loadAssets first.');

    final boundsRegions = BoundsList();
    final context = context_!;
    final document = context.document!;

    final touchableComponents = selectors.where(
      (e) =>
          e.type == InteractiveType.touchable ||
          e.type == InteractiveType.boundsOnly,
    );
    for (final selector in touchableComponents) {
      final group = selector(document);
      if (group == null) {
        continue;
      }
      final path = parseBoundsFromSvg(group);

      if (path != null) {
        boundsRegions[selector] = SvgBounds(path: path, selector: selector);
      }
    }
    return boundsRegions;
  }

  /// Checks if this parser is different from [other].
  ///
  /// Returns true if the asset or selectors have changed.
  @override
  bool isChanged(covariant InteractiveParserDelegate other) {
    if (other is! InteractiveParser) return true;
    return other.asset != asset ||
        !const DeepCollectionEquality().equals(other.selectors, selectors);
  }

  @override
  BoundsList scaleSvgBounds(
    BoundsList boundsList, {
    Size size = Size.zero,
    Alignment alignment = Alignment.topLeft,
    BoxFit fit = BoxFit.contain,
  }) {
    assert(!_lock, 'Please call loadAssets first and wait until it completes.');

    final context_ = _currentContext;
    assert(context_ != null, 'Please call loadAssets first.');
    assert(context_!.viewBox != null, 'Please call loadAssets first.');

    final boundsRegions = BoundsList();
    final context = context_!;
    final viewBox = context.viewBox!;

    MapEntry<InteractiveSelector, SvgBounds> scaleF(
      InteractiveSelector s,
      SvgBounds bounds,
    ) =>
        MapEntry(
          s,
          bounds.copyWith(
            path: scaleBounds(
              bounds.path,
              size: size,
              fit: fit,
              alignment: alignment,
              viewBox: viewBox,
            ),
          ),
        );
    boundsRegions.addAll(boundsList.map(scaleF));
    return boundsRegions;
  }
}
