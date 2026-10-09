import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_svg/interactive_svg.dart';
import 'package:xml/xml.dart';

void main() {
  final document = XmlDocument.parse('''
    <svg>
      <g id="parent-a"><path id="shared"/></g>
      <g id="parent-b"><rect id="shared"/></g>
    </svg>
  ''');

  group('InteractiveSelector.byID', () {
    test('finds an element by id across all tags', () {
      const selector = InteractiveSelector.byID(id: 'shared');

      final result = selector(document);

      expect(result, isA<XmlElement>());
      expect((result! as XmlElement).name.local, 'path');
      expect(selector.label, 'shared');
    });

    test('restricts matching to the configured tag', () {
      const selector = InteractiveSelector.byID(id: 'shared', tag: 'rect');

      final result = selector(document);

      expect(result, isA<XmlElement>());
      expect((result! as XmlElement).name.local, 'rect');
    });

    test('returns null when no element matches', () {
      const selector = InteractiveSelector.byID(id: 'missing');

      expect(selector(document), isNull);
    });
  });

  group('InteractiveSelector.byIDAndParent', () {
    test('searches only inside the selected parent', () {
      const selector = InteractiveSelector.byIDAndParent(
        id: 'shared',
        parentSelector: InteractiveSelector.byID(id: 'parent-b'),
      );

      final result = selector(document);

      expect(result, isA<XmlElement>());
      expect((result! as XmlElement).name.local, 'rect');
      expect(selector.label, 'parent-b > shared');
    });
  });

  test('equality uses id and interaction type', () {
    const touchable = InteractiveSelector.byID(
      id: 'shared',
      type: InteractiveType.touchable,
    );
    const sameIdentity = InteractiveSelector.byID(
      id: 'shared',
      label: 'Another label',
      type: InteractiveType.touchable,
      tag: 'rect',
    );
    const viewOnly = InteractiveSelector.byID(id: 'shared');

    expect(touchable, sameIdentity);
    expect(touchable.hashCode, sameIdentity.hashCode);
    expect(touchable, isNot(viewOnly));
  });
}
