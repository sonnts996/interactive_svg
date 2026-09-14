## 0.0.3

- Upgrade dependencies for Flutter 3.35.5 compatibility.
- Regenerate `copyWith` code with the upgraded generator.

## 0.0.2

- Changes to bounds calculation:
  - Add `SizeReporter` to listen for and accurately confirm size change events.
  - Split bounds loading into two clear steps:
    - `parseSvgBounds`: load and extract raw bounds in SVG viewBox coordinates.
    - `scaleSvgBounds`: scale the extracted bounds into widget coordinates using size, `BoxFit`, and `Alignment`.
  - Compatibility note: `parseSvgBounds` returns unscaled data; call `scaleSvgBounds` to obtain bounds in widget coordinates.

## 0.0.1+1

- Fix bounds transform and scale calculation.

## 0.0.1

- Initial `interactive_svg` source.
