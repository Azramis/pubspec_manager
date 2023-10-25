part of 'internal_parts.dart';

/// represents a dependency that has a 'path' key
/// A path dependency is located on the local file
/// system. The path is a relative or absolute path
/// to the dependant package.
/// A path dependency takes the form of:
/// dependencies:
///   dcli:
///     path: ../dcli
@immutable
class PathDependencyBuilder implements DependencyBuilder {
  PathDependencyBuilder({
    required this.name,
    required this.path,
    List<String>? comments,
  }) : _comments = comments ?? <String>[];

  @override
  late final String name;
  late final String path;
  late final List<String> _comments;

  List<String> get comments => _comments;

  @override
  Dependency _attach(Dependencies dependencies, PubSpec pubspec, int lineNo) =>
      PathDependency._attach(pubspec, lineNo, this);
}
