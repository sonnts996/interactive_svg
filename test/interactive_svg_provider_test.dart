import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_svg/interactive_svg.dart';

void main() {
  group('InteractiveSvgProvider equality', () {
    test('string providers compare SVG content', () {
      const first = InteractiveSvgProvider.string('<svg/>');
      const same = InteractiveSvgProvider.string('<svg/>');
      const changed = InteractiveSvgProvider.string('<svg id="changed"/>');

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(changed));
    });

    test('asset, file, and network providers compare their locations', () {
      expect(
        const InteractiveSvgProvider.asset('assets/map.svg'),
        const InteractiveSvgProvider.asset('assets/map.svg'),
      );
      expect(
        const InteractiveSvgProvider.file('/tmp/map.svg'),
        const InteractiveSvgProvider.file('/tmp/map.svg'),
      );
      expect(
        const InteractiveSvgProvider.network('https://example.com/map.svg'),
        const InteractiveSvgProvider.network('https://example.com/map.svg'),
      );
      expect(
        const InteractiveSvgProvider.network('https://example.com/map.svg'),
        isNot(
          const InteractiveSvgProvider.network(
            'https://example.com/changed.svg',
          ),
        ),
      );
    });
  });

  test('string provider loads its in-memory SVG', () async {
    const provider = InteractiveSvgProvider.string('<svg id="memory"/>');

    final result = await provider.load(_FakeBuildContext());

    expect(result, '<svg id="memory"/>');
  });
}

/// Supplies the unused context required by in-memory provider contracts.
/// Cung cấp context không sử dụng theo hợp đồng của provider trong bộ nhớ.
final class _FakeBuildContext extends Fake implements BuildContext {}
