
part of 'generator.dart';

class InputTypes extends  BaseTypes {
  String _file;
  InputTypes(GraphqlSchema schema,this._file) : super(schema);

  Reference generateInputType(FileBuilder b, dynamic typeSchema) {

    switch(typeSchema.kind) {
      case "NON_NULL":
        return generateInputType(b, typeSchema.ofType);
        break;
      case "LIST":
        Reference genericType = generateInputType(b, typeSchema.ofType);
        return refer("List<${genericType.symbol}>", "dart:core");
      case "INPUT_OBJECT":
        String typeName = typeSchema.name;
        String generated = _schema.findType(typeName);
        if(generated!=null) {
          return refer(typeName, generated);
        }
        var className= generateInputClassForType(b, _schema.findObject(typeName));
        return refer(className);
      case "SCALAR":
        return findDartType(typeSchema.name);
      case "ENUM":
        String typeName = typeSchema.name;
        var className= generateEnumForType(b, _schema.findObject(typeName));
        return refer(className);
      default:
        return refer("dynamic","dart:core");
    }
  }
  generateInputClassForType(FileBuilder b, dynamic typeSchema) {
    var className = typeSchema.name;
    Class clazz = new Class((ClassBuilder cb) {
      cb.name = className;
      /*cb.annotations.add(new Annotation((AnnotationBuilder ab) =>
      ab.code=new Code.scope((a) => a(_serializable)) ));*/
      cb.extend = baseModel;
      for(var f in typeSchema.inputFields){
        FieldBuilder fb=new FieldBuilder()
          ..name = f.name
          ..type = generateInputType(b, f.type);
        cb.fields.add(fb.build());
      };
    });
    b.body.add(clazz);
    _schema.registerInputType(_file, className);
    return className;
  }
  generateEnumForType(FileBuilder b, dynamic typeSchema) {
    b.body.add(new Code("""
      enum ${typeSchema.name} {
        ${typeSchema.enumValues.map((e) => e.name).join(" , ")}
      }
    """));
    return typeSchema.name;
  }

}