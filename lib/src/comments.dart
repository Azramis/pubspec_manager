// ignore_for_file: avoid_returning_this

part of 'internal_parts.dart';

/// Used to hold the comments that prefix a section.
/// A comment section is all comments/blank lines that are above
/// a section upto where the proceeding section ends.
class Comments {
  Comments(this.section) {
    _lines = _commentsAsLine();
  }
  Comments.empty(this.section) : _lines = <Line>[];

  /// The section these comments are attached to.
  Section section;

  /// Gets the set of comments that suffix the passed in [section]
  /// This will include any blank lines upto the end of the prior
  /// section.
  List<Line> _commentsAsLine() {
    final document = section.document;

    final suffix = <Line>[];

    final lines = document.lines;

    /// there can be no comments if we are the first
    /// line of the pubspec.yaml
    if (section.line.lineNo == 1) {
      return suffix;
    }
    // search for comments starting from the prior line
    var lineNo = section.line.lineNo - 2;

    for (; lineNo > 0; lineNo--) {
      final line = lines[lineNo];
      final type = line.type;
      if (type == LineType.comment || type == LineType.blank) {
        suffix.insert(0, line);
      } else {
        break;
      }
    }
    return suffix;
  }

  /// All of the lines that make up this comment.
  late final List<Line> _lines;

  List<Line> get lines => _lines;

  /// the number of dependencies in this section
  int get length => _lines.length;

  /// Add [comment] to the PubSpec
  /// after the last line in this comment section.
  /// DO NOT prefix [comment] with a '#' as this
  /// method adds the '#'.
  Comments append(String comment) {
    final document = section.line.document;
    final commentLine = Line.forInsertion(
        document, '${spaces(section.line.indent * 2)}# $comment');
    _lines.add(commentLine);
    document.insertBefore(commentLine, section.line);
    return this;
  }

  /// removes the comment a offset [index] in the list
  /// of comments for this section. [index] is zero based.
  /// If no comment exists at [index] then a [RangeError] is thrown.
  void removeAt(int index) {
    final document = section.document;
    if (index < 0) {
      throw OutOfBoundsException(
          section.line, 'Index must be >= 0 found $index}');
    }
    if (index > _lines.length) {
      throw OutOfBoundsException(
          section.line, 'Index must be < ${_lines.length} found $index}');
    }

    final line = _lines.removeAt(index);
    document.removeAll([line]);
  }

  void removeAll() {
    section.document.removeAll(_lines);
    _lines.removeRange(0, _lines.length);
  }
}
