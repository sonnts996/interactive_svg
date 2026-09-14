## 0.0.1

- Initial interactive_svg source

# 0.0.1+1

- Fix bounds transform and scale calculation

# 0.0.2

- Changes to bounds calculation:
  - Add SizeReporter to listen for and accurately confirm size change events.
  - Split bounds loading into two clear steps:
    - parseSvgBounds: load and extract the raw list of bounds from the SVG (expressed in SVG viewBox coordinate space).
    - scaleSvgBounds: convert/scale the extracted bounds into widget coordinates using actual size, BoxFit, and Alignment.
  - Compatibility note: parseSvgBounds returns unscaled data; call scaleSvgBounds to obtain bounds in widget coordinates.
