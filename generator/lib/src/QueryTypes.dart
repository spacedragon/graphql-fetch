part of 'generator.dart';

class QueryTypes extends BaseTypes {
  String _prefix;
  String _path;
  List<Reference> depFragments = [];

  QueryTypes(GraphqlSchema schema, this._prefix, this._path) : super(schema);

  TypedReference generateFieldType(
      FileBuilder b, SelectionContext context, dynamic typeSchema) {
    switch (typeSchema.kind) {
      case "NON_NULL":
        return generateFieldType(b, context, typeSchema.ofType);
      case "LIST":
        TypedReference genericType =
            generateFieldType(b, context, typeSchema.ofType);
        return new TypedReference(
            refer("Iterable<${genericType.reference.symbol}>", "dart:core"),
            GraphType.LIST,
            genericType);
      case "OBJECT":
        String typeName = typeSchema.name;
        var className =
            generateClassForType(b, context, _schema.findObject(typeName));
        return new TypedReference(refer(className), GraphType.OBJECT);
      case "SCALAR":
        return new TypedReference(
            findDartType(typeSchema.name), GraphType.SCALAR);
      default:
        return new TypedReference(
            refer("dynamic", "dart:core"), GraphType.OTHER);
    }
  }

  generateClassForType(
      FileBuilder b, SelectionContext context, dynamic objectSchema) {
    var className = "${upperCaseFirst(_prefix)}_${objectSchema.name}";
    Class clazz = new Class((ClassBuilder cb) {
      var fields = {};
      context.field.selectionSet.selections.forEach((sel) {
        if (sel.field != null) {
          var fieldName = sel.field.fieldName.name;
          var fieldObject =
          objectSchema.fields.firstWhere((f) => f.name == fieldName);
          var returnType = generateFieldType(b, sel, fieldObject.type);
          fields[fieldName] = returnType;
        } else if (sel.fragmentSpread != null) {
          String name = sel.fragmentSpread.name;
          TypedReference frag = findFragment(name, _path);
          if (frag != null) {
            depFragments.add(frag.reference);
            cb.mixins.add(frag.reference);
          }
        }
      });
      generateClass(cb, className, fields);
    });
    b.body.add(clazz);
    return className;
  }
}
