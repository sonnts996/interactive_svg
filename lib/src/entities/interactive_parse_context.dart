/*
 Created by sonnts996 on 14/10/25.
 Copyright (c) 2025 . All rights reserved.
*/

part of 'interactive_parser_delegate.dart';

/// Holds parsed XML state for an SVG document.
///
/// - [document]: the full parsed XmlDocument.
/// - [root]: the `<svg>` root element (may be null if parsing failed).
/// - [viewBox]: the parsed viewBox rect when available. This is used to map SVG
///   coordinates into widget coordinates when computing bounds.
@CopyWith()
class InteractiveParseContext {
  /// Creates a new [InteractiveParseContext] with the given fields.
  InteractiveParseContext({
    this.root,
    this.document,
    this.viewBox,
  });

  /// The root <svg> element of the parsed document.
  final XmlElement? root;

  /// The full parsed XML document.
  final XmlDocument? document;

  /// The parsed viewBox rectangle, if available.
  final Rect? viewBox;
}
