part of 'generator.dart';

class BaseTypes {
  GraphqlSchema _schema;

  BaseTypes(this._schema);

  TypedReference findScalarType(String graphqlType) {
    switch (graphqlType) {
      case "Int":
        return new TypedReference(refer("int", "dart:core"), GraphType.SCALAR);
      case "ID":
        return new TypedReference(refer("String", "dart:core"),GraphType.SCALAR);
      case "String":
        return new TypedReference(refer("String", "dart:core"),GraphType.SCALAR);
      case "Float":
        return new TypedReference(refer("double", "dart:core"),GraphType.SCALAR);
      case "Boolean":
        return new TypedReference(refer("bool", "dart:core"),GraphType.SCALAR);
      default:
        var serializer = scalarSerializers[graphqlType];
        if(serializer!=null){
          return new TypedReference(refer(serializer.dartName, serializer.dartPackage),
            GraphType.OTHER, scalaTypeName: graphqlType);
        }
        return new TypedReference(refer("dynamic", "dart:core"),GraphType.SCALAR);
    }
  }

  findFragment(String shortName, String currentPath) {
    String fragName = "${upperCaseFirst(shortName)}Fragment";
    return findType(fragName, currentPath);
  }

  final baseClass =
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
      cb.extend = baseClass;

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
      ..body = getterCode(name, type);
    return getter.build();
  }

  getterCode(String name, TypedReference type) {
    switch (type.type) {
      case GraphType.OBJECT:
        return new Code('${type.reference.symbol}.fromMap(this["$name"])');
      case GraphType.INPUT_OBJECT:
        return new Code('${type.reference.symbol}.fromMap(this["$name"])');
      case GraphType.ENUM:
        return new Code('${type.reference.symbol}.values[this["$name"]]');
      case GraphType.LIST:
        if (type.genericReference.type == GraphType.OBJECT ||
            type.genericReference.type == GraphType.INPUT_OBJECT) {
          return new Code('this["$name"]?.map(${type.genericReference
              .reference.symbol}.fromMap)');
        } else if (type.genericReference.type == GraphType.ENUM) {
          return new Code('this["$name"]?.map((v) => ${type.genericReference
              .reference.symbol}.values[v])');
        } else {
          return new Code('this["$name"]');
        }
        break;
      case GraphType.OTHER:
        Reference r = refer('scalarSerializers','package:graphql_fetch/graphql_fetch.dart');
        return new Code.scope((a)=> '${a(r)}["${type.scalaTypeName}"].deserialize(this["$name"])');
      default:
        return new Code('this["$name"]');
    }
  }


}

enum GraphType { LIST, OBJECT, INPUT_OBJECT, ENUM, SCALAR, OTHER }

class TypedReference {
  Reference reference;
  GraphType type;
  TypedReference genericReference;
  String scalaTypeName;
  TypedReference(this.reference, this.type, {this.genericReference, this.scalaTypeName});

  String file;
}
