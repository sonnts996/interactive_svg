/*
 Created by sonnts996 on 13/10/25.
 Copyright (c) 2025 . All rights reserved.
*/

import 'package:flutter/cupertino.dart';
import 'package:interactive_svg/interactive_svg.dart';

/// When exporting an SVG file from Figma, any duplicate IDs are automatically renamed
/// by appending an auto-incrementing number as a suffix, such as `_2`. This ensures
/// that each ID in the SVG document is unique, as required by SVG and XML standards.
/// Duplicate IDs can cause errors or incorrect rendering in browsers or other tools.
/// For example, if two elements share the ID `shape`, Figma will rename them to
/// `shape` and `shape_2` during export to maintain compatibility and functionality.
@immutable
class TeethInteractiveSelector extends InteractiveSelectorByID {
  const TeethInteractiveSelector({
    required String id,
    String suffix = '',
    required this.group,
  })  : originId = id,
        super(id: id + suffix, type: InteractiveType.touchable);

  /// Add `_2` into the id.
  const TeethInteractiveSelector.$2({required String id, required this.group})
      : originId = id,
        super(id: '${id}_2', type: InteractiveType.touchable);

  final String originId;
  final String group;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TeethInteractiveSelector) return false;
    return id == other.id && group == other.group;
  }

  @override
  int get hashCode => id.hashCode ^ group.hashCode;
}
