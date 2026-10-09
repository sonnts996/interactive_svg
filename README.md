# Interactive SVG

A lightweight Flutter package for rendering SVGs with selectable, interactive regions, supporting hit-testing, bounds extraction, and zoom/scroll functionality.

![Demo GIF](https://media2.giphy.com/media/v1.Y2lkPTc5MGI3NjExMHR2M2dlMWNia3JqOThqaHE1dXJoMXE1c3pvaW42NnF3ejVzcXptYiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/tO6x4onvnBcdqMgSa2/giphy.gif) <!-- Link to GIF will be added later -->

## Table of Contents
- [Features](#features)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [SVG Authoring Guidelines](#svg-authoring-guidelines)
- [Limitations](#limitations)
- [Features and Bugs](#features-and-bugs)
- [Examples](#examples)
- [Contributing](#contributing)
- [Acknowledgments](#acknowledgments)

## Features
- Render SVGs with interactive regions.
- Select elements by ID or group using `InteractiveSelector`.
- Handle region taps with `onTap` and optional outside taps with `onTapOutside`.
- Support for bounds calculation, lazy bounds, and zoom/scroll wrappers.
- Customizable overlays via `interactiveBuilder`.
- Load SVG documents from Flutter assets, strings, local files, or network URLs.
- Approximate hit-test bounds for simple SVG `<text>` elements.

## Getting Started
### Installation
Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  interactive_svg: ^latest_version
```

Run `flutter pub get` to install.

## Usage
Render an SVG with interactive regions and handle taps with this minimal example:

```dart
import 'package:interactive_svg/interactive_svg.dart';

// Define selectors for interactive regions
final selectors = [
  InteractiveSelector.byID(id: 'tooth-1'), // Interactive tooth region
  InteractiveSelector.byID(id: 'background', type: InteractiveType.touchable), // Background region
];

// Render SVG with interactive regions
InteractiveSvgView.fromAssets(
  svgAssets: 'assets/teeth.svg',
  selectors: selectors,
  shouldRebuildWhenBoundsCalculated: true,
  errorBuilder: (context, error, stackTrace) => const Center(
    child: Icon(Icons.error, color: Colors.red),
  ),
  placeholderBuilder: (context) => const Center(
    child: CircularProgressIndicator(),
  ),
  onTap: (selector) => print('Tapped region: ${selector.id}'),
  onTapOutside: () => print('Tapped outside defined regions'),
)
```

### SVG sources

The asset constructor remains available for existing applications:

```dart
InteractiveSvgView.fromAssets(
  svgAssets: 'assets/teeth.svg',
  selectors: selectors,
  onTap: (selector) => print('Tapped ${selector.id}'),
)
```

Use a provider when the SVG comes from another source:

```dart
InteractiveSvgView.fromProvider(
  provider: InteractiveSvgProvider.string(svgString),
  selectors: selectors,
  onTap: (selector) => print('Tapped ${selector.id}'),
)
```

Available providers are:

- `InteractiveSvgProvider.string(svgString)` for SVG text already in memory.
- `InteractiveSvgProvider.asset(assetName)` for a Flutter asset.
- `InteractiveSvgProvider.file(filePath)` for a local file on platforms with
  `dart:io` support. Local files are not supported on web.
- `InteractiveSvgProvider.network(url)` for an HTTP or HTTPS URL.

Provider equality determines whether `InteractiveSvgView` reloads. A new string
value is detected automatically when the parent rebuilds. Asset, file, and
network providers compare their path or URL; if content changes at the same
location, recreate the view with a new `Key` (for example a revision-based
`ValueKey`) to force a reload. Editing a `const` SVG during development may
require hot restart because hot reload does not recreate every canonicalized
constant.

### Notes
- Use `onTap` for hit-testing instead of `GestureDetector` in `interactiveBuilder`, as `flutter_svg` does not forward pointer events through transparent pixels.
- Set `shouldRebuildWhenBoundsCalculated` to `true` to rebuild after bounds are available, as `details.bounds` may be null on first build.
- `interactiveBuilder` replaces the widget for one extracted region. Always call
  and return its `builder()` when the SVG region must remain visible; returning
  `SizedBox.shrink()` intentionally hides that region.

## SVG Authoring Guidelines
To ensure reliable interactivity, follow these guidelines when creating SVGs:

### Element IDs
- IDs should be unique and descriptive (e.g., `tooth-1`, `background`).
- Avoid auto-generated IDs from design tools, as they may change on export.

### Grouping and Layers
- Group related shapes into `<g>` elements to represent independent interactive regions (e.g., tooth, gum, label).
- Keep dependencies (e.g., `<defs>`, gradients, clipPaths, masks) local to each group to avoid fragile cross-references.

### Hit-Testing
- Ensure interactive shapes have a fill (even transparent) to register hits, as `flutter_svg` does not pass pointer events through transparent pixels.
- Mark the background with a unique ID (e.g., `background`) for background tap detection.
- Prefer a dedicated, simplified hit-area SVG made from `<path>`, `<rect>`, or
  `<g>` elements when click accuracy matters. Keep the same `viewBox` as the
  visual SVG, give every hit area a stable ID, and layer/align it with the visual
  SVG in the application. This avoids coupling input behavior to font
  availability, glyph metrics, masks, or decorative details.
- Selecting visual `<text>` directly is supported as a convenience, but its
  bounds are approximate. A dedicated geometric hit area remains the recommended
  production approach.

### ViewBox and Coordinates
- Define a stable `viewBox` on the root `<svg>` for predictable scaling and bounds.
- Keep elements within the `viewBox` and avoid large transforms outside expected bounds.
- Element and nested group transforms are applied once per SVG subtree during
  bounds extraction. Do not pre-transform path coordinates and keep the same
  transform on a duplicated hit-area SVG.

### Performance
- Inline fills and strokes for interactive elements instead of relying on complex `<defs>` or `<use>`.
- Simplify paths for interactive regions to reduce parsing and bounds computation costs.

### Example SVG

```xml
<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <!-- Interactive Tooth Region -->
  <g id="tooth-1">
    <!-- Local Mask -->
    <mask id="mask-tooth-1" x="60" y="80" width="80" height="80">
      <path d="M140 160H60V80H140V160Z" fill="white"/>
    </mask>
    <!-- Tooth Shape (Clipped, transparent fill) -->
    <g mask="url(#mask-tooth-1)">
      <path id="tooth-shape-1" 
            d="M80 120C75 130 85 140 95 145C110 150 120 140 125 130C130 115 100 100 80 120Z" 
            fill="transparent"/>
    </g>
  </g>
  
  <!-- Background for Tap Detection -->
  <rect id="background" x="0" y="0" width="200" height="200" fill="transparent"/>
</svg>
```

## Limitations
- **Performance**: Complex SVGs (e.g., large paths, many nodes, heavy filters, masks) may slow parsing and bounds computation. Simplify interactive regions where possible.

> [!NOTE]
> SVGs can render slowly when running in profile mode (for example using `flutter run --profile`).
> However, when running from a built profile (`flutter build --profile`) they are typically faster and more stable.
> Also, SVG rendering is often noticeably faster on subsequent renders — the slowdown is usually limited to the first load/parse.

- **Bounds Timing**: Region bounds may be null on first build. Use `shouldRebuildWhenBoundsCalculated` to handle this.
- **Hit-Testing**: Transparent pixels do not forward events; ensure shapes have a fill (even transparent).
- **Text bounds are approximate**: Simple, single-line `<text>` supports `x`,
  `y`, `dx`, `dy`, `font-size`, `font-family`, `font-weight`, `font-style`,
  `letter-spacing`, `text-anchor`, inherited values, and transforms. Bounds are
  measured with Flutter font metrics and may differ from `flutter_svg` when the
  requested font is unavailable. Per-`<tspan>` positioning/styles, advanced
  baselines, `textLength`, text on a path, vertical writing modes, and other
  advanced SVG typography are not interpreted. Use explicit geometric hit areas
  for those cases.
- **SVG Features**: Avoid heavy use of `<use>`, external references, or complex `<defs>`, as they may cause unexpected behavior in `flutter_svg`.

## Features and Bugs
For the latest updates on features and known issues, please refer to [this link](https://github.com/sonnts996/overlay_manager/issues) (to be provided).

## Examples
Check the `/example` folder for demos showcasing:
- Defining `InteractiveSelector` values for regions like `tooth-1` and `background`.
- Handling `onTap` events for interactive SVG regions.
- Adding overlays with `interactiveBuilder` (e.g., labels for `tooth-1`).
- Implementing zoom and scroll with `Zoomable` and `SingleChildScrollView`.

## Contributing
Contributions are welcome! Please:
- Adhere to Dart and Flutter lint rules.
- Include tests for parser or selector changes.
- Update this README and documentation for public API changes.

## Acknowledgments
AI tools were consulted and used for specific assistance and code suggestions during the development of this project.
