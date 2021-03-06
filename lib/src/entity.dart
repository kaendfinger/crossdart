library crossdart.entity;

import 'package:crossdart/src/location.dart';
import 'package:crossdart/src/cache.dart';
import 'package:crossdart/src/util.dart';

enum EntityKind {
  CLASS, METHOD, LOCAL_VARIABLE, FUNCTION, PROPERTY_ACCESSOR, CONSTRUCTOR, FIELD, FUNCTION_TYPE_ALIAS,
  TOP_LEVEL_VARIABLE
}

abstract class Entity {
  final Location location;
  final String name;
  final String contextName;
  final int offset;
  final int end;
  final EntityKind kind;
  final int id;

  int _lineNumber;
  int get lineNumber {
    if (offset != null) {
      if (_lineNumber == null) {
        _lineNumber = cache.lineNumber(location.file, offset);
      }
      return _lineNumber;
    } else {
      return null;
    }
  }

  int _lineOffset;
  int get lineOffset {
    if (offset != null) {
      if (_lineOffset == null) {
        _lineOffset = cache.lineOffset(location.file, offset);
      }
      return _lineOffset;
    } else {
      return null;
    }
  }

  Entity(this.location, {this.name, this.contextName, this.offset, this.end, this.kind, this.id});

  int get hashCode => hash([this.runtimeType, location, name, offset, end]);

  bool operator ==(other) {
    return (other.runtimeType == this.runtimeType)
      && location == other.location
      && name == other.name
      && offset == other.offset
      && end == other.end;
  }

  String toString() {
    return "<${runtimeType} ${toMap()}>";
  }

  Map<String, Object> toMap() {
    return {"location": location, "name": name, "offset": offset, "end": end};
  }
}

class Declaration extends Entity {
  Declaration(Location location, {String name, String contextName, int offset, int end, EntityKind kind, int id})
      : super(location, name: name, contextName: contextName, offset: offset, end: end, kind: kind, id: id);
}
class Import extends Declaration {
  Import(Location location, {String name, int id}) : super(location, name: name, id: id);
}
class Token extends Entity {
  Token(Location location, {String name, int offset, int end, int id}) : super(location, name: name, offset: offset, end: end, id: id);
}
class Reference extends Token {
  Reference(Location location, {String name, int offset, int end, int id}) : super(location, name: name, offset: offset, end: end, id: id);
}