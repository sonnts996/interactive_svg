/*
 Created by sonnts996 on 15/10/25.
 Copyright (c) 2025 . All rights reserved.
*/

import 'package:flutter/material.dart';

import '../interactive_svg.dart';
import 'entities/bounds_cache.dart';

/// A [BoundsFactory] implementation that lazily computes and caches SVG region bounds.
///
/// LazyBoundsFactory uses a [GlobalKey] to obtain the render box size of the
/// widget that contains the SVG. Bounds are computed by delegating to the
/// provided [InteractiveParserDelegate] via `parseSvgBounds`.
///
/// This factory caches scaled results keyed by [BoundsCachedData] (size + fit + alignment)
/// so repeated resolves for the same layout do not re-scale paths unnecessarily.
///
/// Typical usage:
/// - Create this factory with the widget's [GlobalKey] and a parser delegate.
/// - Call [load] (typically after layout / in a post-frame callback) to compute bounds.
/// - Call [resolve] with the current widget size to obtain scaled bounds (cached when possible).
/// - Listen for changes on this factory to be notified when bounds are available.
///
/// Important semantics:
/// - Until [load] is called and the underlying parser returns results, [hasData]
///   is false and [data] will return an empty [BoundsList].
/// - [load] attempts to synchronously obtain the RenderBox size (via the key).
///   If the RenderBox is not available, it resolves to an empty [BoundsList].
/// - Any error during parsing will be captured in the snapshot state and listeners
///   will be notified so callers can inspect the error via the snapshot APIs if needed.
/// - Listeners are notified on the same thread that invoked [_updateSnapshot].
class LazyBoundsFactory extends BoundsFactory {
  /// Creates a [LazyBoundsFactory].
  ///
  /// [key] must be the GlobalKey attached to the widget that holds the rendered SVG,
  /// so the factory can obtain the widget size. [parserDelegate] performs the actual
  /// parsing and bounds calculation.
  LazyBoundsFactory({
    required this.key,
    required InteractiveParserDelegate parserDelegate,
  }) : _parserDelegate = parserDelegate;

  /// The [GlobalKey] used to find the widget's [RenderBox] and size.
  final GlobalKey key;

  final BoundsCache _cache = BoundsCache();

  /// The parser delegate responsible for extracting SVG bounds.
  InteractiveParserDelegate _parserDelegate;

  /// Returns true if bounds data is available and not empty.
  ///
  /// This property is derived from the internal async snapshot.
  @override
  bool get hasData =>
      _boundsSnapshot.hasData &&
      _boundsSnapshot.data != null &&
      _boundsSnapshot.data!.isNotEmpty;

  /// Returns the cached bounds data, or an empty map if not available.
  ///
  /// This getter never returns null; callers can safely read it without null checks.
  @override
  BoundsList get data => _cache.current ?? BoundsList();

  @override
  BoundsList resolve(
    Size size, {
    BoxFit fit = BoxFit.contain,
    Alignment alignment = Alignment.topLeft,
  }) {
    if (_boundsSnapshot.hasData) {
      final cachedData = BoundsCachedData(
        size: size,
        fit: fit,
        alignment: alignment,
      );
      final bounds = _cache[cachedData];
      if (bounds != null) {
        return bounds;
      }
      _cache[cachedData] = _parserDelegate.scaleSvgBounds(
        _boundsSnapshot.data!,
        size: size,
        fit: fit,
        alignment: alignment,
      );
      notifyListeners();
      return _cache[cachedData] ?? BoundsList();
    }
    return BoundsList();
  }

  /// The current connection state of the bounds computation.
  @override
  ConnectionState get state => _boundsSnapshot.connectionState;

  AsyncSnapshot<BoundsList> _boundsSnapshot = const AsyncSnapshot.nothing();

  /// Resets the bounds cache and optionally updates the parser delegate.
  ///
  /// Call this when the SVG content or selectors change. After reset, listeners
  /// will be notified and `hasData` will become false until `load` computes new results.
  @override
  void reset([InteractiveParserDelegate? parserDelegate]) {
    if (parserDelegate != null) {
      _parserDelegate = parserDelegate;
    }
    _cache.clear();
    _updateSnapshot(const AsyncSnapshot.nothing());
  }

  /// Loads (computes) SVG bounds and updates the internal snapshot.
  ///
  /// This method calls `_parserDelegate.parseSvgBounds()` to obtain unscaled
  /// bounds expressed in the SVG's coordinate space (viewBox) and stores the
  /// result in the snapshot. Callers should ensure the parser delegate has
  /// been prepared (e.g. `await parserDelegate.loadAssets(context)`) before
  /// calling `load()`.
  @override
  void load() {
    _cache.clear();
    _updateSnapshot(const AsyncSnapshot.waiting());
    try {
      final bounds = _parserDelegate.parseSvgBounds();
      _updateSnapshot(
        AsyncSnapshot.withData(ConnectionState.done, bounds),
      );
    } catch (e, st) {
      _updateSnapshot(
        AsyncSnapshot.withError(ConnectionState.done, e, st),
      );
    }
  }

  /// Updates the internal snapshot and notifies listeners.
  ///
  /// Implementations use an [AsyncSnapshot] to encode state/data/error in a single
  /// object. After updating, [notifyListeners] is called so UI can react to the change.
  void _updateSnapshot(AsyncSnapshot<BoundsList> snapshot) {
    _boundsSnapshot = snapshot;
    notifyListeners();
  }
}
