part of 'generator.dart';

class Operation extends BaseTypes {
  OperationDefinitionContext _context;
  QueryTypes _queryTypes;

  Operation(this._context, GraphqlSchema schema) : super(schema);

  void generate(String path, FileBuilder fb) {
    _queryTypes = new QueryTypes(_schema, methodName, path);

    Method method = new Method((MethodBuilder b) {
      var returns = generateReturn(fb);
      b
        ..name = methodName
        ..returns = returns[0];
      generateParameters(fb, b, path);
      b.body = generateCode(returns[1]);
    });
    fb.body.add(method);
  }

  String get methodName => _context.name;

  String get resultClassName => "${upperCaseFirst(methodName)}Result";

  generateCode(String resultClass) {
    Reference graphqlQuery =
        refer("GraphqlQuery", "package:graphql_fetch/graphql_fetch.dart");
    List<String> variables = _context.variableDefinitions.variableDefinitions
        .map((v) => '"${v.variable.name}": ${v.variable.name}')
        .toList();
    String query = wrapStringCode(_context.span.text);

    List<String> strings = _queryTypes.depFragments.map((r) => "${r
        .symbol}.fragmentString").toList(growable: true);
    strings.insert(0, "query");
    return new Code.scope((a) {
      return "const query = $query;"
          "return new ${a(graphqlQuery)}("
          "${strings.join(" + ")},"
          "{${variables.join(',')}},"
          "${resultClass}.fromMap);";
    });
  }

  generateResultClass(
      FileBuilder b, SelectionContext context, dynamic schemaObject) {
    var cls = new Class((ClassBuilder cb) => generateClass(
            cb, resultClassName, {
          schemaObject.name:
              _queryTypes.generateFieldType(b, context, schemaObject.type)
        }));
    b.body.add(cls);
    return resultClassName;
  }

  generateReturn(FileBuilder b) {
    for (SelectionContext sel in _context.selectionSet.selections) {
      String field = sel.field.fieldName.name;
      var query = this._context.TYPE.text == "mutation"
          ? _schema.findMutation(field)
          : _schema.findQuery(field);
      var className = generateResultClass(b, sel, query);
      return [
        refer("GraphqlQuery<$className>",
            "package:graphql_fetch/graphql_fetch.dart"),
        className
      ];
    }
  }

  void generateParameters(FileBuilder fb, MethodBuilder b, String path) {
    InputTypes inputTypes = new InputTypes(_schema, path);

    if (_context.variableDefinitions != null) {
      for (VariableDefinitionContext variable
          in _context.variableDefinitions.variableDefinitions) {
        String name = variable.variable.name;
        String type = variable.type.typeName.name;
        var parameterBuilder = new ParameterBuilder()
          ..name = name
          ..named = true
          ..type = inputTypes
              .generateInputType(fb, this._schema.findObject(type))
              .reference;
        if (variable.type?.EXCLAMATION?.text == "!") {
          Reference required = refer("required", "package:meta/meta.dart");
          var a = new AnnotationBuilder()
            ..code = new Code.scope((a) => '${a(required)}');
          parameterBuilder.annotations.add(a.build());
        }
        b.optionalParameters.add(parameterBuilder.build());
      }
    }
  }
}
