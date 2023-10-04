import 'dart:io';

import 'package:strings/strings.dart';

import '../internal_parts.dart';
import 'key_value.dart';
import 'line.dart';
import 'line_detached.dart';
import 'line_section.dart';
import 'line_type.dart';
import 'multi_line.dart';
import 'simple_section.dart';

class Document {
  /// Load the pubspec.yaml from the file located at [pathTo]
  /// into a an ordered list of [Line]s.
  factory Document.loadFrom(String pathTo) {
    final lines = File(pathTo).readAsLinesSync();
    final doc = Document.loadFromLines(lines)..pathTo = pathTo;
    return doc;
  }

  /// Load the pubspec.yaml from the set of strings in [contentLines]
  /// into a an ordered list of [Line]s.
  Document.loadFromLines(List<String> contentLines) {
    var lineNo = 1;
    for (final line in contentLines) {
      lines.add(Line(this, line, lineNo++));
    }
    pathTo = '<Loaded from lines>';
  }

  /// Load the pubspec.yaml from [content]
  /// into an ordered list of [Line]s.
  factory Document.loadFromString(String content) {
    var lines = content.split('\n');
    if (lines.isNotEmpty && Strings.isBlank(lines.last)) {
      // if the last char was \n then split returns an extra empty line
      lines = lines.sublist(0, lines.length - 1);
    }

    final doc = Document.loadFromLines(lines)
      ..pathTo = '<Loaded from a String>';
    return doc;
  }

  /// The set of lines that hold the pubspec.yaml
  List<Line> lines = <Line>[];

  /// The path to the file that the pubspec.yaml was loaded from.
  late String pathTo;

  Line? get lastLine => lines.isEmpty ? null : lines.last;

  /// Return the line that has the given [key].
  /// Only lines of type [LineType.key] are considered.
  LineSection getLineForKey(String key) {
    for (final line in lines) {
      if (line.type == LineType.key) {
        if (line.key == key) {
          return LineSection.fromLine(line);
        }
      }
    }
    return LineSection.missing(this, key);
  }

  /// Finds a section for the given [key].
  /// If the [key] doesn't exist then returns null.
  SimpleSection findSectionForKey(String key) {
    for (final line in lines) {
      if (line.type == LineType.key) {
        final keyValue = KeyValue.fromLine(line);
        if (keyValue.key == key) {
          return SimpleSection.fromLine(line);
        }
      }
    }
    return SimpleSection.missing(this, key);
  }

  /// Finds the line for the given [key].
  /// If the [key] isn't found then throws a [PubSpecException].
  LineSection getLineForRequiredKey(String key) {
    final line = getLineForKey(key);
    if (line.missing) {
      throw PubSpecException.forDocument(
          this, "Required key '$key' is missing.");
    }
    return line;
  }

  /// Finds the line for the given [key].
  /// If the [key] isn't found then throws a [PubSpecException].
  MultiLine getMultiLineForRequiredKey(String key) {
    final line = getLineForKey(key);
    if (line.missing) {
      throw PubSpecException.forDocument(
          this, "Required key '$key' is missing.");
    }

    return MultiLine.fromLine(line);
  }

  // Finds the next line that is of [LineType.key]
  // that is a child of the passed line which has the
  // given [key].  If no matching child is found then
  // null is returned.
  Line findKeyChild(Line line, String key) {
    for (final child in childrenOf(line)) {
      if (child.keyValue.key == key) {
        return child;
      }
    }
    return Line.missing(this, LineType.key);
  }

  /// Finds the first root key with the name [key]
  /// returns Line.missing if [key] was not found.
  Line findTopLevelKey(String key) {
    for (final child in lines) {
      if (child.indent != 0) {
        continue;
      }
      if (child.type != LineType.key) {
        continue;
      }

      if (child.keyValue.key == key) {
        return child;
      }
    }
    return Line.missing(this, LineType.key);
  }

  /// Returns the list child for [parent].
  /// If [type] is passed, then only children of that type
  /// are returned.
  /// If [descendants] is true then all descendants of [parent]
  /// are returned not just immediate children.
  List<Line> childrenOf(Line parent,
      {LineType? type, bool descendants = false}) {
    final children = <Line>[];
    for (final line in lines) {
      /// wait until we see a line that is after the parent.
      if (line.lineNo > parent.lineNo) {
        /// If the ident decreases then we have passed all
        /// of the parent's children.
        if (line.indent <= parent.indent) {
          break;
        }

        /// filter out children that don't match the key [type]
        if (type != null && line.type != type) {
          continue;
        }

        /// exclude descendants unless they were asked for.
        if (line.indent > parent.indent + 1 && !descendants) {
          continue;
        }

        children.add(line);
      }
    }
    return children;
  }

  /// Appends the passed line to the end of the document.
  /// The lines [Line.lineNo] will be updated to reflect
  /// the actual line number in the document.
  Line append(LineDetached line) {
    final attached = line.attach(this)..lineNo = lines.length + 1;
    lines.add(attached);
    _validate();
    return attached;
  }

  /// Inserts [line] into the document as indicated
  /// by the lines [Line.lineNo].
  /// The line numbers of subsequent lines are updated
  /// to reflect their new position.
  void insert(Line line, int insertAt) {
    line.lineNo = insertAt - 1;
    lines.insert(line.lineNo, line);

    for (var i = line.lineNo; i < lines.length; i++) {
      final _line = lines.elementAt(i);
      _line.lineNo++;
    }
    _validate();
  }

  /// Removes all of the given [lines] from the
  /// document then renumbers the remaining lines
  void removeAll(List<Line> toBeRemoved) {
    // ignore: prefer_foreach
    for (final line in toBeRemoved) {
      lines.remove(line);
    }
    _reindex();
    _validate();
  }

  void _reindex() {
    var lineNo = 1;
    for (final line in lines) {
      line.lineNo = lineNo++;
    }
  }

  void _validate() {
    var expectedLineNo = 1;
    for (final line in lines) {
      if (line.lineNo != expectedLineNo) {
        throw PubSpecException(line, '''
Oops you found a bug. Expected $expectedLineNo found: ${line.lineNo}
with content:
$line ''');
      }
      expectedLineNo++;
    }
  }
}
