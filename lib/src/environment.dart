part of 'internal_parts.dart';

/// Holds the details of the environment section.
/// i.e. flutter and sdk versions.
class Environment extends Section {
  Environment.missing(Document document)
      : _line = Line.missing(document, LineType.key),
        _sdk = VersionConstraint._missing(document, sdkKey),
        _flutter = VersionConstraint._missing(document, flutterKey);

  /// Load the environment [Section] starting from the
  /// given attached [_line].
  Environment.fromLine(this._line) {
    _sdkLine = _line.findKeyChild('sdk');
    _flutterLine = _line.findKeyChild('flutter');

    _sdk = _sdkLine.missing
        ? VersionConstraint._missing(document, sdkKey)
        : VersionConstraint._fromLine(_sdkLine);

    _flutter = _flutterLine.missing
        ? VersionConstraint._missing(document, sdkKey)
        : VersionConstraint._fromLine(_flutterLine);

    comments = Comments(this);
  }

  Environment._attach(
      PubSpec pubspec, Line lineBefore, EnvironmentBuilder environment) {
    final document = pubspec.document;

    _line = Line.forInsertion(document, 'environment:');
    document.insertAfter(_line, lineBefore);

    if (environment._sdk != null) {
      lineBefore = pubspec.document.insertAfter(
          _sdkLine = Line.forInsertion(
              pubspec.document, '  $sdkKey: ${environment._sdk}'),
          _line);
      _sdk = VersionConstraint._fromLine(_sdkLine);
    } else {
      _sdkLine = Line.missing(document, LineType.key);
      _sdk = VersionConstraint._missing(document, sdkKey);
    }

    if (environment._flutter != null) {
      pubspec.document.insertAfter(
          _flutterLine = Line.forInsertion(
              pubspec.document, '  $flutterKey: ${environment._flutter}'),
          lineBefore);
      _flutter = VersionConstraint._fromLine(_flutterLine);
    } else {
      _flutterLine = Line.missing(document, LineType.key);
      _flutter = VersionConstraint._missing(document, flutterKey);
    }
  }

  static const sdkKey = 'sdk';
  static const flutterKey = 'flutter';

  late VersionConstraint _sdk;
  late VersionConstraint _flutter;

  /// The starting line of the environment section.
  late final Line _line;
  late Line _sdkLine;
  late Line _flutterLine;

  @override
  Line get line => _line;

  @override
  late final Comments comments;

  String get sdk => _sdk.version;
  String get flutter => _flutter.isMissing ? '' : _flutter.version;

  set sdk(String version) {
    if (_sdk.isMissing) {
      final sdkLine = Line.forInsertion(document, '  sdk: $version');
      document.insertAfter(sdkLine, _line);
      _sdkLine = sdkLine;
      _sdk = VersionConstraint._fromLine(_sdkLine);
    } else {
      _sdk.version = version;
      _sdkLine.value = version;
    }
  }

  set flutter(String version) {
    if (_flutter.isMissing) {
      final flutterLine = Line.forInsertion(document, '  flutter: $version');
      document.insertAfter(flutterLine, _line);
      _flutterLine = flutterLine;
      _flutter = VersionConstraint._fromLine(_flutterLine);
    } else {
      _flutter.version = version;
      _flutterLine.value = version;
    }
  }

  @override
  String toString() => _line.value;

  @override
  Document get document => line.document;

  @override
  List<Line> get lines => [
        _line,
        if (!_sdkLine.missing) _sdkLine,
        if (!_flutterLine.missing) _flutterLine
      ];

  /// The last line number used by this  section
  @override
  int get lastLineNo => lines.last.lineNo;

  static const String _key = 'environment';
}
