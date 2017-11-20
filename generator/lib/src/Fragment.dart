part of 'generator.dart';



class Fragment extends BaseTypes{
  FragmentDefinitionContext _context;

  Fragment(this._context, GraphqlSchema schema): super(schema);

  get className => "${upperCaseFirst(_context.name)}Fragment";


  void generate(String path,FileBuilder fileBuilder){
    QueryTypes queryTypes= new QueryTypes(_schema, className, path);

    Class cls = new Class((ClassBuilder cb) {
      cb.name=className;
      String onType = this._context.typeCondition.typeName.name;
      var querySchema = this._schema.findObject(onType);
      for(SelectionContext sel in _context.selectionSet.selections) {
        String field = sel.field.fieldName.name;
        var typeSchema = querySchema.fields.firstWhere((f) => f.name == field);
        queryTypes.generateGetter(field,
            queryTypes.generateFieldType(fileBuilder, sel, typeSchema.type), cb);
      }
      FieldBuilder fb= new FieldBuilder()
      ..name = "fragmentString"
      ..modifier = FieldModifier.constant
      ..static = true
      ..type = refer("String")
      ..assignment = new Code('${wrapStringCode(_context.span.text)}');
      cb.fields.add(fb.build());
    });
    fileBuilder.body.add(cls);
    return className;
  }

  registerFragment(String path) {
    _schema.registerFragment(path, className);
  }
  
}