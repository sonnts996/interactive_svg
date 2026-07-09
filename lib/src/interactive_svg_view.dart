/*
 Created by sonnts996 on 10/10/25.
 Copyright (c) 2025 . All rights reserved.
*/

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/svg.dart';

import '../interactive_svg.dart';
import 'interactive_parser.dart';
import 'lazy_bound_factory.dart';
import 'widget/size_reporter.dart';

/// A widget that renders an SVG asset and exposes interactive regions via [InteractiveSelector].
///
/// This widget parses the provided SVG asset and renders each region/group as separate layers.
/// Important: do not rely on putting GestureDetector (or other hit-test wrappers) inside
/// `interactiveBuilder` to receive taps through transparent SVG areas. The flutter_svg renderer does not
/// forward pointer events through transparent pixels, so pointer events will not reliably reach widgets
/// layered beneath the SVG content.
///
/// InteractiveSvgView performs its own hit testing and dispatches taps via the [onTap] callback.
/// Use [interactiveBuilder] only to decorate or augment region widgets (e.g. add visual highlights,
/// overlays, labels). The builder signature receives (BuildContext, Widget regionWidget, SvgRegionsDetails details).
///
/// Notes about SvgRegionsDetails:
/// - details.selector: the InteractiveSelector associated with the region.
/// - details.bounds: may be null on the initial build because bounds are computed after layout; once computed,
///   they are available here.
///
/// If you want `interactiveBuilder` to be rebuilt after bounds are calculated, set
/// [shouldRebuildWhenBoundsCalculated] to true so the widget will rebuild and receive updated
/// SvgRegionsDetails with non-null bounds.
///
/// Correct usage example:
/// ```dart
/// InteractiveSvgView.fromAssets(
///   svgAssets: 'assets/tooth_chart.svg',
///   selectors: [InteractiveSelector.byID(id: 'tooth_1', type: InteractiveType.touchable)],
///   interactiveBuilder: (context, regionWidget, details) {
///     // Decorate the region; do NOT add GestureDetector expecting pointer pass-through.
///     return Stack(
///       children: [
///         regionWidget,
///         if (details.bounds != null)
///           // show an overlay or label positioned using details.bounds
///           Positioned.fromRect(rect: details.bounds!, child: /* overlay */ SizedBox.shrink()),
///       ],
///     );
///   },
///   onTap: (selector) => debugPrint('Tapped ${selector.label}'),
/// )
/// ```
///
/// Parameters:
/// - [parserDelegate]: The parser delegate that extracts regions from the SVG.
/// - [interactiveBuilder]: Optional builder for customizing each interactive region.
/// - [onTap]: Callback when a touchable region is tapped.
/// - [fit], [alignment]: Control SVG layout.
/// - [errorBuilder], [placeholderBuilder]: Custom error/placeholder widgets.
class InteractiveSvgView extends StatefulWidget {
  /// Creates an [InteractiveSvgView] with the given [parserDelegate].
  const InteractiveSvgView({
    super.key,
    required this.parserDelegate,
    this.interactiveBuilder,
    this.errorBuilder,
    this.placeholderBuilder,
    this.onTap,
    this.onTapOutside,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.topLeft,
    this.markerBuilder,
    this.onBoundsCalculated,
    this.shouldRebuildWhenBoundsCalculated = false,
  });

  /// Creates an [InteractiveSvgView] that loads an SVG asset from [svgAssets].
  ///
  /// [svgAssets] - asset path to the SVG file.
  /// [selectors] - optional list of selectors to parse and render as separate regions.
  /// [interactiveBuilder] - builder used to wrap each region (e.g. with gesture detectors).
  /// [onBoundsCalculated] - called when region bounds are computed.
  factory InteractiveSvgView.fromAssets({
    Key? key,
    required String svgAssets,
    Iterable<InteractiveSelector> selectors = const [],
    ErrorBuilder? errorBuilder,
    WidgetBuilder? placeholderBuilder,
    InteractiveBuilder? interactiveBuilder,
    void Function(InteractiveSelector selector)? onTap,
    void Function()? onTapOutside,
    BoxFit fit = BoxFit.contain,
    Alignment alignment = Alignment.topLeft,
    MarkerBuilder? markerBuilder,
    void Function(BoundsList boundsData)? onBoundsCalculated,
    bool shouldRebuildWhenBoundsCalculated = false,
  }) =>
      InteractiveSvgView(
        key: key,
        parserDelegate: InteractiveParser.fromAssets(
          svgAsset: svgAssets,
          selectors: selectors,
        ),
        errorBuilder: errorBuilder,
        placeholderBuilder: placeholderBuilder,
        interactiveBuilder: interactiveBuilder,
        onTap: onTap,
        onTapOutside: onTapOutside,
        fit: fit,
        alignment: alignment,
        markerBuilder: markerBuilder,
        onBoundsCalculated: onBoundsCalculated,
        shouldRebuildWhenBoundsCalculated: shouldRebuildWhenBoundsCalculated,
      );

