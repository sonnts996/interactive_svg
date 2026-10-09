import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_svg/src/parsers/bounds_parser_utilities.dart';
import 'package:xml/xml.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('shape parsers', () {
    test('parses rect, circle, ellipse, polygon, polyline, and line', () {
      expect(
        parseRect(_parseElement('<rect x="1" y="2" width="3" height="4"/>'))
            .getBounds(),
        const Rect.fromLTWH(1, 2, 3, 4),
      );
      expect(
        parseCircle(_parseElement('<circle cx="5" cy="6" r="2"/>')).getBounds(),
        const Rect.fromLTRB(3, 4, 7, 8),
      );
      expect(
        parseEllipse(_parseElement('<ellipse cx="5" cy="6" rx="3" ry="2"/>'))
            .getBounds(),
        const Rect.fromLTRB(2, 4, 8, 8),
      );
      expect(
        parsePolygon(_parseElement('<polygon points="0,0 10,0 10,5 0,5"/>'))
            .getBounds(),
        const Rect.fromLTRB(0, 0, 10, 5),
      );
      expect(
        parsePolyline(_parseElement('<polyline points="1,2 4,6 8,3"/>'))
            .getBounds(),
        const Rect.fromLTRB(1, 2, 8, 6),
      );
      expect(
        parseLine(_parseElement('<line x1="2" y1="3" x2="8" y2="9"/>'))
            .getBounds(),
        const Rect.fromLTRB(2, 3, 8, 9),
      );
    });

    test('returns empty paths for invalid point collections', () {
      expect(
        parsePolygon(_parseElement('<polygon points="0,0 10"/>')).getBounds(),
        Rect.zero,
      );
      expect(
        parsePolyline(_parseElement('<polyline points="0,0 10"/>')).getBounds(),
        Rect.zero,
      );
    });

    test('skips hidden and invisible elements', () {
      expect(
        collectDrawablePaths(
          _parseElement('<rect display="none" width="10" height="10"/>'),
        ),
        isEmpty,
      );
      expect(
        collectDrawablePaths(
          _parseElement(
            '<rect opacity="0" fill="none" stroke="none" width="10" height="10"/>',
          ),
        ),
        isEmpty,
      );
    });
  });

  group('parseBoundsFromSvg transforms', () {
    test('applies a path transform exactly once', () {
      final element = _parseElement('''
        <path
          d="M 0 0 L 100 0 L 100 100 L 0 100 Z"
          transform="matrix(0.5,0,0,0.5,10,20)"
        />
      ''');

      final bounds = parseBoundsFromSvg(element)!.getBounds();

      _expectRectClose(bounds, const Rect.fromLTRB(10, 20, 60, 70));
    });

    test('composes nested element and group transforms once', () {
      final element = _parseElement('''
        <g transform="matrix(2,0,0,2,5,7)">
          <rect
            x="1"
            y="2"
            width="3"
            height="4"
            transform="matrix(0.5,0,0,0.5,10,20)"
          />
        </g>
      ''');

      final bounds = parseBoundsFromSvg(element)!.getBounds();

      _expectRectClose(bounds, const Rect.fromLTRB(26, 49, 29, 53));
    });
  });

  group('parseText', () {
    test('creates non-empty bounds from simple SVG text', () {
      final element = _parseElement('''
        <text x="10" y="30" font-size="20">Clickable</text>
      ''');

      final bounds = parseText(element).getBounds();

      expect(bounds.left, closeTo(10, 0.001));
      expect(bounds.top, lessThan(30));
      expect(bounds.right, greaterThan(10));
      expect(bounds.bottom, greaterThan(30));
    });

    test('honors middle and end text anchors', () {
      final middle = parseText(
        _parseElement('''
          <text x="50" y="30" font-size="20" text-anchor="middle">ABC</text>
        '''),
      ).getBounds();
      final end = parseText(
        _parseElement('''
          <text x="50" y="30" font-size="20" text-anchor="end">ABC</text>
        '''),
      ).getBounds();

      expect(middle.center.dx, closeTo(50, 0.001));
      expect(end.right, closeTo(50, 0.001));
    });

    test('reads inherited font attributes from a parent group', () {
      final group = _parseElement('''
        <g font-size="24" font-weight="bold" font-style="italic">
          <text x="5" y="40">Inherited</text>
        </g>
      ''');
      final text = group.findElements('text').single;

      final bounds = parseText(text).getBounds();

      expect(bounds.left, closeTo(5, 0.001));
      expect(bounds.width, greaterThan(0));
      expect(bounds.height, greaterThan(0));
    });

    test('applies a text transform exactly once', () {
      final element = _parseElement('''
        <text
          x="10"
          y="30"
          font-size="20"
          transform="matrix(0.5,0,0,0.5,7,11)"
        >Clickable</text>
      ''');
      final untransformed = parseText(element).getBounds();

      final transformed = parseBoundsFromSvg(element)!.getBounds();

      _expectRectClose(
        transformed,
        Rect.fromLTRB(
          untransformed.left * 0.5 + 7,
          untransformed.top * 0.5 + 11,
          untransformed.right * 0.5 + 7,
          untransformed.bottom * 0.5 + 11,
        ),
      );
    });

    test('creates bounds for the text structure from issue 1', () {
      final element = _parseElement('''
        <text
          x="0"
          y="0"
          transform="matrix(0.03333333333333333,0,0,0.03333333333333333,3.1308243727598573,3.2513440860215055)"
          font-size="26.881720430107528"
          font-family="Cousine-Bold, monospace"
          font-weight="bold"
          id="CodeInput_1"
        >CodeInput_1</text>
      ''');

      final bounds = parseBoundsFromSvg(element)!.getBounds();

      expect(bounds.width, greaterThan(0));
      expect(bounds.height, greaterThan(0));
      expect(bounds.left, closeTo(3.1308243727598573, 0.001));
    });
  });

  group('scaleBounds', () {
    test('contains and aligns an SVG viewBox inside the target size', () {
      final path = Path()..addRect(const Rect.fromLTWH(0, 0, 100, 50));

      final bounds = scaleBounds(
        path,
        viewBox: const Rect.fromLTWH(0, 0, 100, 50),
        size: const Size(300, 300),
        fit: BoxFit.contain,
        alignment: Alignment.center,
      ).getBounds();

      _expectRectClose(bounds, const Rect.fromLTRB(0, 75, 300, 225));
    });

    test('returns the original path when target size is zero', () {
      final path = Path()..addRect(const Rect.fromLTWH(2, 3, 4, 5));

      final scaled = scaleBounds(
        path,
        viewBox: const Rect.fromLTWH(0, 0, 10, 10),
        size: Size.zero,
      );

      expect(scaled, same(path));
    });
  });
}

/// Parses one XML element for a focused bounds unit test.
/// Parse một XML element để kiểm thử bounds độc lập.
XmlElement _parseElement(String source) =>
    XmlDocument.parse(source).rootElement;

/// Verifies every edge while allowing harmless floating-point differences.
/// Kiểm tra từng cạnh và cho phép sai số dấu phẩy động không đáng kể.
void _expectRectClose(Rect actual, Rect expected) {
  expect(actual.left, closeTo(expected.left, 0.001));
  expect(actual.top, closeTo(expected.top, 0.001));
  expect(actual.right, closeTo(expected.right, 0.001));
  expect(actual.bottom, closeTo(expected.bottom, 0.001));
}
