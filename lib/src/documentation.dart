part of 'internal_parts.dart';

class Documentation implements SingleLine {
  Documentation(this.url);
  Documentation.missing() : url = '';

  String url;

  DocumentationAttached attach(Pubspec pubspec, int lineNo) =>
      DocumentationAttached._attach(pubspec, lineNo, this);

  @override
  String get value => url;
}

class DocumentationAttached extends SectionSingleLine {
  DocumentationAttached._attach(Pubspec pubspec, int lineNo, this.documentation)
      : super.attach(_key, pubspec, lineNo, documentation);

  DocumentationAttached._fromLine(Line line)
      : documentation = Documentation(line.value),
        super.fromLine(_key, line);

  DocumentationAttached.missing(Document document)
      : documentation = Documentation.missing(),
        super.missing(_key, document);

  DocumentationAttached url(String url) {
    documentation.url = url;

    if (missing) {
      // we now need to attach ourself.
      set(url);
    }

    // ignore: avoid_returning_this
    return this;
  }

  //final Document document;
  final Documentation documentation;

  static const String _key = 'documentation';
}

abstract class SingleLine {
  String get value;
}