  /// Parser delegate responsible for loading/parsing the SVG and providing regions.
  final InteractiveParserDelegate parserDelegate;

  /// Optional custom error builder. Receives (context, error, stackTrace).
  final ErrorBuilder? errorBuilder;

  /// Optional placeholder builder shown while loading.
  final WidgetBuilder? placeholderBuilder;

  /// Optional builder for wrapping each region widget. Useful for adding gestures or overlays.
  final InteractiveBuilder? interactiveBuilder;

  /// Optional callback invoked when a touchable [InteractiveSelector] is tapped.
  final void Function(InteractiveSelector selector)? onTap;

  /// Optional callback invoked when a tap occurs outside any touchable region.
  final void Function()? onTapOutside;

  /// How the SVG content should be inscribed into the available space.
  final BoxFit fit;

  /// Alignment used when rendering the SVG content.
  final Alignment alignment;

  /// Optional marker builder: used to overlay markers or additional widgets on top of the SVG.
  final MarkerBuilder? markerBuilder;

  /// Callback invoked when bounds for touchable regions are calculated.
  final void Function(BoundsList boundsData)? onBoundsCalculated;

  /// When true, the widget will trigger a rebuild after bounds are calculated.
  final bool shouldRebuildWhenBoundsCalculated;

  @override
  State<InteractiveSvgView> createState() => _InteractiveSvgViewState();

  // Added: expose important fields to Flutter diagnostics.
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<InteractiveParserDelegate>(
        'parserDelegate',
        parserDelegate,
        ifNull: 'null',
      ),
    );
    properties.add(DiagnosticsProperty<BoxFit>('fit', fit));
    properties.add(DiagnosticsProperty<Alignment>('alignment', alignment));
    properties.add(
      FlagProperty(
        'hasInteractiveBuilder',
        value: interactiveBuilder != null,
        ifTrue: 'true',
        ifFalse: 'false',
      ),
    );
    properties.add(
      FlagProperty(
        'hasOnTap',
        value: onTap != null,
        ifTrue: 'true',
        ifFalse: 'false',
      ),
    );
    properties.add(
      FlagProperty(
        'shouldRebuildWhenBoundsCalculated',
        value: shouldRebuildWhenBoundsCalculated,
        ifTrue: 'true',
        ifFalse: 'false',
      ),
    );
    properties.add(
      ObjectFlagProperty<MarkerBuilder?>.has('markerBuilder', markerBuilder),
    );
    properties.add(
      ObjectFlagProperty<ErrorBuilder?>.has('errorBuilder', errorBuilder),
    );
    properties.add(
      ObjectFlagProperty<WidgetBuilder?>.has(
        'placeholderBuilder',
        placeholderBuilder,
      ),
    );
    properties.add(
      ObjectFlagProperty<void Function(BoundsList boundsData)?>.has(
        'onBoundsCalculated',
        onBoundsCalculated,
      ),
    );
    properties.add(
        ObjectFlagProperty<void Function()?>.has('onTapOutside', onTapOutside));
  }
}

class _InteractiveSvgViewState extends State<InteractiveSvgView> {
  final GlobalKey _sizedKey = GlobalKey();

  late final BoundsFactory boundsFactory;

  AsyncSnapshot<RegionList> _regionSnapshot = const AsyncSnapshot.nothing();

  @override
  void initState() {
    super.initState();
    boundsFactory = LazyBoundsFactory(
      key: _sizedKey,
      parserDelegate: widget.parserDelegate,
    );
    load();
    boundsFactory.addListener(_onBoundsCalculated);
  }

  @override
  void dispose() {
    boundsFactory.removeListener(_onBoundsCalculated);
    boundsFactory.dispose();
    super.dispose();
  }

