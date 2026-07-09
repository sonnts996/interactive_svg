/*
 Created by sonnts996 on 19/10/25.
 Copyright (c) 2025 . All rights reserved.
 MIT License
 Modified by Lyana Goedtkindt (lyana.goedtkindt@ch.abb.com)
*/

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:vector_math/vector_math_64.dart' as v;

/// Parses a single SVG group/element and composes a union [Path] suitable for hit-testing.
///
/// The returned [Path] is a union of drawable shapes found inside [data]. If any
/// transform attributes exist on the element or its parents (matrix(...)), the
/// first found transform is applied to the composed path. Mask and clip-path are
/// respected where possible. If no drawable content is found this function returns null.
Path? parseBoundsFromSvg(XmlNode data) {
  final subpaths = collectDrawablePaths(data);
  Matrix4? transform;
  XmlNode? current = data;
  while (current != null) {
    final transformStr = current.getAttribute('transform');
    if (transformStr != null) {
      transform = parseTransform(transformStr);
      break;
    }
    current = current.parentElement;
  }

  if (subpaths.isNotEmpty) {
    var combinedUnion = Path();
    for (final p in subpaths) {
      combinedUnion.addPath(p, Offset.zero);
    }

// Handle stroke if present
    final strokeWidth =
        double.tryParse(data.getAttribute('stroke-width') ?? '0') ?? 0;
    if (strokeWidth > 0) {
      final strokedPath = Path();
      strokedPath.addPath(combinedUnion, Offset.zero);
      combinedUnion =
          Path.combine(PathOperation.union, combinedUnion, strokedPath);
    }

    if (transform != null) {
      combinedUnion = combinedUnion.transform(transform.storage);
    }

    return combinedUnion;
  }

  return null;
}

/// Collects all drawable paths from an [XmlNode] recursively, applying inner clip-path and mask.
///
/// This traverses supported shape elements and groups, ignoring elements with display="none"
/// or visibility="hidden", and skipping contents of <mask> when [skipMasks] is true.
///
/// Returns a list of [Path] objects extracted from the node and its children.
List<Path> collectDrawablePaths(XmlNode node, {bool skipMasks = true}) {
  final paths = <Path>[];
  if (node is! XmlElement) return paths;

  final element = node;
  final tag = element.name.local;

// Skip if display="none" or visibility="hidden"
  if (element.getAttribute('display') == 'none' ||
      element.getAttribute('visibility') == 'hidden') {
    return paths;
  }

// Skip invisible rect
  if (tag == 'rect' &&
      element.getAttribute('opacity') == '0' &&
      element.getAttribute('fill') == 'none' &&
      element.getAttribute('stroke') == 'none') {
    return paths;
  }

// Skip contents inside <mask> when skipMasks=true
  if (skipMasks && tag == 'mask') return paths;

  Path? shapePath;
  try {
    if (tag == 'path') {
      final d = element.getAttribute('d') ?? '';
      if (d.isNotEmpty) shapePath = parseSvgPathData(d);
    } else if (tag == 'rect') {
      shapePath = parseRect(element);
    } else if (tag == 'circle') {
      shapePath = parseCircle(element);
    } else if (tag == 'ellipse') {
      shapePath = parseEllipse(element);
    } else if (tag == 'polygon') {
      shapePath = parsePolygon(element);
    } else if (tag == 'polyline') {
      shapePath = parsePolyline(element);
    } else if (tag == 'line') {
      shapePath = parseLine(element);
    } else if (tag == 'use') {
      shapePath = parseUse(element);
    } else if (tag == 'g') {
// Iterate children of <g> without creating a direct shapePath
    } else {
      return paths; // Skip tags that are not shapes
    }

// Apply inner clip-path and mask if present
    if (shapePath != null) {
      final localTransform = parseTransform(element.getAttribute('transform'));
      if (localTransform != null && tag != 'path') {
        shapePath = shapePath.transform(localTransform.storage);
      }

// Check clip-path on element
      final clipPathUrl = element
          .getAttribute('clip-path')
          ?.replaceFirst('url(#', '')
          .replaceFirst(')', '');
      if (clipPathUrl != null) {
        final clipNode =
            element.document?.findAllElements('clipPath').firstWhereOrNull(
                  (e) => e.getAttribute('id') == clipPathUrl,
                );
        if (clipNode != null) {
          final clipSubpaths = collectDrawablePaths(clipNode, skipMasks: false);
          if (clipSubpaths.isNotEmpty) {
            final clipCombined = Path();
            for (final p in clipSubpaths) {
              clipCombined.addPath(p, Offset.zero);
            }
            final clipRule = clipNode.getAttribute('clip-rule') ?? 'nonzero';
            clipCombined.fillType = clipRule == 'evenodd'
                ? PathFillType.evenOdd
                : PathFillType.nonZero;
            shapePath =
                Path.combine(PathOperation.intersect, shapePath, clipCombined);
          }
        }
      }

// Check mask on element
      final maskUrl = element
          .getAttribute('mask')
          ?.replaceFirst('url(#', '')
          .replaceFirst(')', '');
      if (maskUrl != null) {
        final maskNode =
            element.document?.findAllElements('mask').firstWhereOrNull(
                  (e) => e.getAttribute('id') == maskUrl,
                );
        if (maskNode != null) {
          final maskSubpaths = collectDrawablePaths(maskNode, skipMasks: false);
          if (maskSubpaths.isNotEmpty) {
            final maskCombined = Path();
            for (final p in maskSubpaths) {
              maskCombined.addPath(p, Offset.zero);
            }
            shapePath =
                Path.combine(PathOperation.intersect, shapePath, maskCombined);
          }
        }
      }

      paths.add(shapePath);
    }
  } catch (e) {
    debugPrint('Invalid $tag data: $e');
  }

// Recurse into children
  for (final child in element.children) {
    paths.addAll(collectDrawablePaths(child, skipMasks: skipMasks));
  }

  return paths;
}

