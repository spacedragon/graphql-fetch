part of 'generator.dart';

class InputTypes extends BaseTypes {
  String _file;

  InputTypes(GraphqlSchema schema, this._file) : super(schema);

  TypedReference generateInputType(FileBuilder b, dynamic typeSchema) {
    switch (typeSchema.kind) {
      case "NON_NULL":
        return generateInputType(b, typeSchema.ofType);
        break;
      case "LIST":
        TypedReference genericType = generateInputType(b, typeSchema.ofType);
        return new TypedReference(
            refer("Iterable<${genericType.reference.symbol}>", "dart:core"),
            GraphType.LIST,
            genericReference: genericType);
      case "INPUT_OBJECT":
        String typeName = typeSchema.name;
        TypedReference generated = findType(typeName, _file);
        if (generated != null) {
          return generated;
        }
        var className =
            generateInputClassForType(b, _schema.findObject(typeName));
        return new TypedReference(
          refer(className),
          GraphType.INPUT_OBJECT,
        );
      case "SCALAR":
        return findScalarType(typeSchema.name);
      case "ENUM":
        String typeName = typeSchema.name;
        TypedReference generated = findType(typeName, _file);
        if (generated != null) {
          return generated;
        }
        var className = generateEnumForType(b, _schema.findObject(typeName));
        return new TypedReference(refer(className), GraphType.ENUM);
      default:
        return new TypedReference(
            refer("dynamic", "dart:core"), GraphType.OTHER);
    }
  }

  generateInputClassForType(FileBuilder b, dynamic typeSchema) {
    var className = typeSchema.name;
    TypedReference t =
        new TypedReference(refer(className), GraphType.INPUT_OBJECT);
    _schema.registerType(_file, t);
    var fields = {};
    for (var f in typeSchema.inputFields) {
      fields[f.name] = generateInputType(b, f.type);
    }
    var clazz = new Class((cb) {
      generateClass(cb, className, fields);
      generateConstructor(cb, className, fields);
    });
    b.body.add(clazz);
    return className;
  }

  generateConstructor(ClassBuilder cb,String className, Map<String, TypedReference> fields) {
    ConstructorBuilder constructor = new ConstructorBuilder();
    List<String> creatorCode = [];
    for (var name in fields.keys) {
      TypedReference type = fields[name];
      constructor.optionalParameters
          .add(new Parameter((ParameterBuilder pb) => pb
        ..name = name
        ..type = type.reference
        ..named = true));
      creatorCode.add('"$name" : $name');
    }
    constructor
      ..initializers.add(new Code('''super.fromMap({
       ${creatorCode.join(",\n")}
        })'''));
    cb.constructors.add(constructor.build());
  }

  generateEnumForType(FileBuilder b, dynamic typeSchema) {
    String className = typeSchema.name;
    TypedReference t = new TypedReference(refer(className), GraphType.ENUM);
    _schema.registerType(_file, t);
    b.body.add(new Class((ClassBuilder b) => b
      ..name = className
      ..fields.addAll(
          typeSchema.enumValues.map((e) => new Field((FieldBuilder fb) => fb
            ..name = e.name
            ..type = refer(className)
            ..static = true
            ..modifier = FieldModifier.final$
            ..assignment = new Code('new $className._("${e.name}")'))))
      ..fields.add(new Field((FieldBuilder fb) => fb
        ..name = "value"
        ..type = refer("String")))
      ..constructors.add(new Constructor((ConstructorBuilder cb) => cb
        ..name = "_"
        ..requiredParameters.add(new Parameter((ParameterBuilder pb) => pb
          ..name = "value"
          ..type = refer("String")
          ..toThis = true))))
      ..fields.add(new Field((FieldBuilder fb) => fb
        ..name = "values"
        ..static = true
        ..assignment = new Code("{" +
            typeSchema.enumValues
                .map((e) => '"${e.name}": ${e.name}')
                .join(",\n") +
            "}")
        ..type = refer("Map<String, $className>")))));
    return className;
  }
}