  /// Internal handler invoked when the bounds factory finishes calculating bounds.
  ///
  /// If `widget.shouldRebuildWhenBoundsCalculated` is true, triggers a rebuild.
  /// Also forwards `_boundsFactory.data` to `widget.onBoundsCalculated` if provided.
  void _onBoundsCalculated() {
    if (widget.shouldRebuildWhenBoundsCalculated) {
      setState(() {});
    }
    if (widget.onBoundsCalculated != null && boundsFactory.hasData) {
      widget.onBoundsCalculated?.call(boundsFactory.data);
    }
  }

  Future<void> _loadBounds() async {
    if (widget.parserDelegate.hasTouchableItem || widget.onTap != null) {
      boundsFactory.load();
    }
  }

  void load() {
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      try {
        setState(() {
          _regionSnapshot = const AsyncSnapshot.waiting();
          boundsFactory.reset(widget.parserDelegate);
        });
        await widget.parserDelegate.loadAssets(context);
        if (!mounted) return;
        final data = widget.parserDelegate.parseSvg();
        unawaited(_loadBounds());
        setState(
          () => _regionSnapshot =
              AsyncSnapshot.withData(ConnectionState.done, data),
        );
      } catch (e, st) {
        debugPrint('$e');
        debugPrintStack(stackTrace: st);
        if (!mounted) return;
        setState(
          () => _regionSnapshot =
              AsyncSnapshot.withError(ConnectionState.done, e, st),
        );
      }
    });
  }

  @override
  void didUpdateWidget(covariant InteractiveSvgView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.parserDelegate.isChanged(oldWidget.parserDelegate)) {
      load();
    }
  }

  /// Builds the placeholder widget used while the SVG is loading.
  Widget _buildPlaceholder(BuildContext context) =>
      widget.placeholderBuilder != null
          ? widget.placeholderBuilder!(context)
          : const SizedBox.shrink();

  /// Builds an error widget. Prefers `widget.errorBuilder`, then `widget.placeholderBuilder`.
  Widget _buildError(
    BuildContext context, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(context, error, stackTrace);
    }
    if (widget.placeholderBuilder != null) {
      return widget.placeholderBuilder!(context);
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) =>
      switch (_regionSnapshot.connectionState) {
        ConnectionState.none ||
        ConnectionState.waiting =>
          _buildPlaceholder(context),
        ConnectionState.active || ConnectionState.done => Builder(
            builder: (context) {
              if (_regionSnapshot.hasError) {
                return _buildError(
                  context,
                  _regionSnapshot.error,
                  _regionSnapshot.stackTrace,
                );
              }
              final data = _regionSnapshot.data;
              if (data == null) return _buildPlaceholder(context);
              return FittedBox(
                alignment: widget.alignment,
                fit: widget.fit,
                child: _SvgView(
                  key: _sizedKey,
                  lazyBounds: boundsFactory,
                  background: data[null],
                  alignment: Alignment.topLeft,
                  fit: BoxFit.contain,
                  regions: data.entries
                      .where(
                        (element) =>
                            element.key != null &&
                            element.value.selector != null,
                      )
                      .map((e) => e.value),

                  /// FittedBox handled UI scale and fit.
                  // alignment: widget.alignment,
                  // fit: widget.fit,
                  interactiveBuilder: widget.interactiveBuilder,
                  maskerBuilder: widget.markerBuilder,
                  onTap: widget.onTap?.call,
                  onTapOutside: widget.onTapOutside,
                ),
              );
            },
          )
      };

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<BoundsFactory>('boundsFactory', boundsFactory),
    );
  }
}

class _SvgView extends StatefulWidget {
  const _SvgView({
    required GlobalKey super.key,
    required this.background,
    required this.regions,
    this.alignment = Alignment.topLeft,
    this.fit = BoxFit.contain,
    this.interactiveBuilder,
    this.onTap,
    this.onTapOutside,
    required this.lazyBounds,
    this.maskerBuilder,
  });

  /// Background (non-interactive) SVG region that is rendered behind the interactive regions.
  final SvgRegion? background;

  /// Iterable of parsed SVG regions (each should carry an [InteractiveSelector] on its metadata).
  final Iterable<SvgRegion> regions;

  /// Alignment used when rendering each SVG piece.
  final Alignment alignment;

  /// Fit mode applied to each [SvgPicture].
  final BoxFit fit;

  /// Optional builder to wrap each region (same as [InteractiveSvgView.interactiveBuilder]).
  final InteractiveBuilder? interactiveBuilder;

