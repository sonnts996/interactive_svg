/*
 Created by sonnts996 on 13/10/25.
 Copyright (c) 2025 . All rights reserved.
*/

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:xml/xml.dart';

/// The type of interactivity for a selector region.
///
/// - [viewOnly]: Regions intended only for visual display. They are excluded from
///   hit-testing and touch handling; no bounds are computed for these selectors.
/// - [touchable]: Regions intended to participate in user interaction. When set to
///   [touchable], bounds will be computed (when possible) and the region will be
///   considered for hit testing (e.g., taps).
enum InteractiveType {
  /// viewOnly:
  /// - Use for elements that are separated into their own layer for visual
  ///   processing (e.g., show/hide, opacity changes) but where the system does
  ///   not need to know their position or size.
  /// - These elements are not considered for hit-testing; bounds are not computed.
  /// - Examples: purely decorative overlays, visual-only guides.
  viewOnly,

  /// boundsOnly:
  /// - Use for elements that are separated into their own layer like `viewOnly`,
  ///   but where the system must know their position and size (bounds).
  /// - Bounds will be computed so the element's position/size can be used for
  ///   tasks such as placing markers, computing replacements, aligning overlays, etc.
  /// - These elements are not returned for touch callbacks (they are not touchable).
  /// - Examples: elements used to determine anchor points or layout reference boxes.
  boundsOnly,

  /// touchable:
  /// - Use for elements that are separated into their own layer and that also
  ///   have meaningful bounds (position and size) like `boundsOnly`.
  /// - Additionally, these elements participate in user interactions: they are
  ///   considered during hit-testing and will generate tap events.
  /// - Only elements defined as `touchable` will be returned from onTap handlers.
  /// - Examples: buttons, interactive icons, selectable areas that respond to taps.
  touchable,
}

/// An abstract representation of a selector used to identify SVG elements or groups.
///
/// Subclasses implement a selection strategy (for example, matching by element name/id
/// or by parent relationship). An [InteractiveSelector] carries:
/// - `id`: the identifier used to match elements (semantic meaning depends on implementation),
/// - `label`: a human-friendly name used for debugging or display (defaults to `id`),
/// - `tag`: the XML element name to target (e.g. 'path', 'g', 'rect'). Use '*' to search all tags.
/// - `type`: whether the region is touchable or view-only.
///
/// Important: the selector API returns a matched XmlNode (or null) rather than a boolean.
/// Implementations should return the first matching descendant node (or null when no match).
/// This allows callers to obtain the actual node to render or inspect.
@immutable
abstract class InteractiveSelector {
  /// Creates an [InteractiveSelector].
  ///
  /// [id] identifies the target element(s) in the SVG (implementation-specific).
  /// [label] is an optional human readable label; if omitted, subclasses typically
  /// default it to `id`.
  /// [type] determines whether bounds should be computed for hit testing.
  const InteractiveSelector({
    required this.id,
    this.label = '',
    this.type = InteractiveType.viewOnly,
    this.tag = '*',
  });

  /// Factory constructor for a selector that matches elements by their `id` attribute.
  ///
  /// Produces an [InteractiveSelectorByID] instance.
  const factory InteractiveSelector.byID({
    required String id,
    String? label,
    InteractiveType type,
    String tag,
  }) = InteractiveSelectorByID;

  /// Factory constructor for a selector that matches elements by `id` and a parent selector.
  ///
  /// Produces an [InteractiveSelectorByIDAndParent] instance where the matched element's parent
  /// must also match `parentSelector`.
  const factory InteractiveSelector.byIDAndParent({
    required String id,
    required InteractiveSelector parentSelector,
    String? label,
    InteractiveType type,
    String tag,
  }) = InteractiveSelectorByIDAndParent;

  /// The human-readable label for this selector. May be empty.
  final String label;

  /// The identifier used for selection. Semantics depend on the concrete selector.
  final String id;

  /// The xml's element name (e.g., 'path', 'g', 'rect') this selector is intended to match.
  final String tag;

  /// The interactivity type for this selector (view-only or touchable).
  final InteractiveType type;

  /// Returns true when [element] matches this selector.
  ///
  /// Concrete subclasses must implement the selection logic. The matching is performed
  /// against an [XmlElement] extracted from the parsed SVG.
  ///
  /// - `element` is the XML node (often the document root or a subtree) to search within.
  /// - Implementations should return the matched XmlNode (for example, an XmlElement)
  ///   when found, or `null` if no matching node exists.
  ///
  /// Notes:
  /// - Implementations may search descendants (not just `element` itself).
  /// - The returned node may be used by parsers/renderers to extract SVG fragments.
  XmlNode? selector(XmlNode element);

  /// Callable shorthand that delegates to [selector].
  ///
  /// This allows treating an InteractiveSelector as a function:
  /// `final node = selector(someXmlNode);`
  XmlNode? call(XmlNode element) => selector(element);

  @override
  String toString() => 'InteractiveSelector($label)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InteractiveSelector) return false;

    return other.id == id && other.type == type;
  }

  @override
  int get hashCode => Object.hash(id, type);
}

/// A selector that matches SVG elements by their `id` attribute.
///
/// Use this when you want to match a specific element or group in the SVG via its `id`.
class InteractiveSelectorByID extends InteractiveSelector {
  /// Creates a selector that matches elements with the given [id].
  ///
  /// If [label] is not provided, it defaults to [id].
  const InteractiveSelectorByID({
    required super.id,
    String? label,
    super.type,
    super.tag = '*',
  }) : super(label: label ?? id);

  @override
  XmlNode? selector(XmlNode element) => element
      .findAllElements(tag)
      .firstWhereOrNull((e) => e.getAttribute('id') == id);
}

/// A selector that matches SVG elements by `id` and whose parent element matches another selector.
///
/// This selector first invokes [parentSelector] on the provided `element` and then searches
/// the returned subtree for a node with the given `id`. Returns the matched node or `null`.
class InteractiveSelectorByIDAndParent extends InteractiveSelectorByID {
  /// Creates a selector that matches elements with [id] whose parent satisfies [parentSelector].
  const InteractiveSelectorByIDAndParent({
    required super.id,
    required this.parentSelector,
    super.label,
    super.type,
    super.tag = '*',
  }) : _label = label;

  final String? _label;

  /// The selector that must match the parent element.
  final InteractiveSelector parentSelector;

  @override
  String get label => _label ?? '${parentSelector.label} > $id';

  @override
  XmlNode? selector(XmlNode element) {
    final result = parentSelector(element);
    if (result != null) {
      return super.selector(result);
    }
    return null;
  }
}
