import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_svg/interactive_svg.dart';
import 'package:interactive_svg/src/interactive_parser.dart';
import 'package:xml/xml.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InteractiveParser', () {
    test('loads a string provider and reads the viewBox', () async {
      final parser = InteractiveParser.provider(
        provider: const InteractiveSvgProvider.string(_svg),
      );

      await parser.loadAssets(_FakeBuildContext());

      expect(
        parser.currentContext?.viewBox,
        const Rect.fromLTWH(0, 0, 100, 50),
      );
    });

    test('extracts selected regions from the background', () async {
      const selector = InteractiveSelector.byID(
        id: 'button',
        type: InteractiveType.touchable,
      );
      final parser = InteractiveParser.provider(
        provider: const InteractiveSvgProvider.string(_svg),
        selectors: const [selector],
      );
      await parser.loadAssets(_FakeBuildContext());

      final regions = parser.parseSvg();
      final selectedDocument = XmlDocument.parse(regions[selector]!.svg);
      final backgroundDocument = XmlDocument.parse(regions[null]!.svg);

      expect(
        selectedDocument.findAllElements('*').where(
              (element) => element.getAttribute('id') == 'button',
            ),
        isNotEmpty,
      );
      expect(
        backgroundDocument.findAllElements('*').where(
              (element) => element.getAttribute('id') == 'button',
            ),
        isEmpty,
      );
      expect(
        backgroundDocument.findAllElements('*').where(
              (element) => element.getAttribute('id') == 'decoration',
            ),
        isNotEmpty,
      );
    });

    test('computes bounds only for touchable and bounds-only selectors',
        () async {
      const touchable = InteractiveSelector.byID(
        id: 'button',
        type: InteractiveType.touchable,
      );
      const boundsOnly = InteractiveSelector.byID(
        id: 'anchor',
        type: InteractiveType.boundsOnly,
      );
      const viewOnly = InteractiveSelector.byID(id: 'decoration');
      final parser = InteractiveParser.provider(
        provider: const InteractiveSvgProvider.string(_svg),
        selectors: const [touchable, boundsOnly, viewOnly],
      );
      await parser.loadAssets(_FakeBuildContext());

      final bounds = parser.parseSvgBounds();

      expect(
        bounds.keys,
        containsAll(<InteractiveSelector>[touchable, boundsOnly]),
      );
      expect(bounds.containsKey(viewOnly), isFalse);
      expect(
        bounds[touchable]!.getBounds(),
        const Rect.fromLTWH(10, 5, 20, 10),
      );
    });

    test('scales parsed bounds into widget coordinates', () async {
      const selector = InteractiveSelector.byID(
        id: 'button',
        type: InteractiveType.touchable,
      );
      final parser = InteractiveParser.provider(
        provider: const InteractiveSvgProvider.string(_svg),
        selectors: const [selector],
      );
      await parser.loadAssets(_FakeBuildContext());

      final scaled = parser.scaleSvgBounds(
        parser.parseSvgBounds(),
        size: const Size(200, 100),
      );

      expect(
        scaled[selector]!.getBounds(),
        const Rect.fromLTWH(20, 10, 40, 20),
      );
    });

    test('detects provider and selector changes', () {
      const selector = InteractiveSelector.byID(
        id: 'button',
        type: InteractiveType.touchable,
      );
      final parser = InteractiveParser.provider(
        provider: const InteractiveSvgProvider.string(_svg),
        selectors: const [selector],
      );
      final equivalent = InteractiveParser.provider(
        provider: const InteractiveSvgProvider.string(_svg),
        selectors: const [selector],
      );
      final changedSource = InteractiveParser.provider(
        provider: const InteractiveSvgProvider.string('<svg/>'),
        selectors: const [selector],
      );
      final changedSelectors = InteractiveParser.provider(
        provider: const InteractiveSvgProvider.string(_svg),
      );

      expect(parser.isChanged(equivalent), isFalse);
      expect(parser.isChanged(changedSource), isTrue);
      expect(parser.isChanged(changedSelectors), isTrue);
    });

    test('preserves the legacy asset constructor contract', () {
      final parser = InteractiveParser(asset: 'assets/map.svg');
      final stringParser = InteractiveParser.provider(
        provider: const InteractiveSvgProvider.string('<svg/>'),
      );

      expect(parser.asset, 'assets/map.svg');
      expect(() => stringParser.asset, throwsStateError);
    });
  });
}

/// Supplies the context ignored by the in-memory SVG provider.
/// Cung cấp context được SVG provider trong bộ nhớ bỏ qua.
final class _FakeBuildContext extends Fake implements BuildContext {}

const _svg = '''
<svg viewBox="0 0 100 50" xmlns="http://www.w3.org/2000/svg">
  <rect id="button" x="10" y="5" width="20" height="10"/>
  <circle id="anchor" cx="50" cy="20" r="5"/>
  <path id="decoration" d="M 0 0 L 5 0 L 5 5 Z"/>
</svg>
''';
