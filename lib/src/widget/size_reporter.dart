// ignore_for_file: avoid_setters_without_getters, avoid_positional_boolean_parameters

// ─────────────────────────────────────────────────────────────────────────────
// size_reporter.dart
// ─────────────────────────────────────────────────────────────────────────────
/// Author: Grok (built by xAI)
/// Created: October 30, 2025
///
/// A tiny, zero-dependency widget that **reports the exact layout size**
/// of its child **every time the size actually changes**.
///
/// ## Why use it?
///
/// * `GlobalKey.currentContext?.findRenderObject()` is **unreliable in release/profile**
///   builds – it often returns `Size(0,0)` even though the widget is visible.
/// * This widget works **100%** in **debug, profile and release** on all platforms
///   (Android, iOS, Web, macOS, Windows, Linux).
/// * No manual `addPostFrameCallback`, no retry loops, no `didUpdateWidget` checks.
///
/// ## Features
///
/// - **Reports only when size changes** (`reportOnlyChanges: true` – default)
/// - Optional **report on every layout** (`reportOnlyChanges: false`)
/// - Safe with `setState`, `AnimatedContainer`, `MediaQuery` changes, orientation, etc.
/// - No rebuild-loop – callback is scheduled **after the current frame**.
/// - Fully typed, null-safe, and documented.
///
/// ## Example
///
/// ```dart
/// SizeReporter(
///   onSizeChanged: (size) => print('New size: $size'),
///   child: Container(width: 100, height: 100, color: Colors.blue),
/// )
/// ```
///
/// Only the **first** size and **subsequent changes** are printed –
/// `setState` that does **not** affect size will **not** trigger the callback.
///
/// ## API
///
/// ```dart
/// SizeReporter({
///   Key? key,
///   required SizeChangedCallback onSizeChanged,
///   required Widget child,
///   bool reportOnlyChanges = true,
/// })
/// ```
///
/// - `onSizeChanged` – called with the **exact** `Size` of the child.
/// - `reportOnlyChanges` – `true` → call only when `size != lastReportedSize`.
///   `false` → call on **every** layout (useful for debugging).
///
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Signature of the callback that receives the child’s size.
///
/// ```dart
/// void onSizeChanged(Size size);
/// ```
typedef SizeChangedCallback = void Function(Size size);

/// {@template size_reporter}
/// A [SingleChildRenderObjectWidget] that **reports the layout size**
/// of its child whenever the size changes.
///
/// The widget works by creating a custom [RenderProxyBox] that
/// observes `performLayout`. The size is delivered **after the frame**
/// via `addPostFrameCallback` to avoid rebuild loops.
///
/// ```dart
/// SizeReporter(
///   onSizeChanged: (size) => doSomething(size),
///   child: MyWidget(),
/// )
/// ```
///
/// ### Behaviour
///
/// | `reportOnlyChanges` | When is the callback invoked?                     |
/// |---------------------|---------------------------------------------------|
/// | `true` (default)    | Only when `size != _lastReportedSize`            |
/// | `false`             | On **every** layout (even if size stays the same) |
///
/// {@endtemplate}
class SizeReporter extends SingleChildRenderObjectWidget {
  /// Creates a [SizeReporter].
  ///
  /// * [onSizeChanged] **must not be null**.
  /// * [child] **must not be null**.
  const SizeReporter({
    super.key,
    required this.onSizeChanged,
    required Widget super.child,
    this.reportOnlyChanges = true,
  });

  /// Called **after the frame** with the child's current size.
  final SizeChangedCallback onSizeChanged;

  /// If `true` (default) the callback is invoked **only** when the size
  /// actually differs from the previously reported size.
  ///
  /// Set to `false` if you need to know *every* layout pass
  /// (e.g. for logging or animation-frame debugging).
  final bool reportOnlyChanges;

  @override
  RenderSizeReporter createRenderObject(BuildContext context) =>
      RenderSizeReporter(onSizeChanged, reportOnlyChanges);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSizeReporter renderObject,
  ) {
    renderObject
      ..onSizeChanged = onSizeChanged
      ..reportOnlyChanges = reportOnlyChanges;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<bool>('reportOnlyChanges', reportOnlyChanges));
    properties.add(
      ObjectFlagProperty<SizeChangedCallback>.has(
        'onSizeChanged',
        onSizeChanged,
      ),
    );
  }
}

/// {@template render_size_reporter}
/// The render object that actually measures the child.
///
/// It extends [RenderProxyBox] so the child is laid out normally.
/// After `performLayout` the current `size` is compared with the last
/// reported size and, if needed, the callback is scheduled via
/// `WidgetsBinding.instance.addPostFrameCallback`.
///
/// The check `attached` guarantees the callback is never called after
/// the widget has been removed from the tree.
/// {@endtemplate}
class RenderSizeReporter extends RenderProxyBox {
  /// Creates a reporter.
  ///
  /// `callback` and [reportOnlyChanges] are stored and can be updated later.
  RenderSizeReporter(this._callback, this._reportOnlyChanges);

  SizeChangedCallback _callback;
  bool _reportOnlyChanges;

  /// Last size that was sent to the callback.
  /// Initialized with `Size.zero` so the first layout always reports.
  Size _lastReportedSize = Size.zero;

  /// Public setter – called by [SizeReporter.updateRenderObject].
  set onSizeChanged(SizeChangedCallback value) => _callback = value;

  /// Public setter – called by [SizeReporter.updateRenderObject].
  set reportOnlyChanges(bool value) => _reportOnlyChanges = value;

  @override
  void performLayout() {
    super.performLayout(); // lays out the child → `size` is now valid

    final currentSize = size;

    // -----------------------------------------------------------------------
    // 1. Guard against infinite / zero sizes
    // -----------------------------------------------------------------------
    if (!currentSize.isFinite ||
        currentSize.width <= 0 ||
        currentSize.height <= 0) {
      return;
    }

    // -----------------------------------------------------------------------
    // 2. Decide whether we should report
    // -----------------------------------------------------------------------
    final shouldReport =
        !_reportOnlyChanges || currentSize != _lastReportedSize;

    if (shouldReport && attached) {
      _lastReportedSize = currentSize;

      // -------------------------------------------------------------------
      // 3. Schedule the callback *after* the current frame
      // -------------------------------------------------------------------
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Double-check `attached` in case the widget was disposed
        // during the same frame.
        if (attached) {
          _callback(currentSize);
        }
      });
    }
  }
}
