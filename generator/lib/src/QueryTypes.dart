part of 'generator.dart';

class QueryTypes extends BaseTypes {
  String _prefix;
  String _path;
  List<Reference> depFragments = [];

  QueryTypes(GraphqlSchema schema, this._prefix, this._path) : super(schema);

  generateFieldType(
      FileBuilder b, SelectionContext context, dynamic typeSchema) {
    switch (typeSchema.kind) {
      case "NON_NULL":
        return generateFieldType(b, context, typeSchema.ofType);
      case "LIST":
        Reference genericType =
            generateFieldType(b, context, typeSchema.ofType)[0];
        return [refer("List<${genericType.symbol}>", "dart:core"), genericType];
      case "OBJECT":
        String typeName = typeSchema.name;
        var className =
            generateClassForType(b, context, _schema.findObject(typeName));
        return [refer(className)];
      case "SCALAR":
        return [findDartType(typeSchema.name)];
      default:
        return [refer("dynamic", "dart:core")];
    }
  }

  generateClassForType(
      FileBuilder b, SelectionContext context, dynamic objectSchema) {
    var className = "${upperCaseFirst(_prefix)}_${objectSchema.name}";
    Class clazz = new Class((ClassBuilder cb) {
      cb.name = className;
      cb.extend = baseModel;
      context.field.selectionSet.selections.forEach((sel) {
        if (sel.field != null) {
          var fieldName = sel.field.fieldName.name;
          var fieldObject =
              objectSchema.fields.firstWhere((f) => f.name == fieldName);
          var returnType = generateFieldType(b, sel, fieldObject.type);
          generateGetter(fieldName, returnType, cb);
        } else if (sel.fragmentSpread!=null) {
          String name = sel.fragmentSpread.name;
          Reference frag = findFragment(name, _path);
          if(frag!=null) {
            depFragments.add(frag);
            cb.mixins.add(frag);
          }
        }
      });
      generateCreator(cb);
    });
    b.body.add(clazz);
    return className;
  }

  void generateGetter(String fieldName, returnType, ClassBuilder cb) {
    MethodBuilder mb = new MethodBuilder()
      ..name = fieldName
      ..type = MethodType.getter
      ..lambda = true
      ..returns = returnType[0];
    if (returnType.length == 2) {
      mb.body = new Code.scope((a) => 'MapObject.getProp(this, "${fieldName}",${a(
          returnType[1])}.fromMap)');
    } else if (returnType[0].url == "dart:core") {
      final identity =
          refer("Identity", "package:graphql_fetch/graphql_fetch.dart");
      mb.body = new Code.scope((a) => 'MapObject.getProp(this, "${fieldName}",${a(identity)})');
    } else {
      mb.body = new Code.scope((a) => 'MapObject.getProp(this, "${fieldName}",${a(
          returnType[0])}.fromMap)');
    }
    cb.methods.add(mb.build());
  }

  void generateCreator(ClassBuilder cb) {
    cb.methods.add(new Method((MethodBuilder mb) {
      mb
        ..static = true
        ..name = "fromMap"
        ..requiredParameters.add(new Parameter((pb) => pb..name = "map"))
        ..lambda = true
        ..body = new Code("new ${cb.name}()..mapObject = map")
        ..returns = refer(cb.name);
    }));
  }
}
