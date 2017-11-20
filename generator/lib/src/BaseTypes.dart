part of 'generator.dart';

class BaseTypes {
  GraphqlSchema _schema;

  BaseTypes(this._schema);

  Reference findDartType(String graphqlType) {
    switch (graphqlType) {
      case "Int":
        return refer("int", "dart:core");
      case "ID":
        return refer("String", "dart:core");
      case "String":
        return refer("String", "dart:core");
      case "Float":
        return refer("double", "dart:core");
      case "Boolean":
        return refer("bool", "dart:core");
      case "DateTime":
        return refer("DatTime", "dart:core");
      default:
        return refer("dynamic", "dart:core");
    }
  }

  findFragment(String shortName, String currentPath) {
    String fragName = "${upperCaseFirst(shortName)}Fragment";
    return findType(fragName, currentPath);
  }

  final baseModel =
      refer("MapObject", "package:graphql_fetch/graphql_fetch.dart");

  upperCaseFirst(String s) {
    return s[0].toUpperCase() + s.substring(1);
  }

  findType(String typeName, String currentPath) {
    String path = this._schema.findType(typeName);
    if (path != null)
      return refer(typeName, p.relative(path, from: p.dirname(currentPath)));
    return null;
  }

  String wrapStringCode(String code) {
    return '"""${code.replaceAll("\$", "\\\$")}"""';
  }
}