/// Parses a transform attribute string into a [Matrix4].
///
/// Supports matrix(a,b,c,d,tx,ty) format. Returns null if input is null or unsupported.
Matrix4? parseTransform(String? transformStr) {
  if (transformStr == null || transformStr.isEmpty) return null;
  try {
    if (transformStr.startsWith('matrix(')) {
      final values = transformStr
          .replaceFirst('matrix(', '')
          .replaceFirst(')', '')
          .split(RegExp(r'\s+|,'))
          .map((s) => double.tryParse(s) ?? 0.0)
          .toList();
      if (values.length >= 6) {
        return Matrix4(
          values[0],
          values[1],
          0,
          0,
          values[2],
          values[3],
          0,
          0,
          0,
          0,
          1,
          0,
          values[4],
          values[5],
          0,
          1,
        );
      }
    }
  } catch (e) {
    debugPrint('Invalid transform format: $transformStr');
  }
  return null;
}

/// Parse a <rect> element into a [Path].
Path parseRect(XmlNode e) => Path()
  ..addRect(
    Rect.fromLTWH(
      double.tryParse(e.getAttribute('x') ?? '0') ?? 0,
      double.tryParse(e.getAttribute('y') ?? '0') ?? 0,
      double.tryParse(e.getAttribute('width') ?? '0') ?? 0,
      double.tryParse(e.getAttribute('height') ?? '0') ?? 0,
    ),
  );

/// Parse a <circle> element into a [Path].
Path parseCircle(XmlNode e) {
  final center = Offset(
    double.tryParse(e.getAttribute('cx') ?? '0') ?? 0,
    double.tryParse(e.getAttribute('cy') ?? '0') ?? 0,
  );
  final radius = double.tryParse(e.getAttribute('r') ?? '0') ?? 0;
  return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
}

/// Parse an <ellipse> element into a [Path].
Path parseEllipse(XmlNode e) {
  final center = Offset(
    double.tryParse(e.getAttribute('cx') ?? '0') ?? 0,
    double.tryParse(e.getAttribute('cy') ?? '0') ?? 0,
  );
  final rx = double.tryParse(e.getAttribute('rx') ?? '0') ?? 0;
  final ry = double.tryParse(e.getAttribute('ry') ?? '0') ?? 0;
  return Path()
    ..addOval(Rect.fromCenter(center: center, width: rx * 2, height: ry * 2));
}

/// Parse a <polygon> element into a closed [Path].
Path parsePolygon(XmlNode e) {
  final pointsStr = e.getAttribute('points') ?? '';
  final points = pointsStr
      .split(RegExp(r'\s+|,'))
      .map(double.tryParse)
      .where((e) => e != null)
      .cast<double>()
      .toList();
  if (points.length < 4 || points.length % 2 != 0) return Path();
  final path = Path();
  for (var i = 0; i < points.length; i += 2) {
    if (i == 0) {
      path.moveTo(points[i], points[i + 1]);
    } else {
      path.lineTo(points[i], points[i + 1]);
    }
  }
  path.close();
  return path;
}

/// Parse a <polyline> element into a [Path] (open).
Path parsePolyline(XmlNode e) {
  final pointsStr = e.getAttribute('points') ?? '';
  final points = pointsStr
      .split(RegExp(r'\s+|,'))
      .map(double.tryParse)
      .where((e) => e != null)
      .cast<double>()
      .toList();
  if (points.length < 4 || points.length % 2 != 0) return Path();
  final path = Path();
  for (var i = 0; i < points.length; i += 2) {
    if (i == 0) {
      path.moveTo(points[i], points[i + 1]);
    } else {
      path.lineTo(points[i], points[i + 1]);
    }
  }
  return path;
}

