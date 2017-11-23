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

  final MapObject =
      refer("MapObject", "package:graphql_fetch/graphql_fetch.dart");

  upperCaseFirst(String s) {
    return s[0].toUpperCase() + s.substring(1);
  }

  findType(String typeName, String currentPath) {
    TypedReference t = this._schema.findType(typeName);
    if (t == null) return null;
    Reference r;
    if (t?.file == currentPath) {
      r = refer(typeName);
    } else {
      r = refer(typeName, p.relative(t?.file, from: p.dirname(currentPath)));
    }
    return new TypedReference(r, t.type);
  }

  String wrapStringCode(String code) {
    return '"""${code.replaceAll("\$", "\\\$")}"""';
  }

  generateClass(ClassBuilder cb, String className, Map<String, TypedReference> fields) {
      cb.name = className;
      cb.extend = MapObject;

      for (var name in fields.keys) {
        TypedReference type = fields[name];
        cb.methods.add(generateGetter(name, type));
      }
      cb.methods.add(new Method((MethodBuilder b) => b
        ..name = "fromMap"
        ..static = true
        ..returns = refer(className)
        ..requiredParameters.add((new ParameterBuilder()
              ..name = "map"
              ..type = refer("Map"))
            .build())
        ..body = new Code('''return map == null ? 
        null : 
        new ${className}()..map.addAll(map);  
        ''')));
  }

  generateGetter(String name, TypedReference type) {
    MethodBuilder getter = new MethodBuilder()
      ..name = name
      ..returns = type.reference
      ..lambda = true
      ..type = MethodType.getter
      ..body = new Code(getterCode(name, type));
    return getter.build();
  }

  getterCode(String name, TypedReference type) {
    switch (type.type) {
      case GraphType.OBJECT:
        return '${type.reference.symbol}.fromMap(this["$name"])';
      case GraphType.INPUT_OBJECT:
        return '${type.reference.symbol}.fromMap(this["$name"])';
      case GraphType.ENUM:
        return '${type.reference.symbol}.values[this["$name"]]';
      case GraphType.LIST:
        if (type.genericReference.type == GraphType.OBJECT ||
            type.genericReference.type == GraphType.INPUT_OBJECT) {
          return 'this["$name"]?.map(${type.genericReference
              .reference.symbol}.fromMap)';
        } else if (type.genericReference.type == GraphType.ENUM) {
          return 'this["$name"]?.map((v) => ${type.genericReference
              .reference.symbol}.values[v])';
        } else {
          return 'this["$name"]';
        }
        break;
      default:
        return 'this["$name"]';
    }
  }


}

enum GraphType { LIST, OBJECT, INPUT_OBJECT, ENUM, SCALAR, OTHER }

class TypedReference {
  Reference reference;
  GraphType type;
  TypedReference genericReference;

  TypedReference(this.reference, this.type, [this.genericReference]);

  String file;
}