  /// Optional onTap handler invoked when a touchable region is tapped.
  final void Function(InteractiveSelector selector)? onTap;

  /// Optional onTapOutside handler invoked when a tap occurs outside any touchable region.
  final void Function()? onTapOutside;

  /// Lazy bounds factory used to compute and provide bounds for touchable regions.
  final BoundsFactory lazyBounds;

  /// Optional masker/overlay builder.
  final MarkerBuilder? maskerBuilder;

  @override
  State<_SvgView> createState() => _SvgViewState();

  // Added: expose important fields to Flutter diagnostics.
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<SvgRegion?>(
        'background',
        background,
        defaultValue: null,
      ),
    );
    properties.add(
      IterableProperty<SvgRegion>(
        'regions',
        regions,
        level: DiagnosticLevel.debug,
      ),
    );
    properties.add(DiagnosticsProperty<Alignment>('alignment', alignment));
    properties.add(DiagnosticsProperty<BoxFit>('fit', fit));
    properties.add(
      FlagProperty(
        'hasInteractiveBuilder',
        value: interactiveBuilder != null,
        ifTrue: 'true',
        ifFalse: 'false',
      ),
    );
    properties.add(
      FlagProperty(
        'hasOnTap',
        value: onTap != null,
        ifTrue: 'true',
        ifFalse: 'false',
      ),
    );
    properties.add(
      DiagnosticsProperty<BoundsFactory>(
        'lazyBounds',
        lazyBounds,
        ifNull: 'null',
      ),
    );
    properties.add(
      FlagProperty(
        'hasMaskerBuilder',
        value: maskerBuilder != null,
        ifTrue: 'true',
        ifFalse: 'false',
      ),
    );
    properties.add(
        ObjectFlagProperty<void Function()?>.has('onTapOutside', onTapOutside));
  }
}

class _SvgViewState extends State<_SvgView> {
  @override
  Widget build(BuildContext context) => SizeReporter(
        onSizeChanged: (size) {
          widget.lazyBounds
              .resolve(size, alignment: widget.alignment, fit: widget.fit);
        },
        child: GestureDetector(
          onTapUp: onTap,
          child: Stack(
            fit: StackFit.loose,
            children: [
              if (widget.background != null)
                _buildSvg(null, widget.background!.svg),
              ...widget.regions.map(
                (e) {
                  final selector = e.selector!;
                  if (widget.interactiveBuilder != null) {
                    return widget.interactiveBuilder!(
                      context,
                      () => _buildSvg(selector.id, e.svg),
                      SvgRegionsDetails(
                        selector: selector,
                        bounds: widget.lazyBounds.data[selector],
                      ),
                    );
                  }
                  return _buildSvg(selector.id, e.svg);
                },
              ),
              if (widget.maskerBuilder != null)
                ...widget.maskerBuilder!(context),
            ],
          ),
        ),
      );

  /// Builds an [SvgPicture] from raw SVG string [data]. If [key] is null, a background key is used.
  Widget _buildSvg(String? key, String data) => SvgPicture.string(
        key: (key != null) ? ValueKey(key) : const ValueKey('__bg__'),
        data,
        fit: widget.fit,
        alignment: widget.alignment,
      );

  /// Handles tap events and maps the tap position to any touchable region using precomputed bounds.
  ///
  /// The function iterates regions in reverse order (topmost rendered region first),
  /// checks whether computed bounds contain the touch position and, if so, calls `widget.onTap`.
  void onTap(TapUpDetails details) {
    if (widget.onTap == null && widget.onTapOutside == null) return;
    final regions = widget.regions;
    if (regions.isEmpty) return;

    if (!widget.lazyBounds.hasData) {
      debugPrint('Bounds not ready, cannot process tap.');
      return;
    }

    final bounds = widget.lazyBounds.data;
    final touchPosition = details.localPosition;

    // Iterate regions in reverse render order to respect z-order (topmost first).
    final regionList = regions.toList();
    var isHandled = false;
    for (var i = regionList.length - 1; i >= 0; i--) {
      final selector = regionList[i].selector;
      if (selector == null || selector.type != InteractiveType.touchable) {
        continue;
      }
      final svgBounds = bounds[selector];
      if (svgBounds == null) continue;
      if (svgBounds.contains(touchPosition)) {
        isHandled = true;
        widget.onTap?.call(selector);
        break;
      }
    }
    if (!isHandled) {
      widget.onTapOutside?.call();
    }
  }
}