/// Parse a <line> element into a [Path].
Path parseLine(XmlNode e) {
  final x1 = double.tryParse(e.getAttribute('x1') ?? '0') ?? 0;
  final y1 = double.tryParse(e.getAttribute('y1') ?? '0') ?? 0;
  final x2 = double.tryParse(e.getAttribute('x2') ?? '0') ?? 0;
  final y2 = double.tryParse(e.getAttribute('y2') ?? '0') ?? 0;
  final path = Path()
    ..moveTo(x1, y1)
    ..lineTo(x2, y2);
  return path;
}

/// Parse a <use> element by resolving its referenced element and combining its paths.
///
/// Returns a combined [Path] of referenced content, or null if reference not found.
Path? parseUse(XmlElement e) {
  final href = e.getAttribute('href')?.replaceFirst('#', '') ??
      e.getAttribute('xlink:href')?.replaceFirst('#', '') ??
      '';
  if (href.isEmpty) return null;
  final referenced = e.document?.findAllElements('*').firstWhereOrNull(
        (el) => el.getAttribute('id') == href,
      );
  if (referenced != null) {
    final subpaths = collectDrawablePaths(referenced);
    if (subpaths.isNotEmpty) {
      final combined = Path();
      for (final p in subpaths) {
        combined.addPath(p, Offset.zero);
      }
      return combined;
    }
  }
  return null;
}

/// Scales and translates [path] from [viewBox] coordinate space to [size] using [fit] and [alignment].
///
/// If [size] or [viewBox] is null, returns the original path.
Path scaleBounds(
  Path path, {
  Rect? viewBox,
  Size? size,
  BoxFit fit = BoxFit.none,
  Alignment alignment = Alignment.topLeft,
}) {
  if (size != null &&
      size != Size.zero &&
      viewBox != null &&
      viewBox.size != Size.zero) {
    var scaleX = size.width / viewBox.width;
    var scaleY = size.height / viewBox.height;
    var translateX = -viewBox.left;
    var translateY = -viewBox.top;

    switch (fit) {
      case BoxFit.contain:
        final scale = scaleX < scaleY ? scaleX : scaleY;
        scaleX = scale;
        scaleY = scale;
        translateX += (size.width - viewBox.width * scale) *
            (alignment.x + 1) /
            2 /
            scaleX;
        translateY += (size.height - viewBox.height * scale) *
            (alignment.y + 1) /
            2 /
            scaleY;
      case BoxFit.cover:
        final scale = scaleX > scaleY ? scaleX : scaleY;
        scaleX = scale;
        scaleY = scale;
        translateX += (size.width - viewBox.width * scale) *
            (alignment.x + 1) /
            2 /
            scaleX;
        translateY += (size.height - viewBox.height * scale) *
            (alignment.y + 1) /
            2 /
            scaleY;
      case BoxFit.fitWidth:
        scaleY = scaleX;
        translateX += (size.width - viewBox.width * scaleX) *
            (alignment.x + 1) /
            2 /
            scaleX;
        translateY += (size.height - viewBox.height * scaleX) *
            (alignment.y + 1) /
            2 /
            scaleY;
      case BoxFit.fitHeight:
        scaleX = scaleY;
        translateX += (size.width - viewBox.width * scaleY) *
            (alignment.x + 1) /
            2 /
            scaleX;
        translateY += (size.height - viewBox.height * scaleY) *
            (alignment.y + 1) /
            2 /
            scaleY;
      case BoxFit.fill:
        translateX += (size.width - viewBox.width * scaleX) *
            (alignment.x + 1) /
            2 /
            scaleX;
        translateY += (size.height - viewBox.height * scaleY) *
            (alignment.y + 1) /
            2 /
            scaleY;
      case BoxFit.none:
        scaleX = 1.0;
        scaleY = 1.0;
        translateX += (size.width - viewBox.width) * (alignment.x + 1) / 2;
        translateY += (size.height - viewBox.height) * (alignment.y + 1) / 2;
      case BoxFit.scaleDown:
        final scale = scaleX < scaleY ? scaleX : scaleY;
        scaleX = scale < 1.0 ? scale : 1.0;
        scaleY = scale < 1.0 ? scale : 1.0;
        translateX += (size.width - viewBox.width * scaleX) *
            (alignment.x + 1) /
            2 /
            scaleX;
        translateY += (size.height - viewBox.height * scaleY) *
            (alignment.y + 1) /
            2 /
            scaleY;
    }

    final scaleMatrix = Matrix4.identity()
      ..translateByVector3(v.Vector3(translateX, translateY, 0))
      ..scaleByVector3(v.Vector3(scaleX, scaleY, 1));
    return path.transform(scaleMatrix.storage);
  }
  return path;
}
