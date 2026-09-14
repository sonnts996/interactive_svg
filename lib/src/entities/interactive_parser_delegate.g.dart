// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interactive_parser_delegate.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InteractiveParseContextCWProxy {
  InteractiveParseContext root(XmlElement? root);

  InteractiveParseContext document(XmlDocument? document);

  InteractiveParseContext viewBox(Rect? viewBox);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `InteractiveParseContext(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InteractiveParseContext(...).copyWith(id: 12, name: "My name")
  /// ```
  InteractiveParseContext call({
    XmlElement? root,
    XmlDocument? document,
    Rect? viewBox,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfInteractiveParseContext.copyWith(...)` or call `instanceOfInteractiveParseContext.copyWith.fieldName(value)` for a single field.
class _$InteractiveParseContextCWProxyImpl
    implements _$InteractiveParseContextCWProxy {
  const _$InteractiveParseContextCWProxyImpl(this._value);

  final InteractiveParseContext _value;

  @override
  InteractiveParseContext root(XmlElement? root) => call(root: root);

  @override
  InteractiveParseContext document(XmlDocument? document) =>
      call(document: document);

  @override
  InteractiveParseContext viewBox(Rect? viewBox) => call(viewBox: viewBox);

  @override

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `InteractiveParseContext(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InteractiveParseContext(...).copyWith(id: 12, name: "My name")
  /// ```
  InteractiveParseContext call({
    Object? root = const $CopyWithPlaceholder(),
    Object? document = const $CopyWithPlaceholder(),
    Object? viewBox = const $CopyWithPlaceholder(),
  }) {
    return InteractiveParseContext(
      root: root == const $CopyWithPlaceholder()
          ? _value.root
          // ignore: cast_nullable_to_non_nullable
          : root as XmlElement?,
      document: document == const $CopyWithPlaceholder()
          ? _value.document
          // ignore: cast_nullable_to_non_nullable
          : document as XmlDocument?,
      viewBox: viewBox == const $CopyWithPlaceholder()
          ? _value.viewBox
          // ignore: cast_nullable_to_non_nullable
          : viewBox as Rect?,
    );
  }
}

extension $InteractiveParseContextCopyWith on InteractiveParseContext {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfInteractiveParseContext.copyWith(...)` or `instanceOfInteractiveParseContext.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InteractiveParseContextCWProxy get copyWith =>
      _$InteractiveParseContextCWProxyImpl(this);
}
