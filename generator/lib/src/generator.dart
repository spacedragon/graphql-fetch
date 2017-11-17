import './GraphqlSchema.dart';
import 'package:graphql_parser/graphql_parser.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

class GraphqlParser {
  GraphqlSchema _schema;

  GraphqlParser(this._schema);

  Module parse(String query) {
    final parser = new Parser(scan(query));
    final document = parser.parseDocument();

    var operations = document.definitions
        .where((d) => d is OperationDefinitionContext)
        .map((c) => new Operation(c, _schema));
    return new Module(operations.toList());
  }
}

class Module {
  List<Operation> _operations;

  Module(this._operations);

  String generate() {
    final library = new File((FileBuilder b) {
      for (var op in _operations) {
        op.generate(b);
      }
    });
    final emitter = new DartEmitter(new Allocator());
    return new DartFormatter()
        .format('// GENERATED CODE - DO NOT MODIFY BY HAND\n\n'
            '${library.accept(emitter)}');
  }
}

class Operation {
  GraphqlSchema _schema;

  OperationDefinitionContext _context;

  Operation(this._context, this._schema);

  void generate(FileBuilder fb) {
    Method method = new Method((MethodBuilder b) {
      var returns = generateReturn(fb);
      b
        ..name = getMethodName()
        ..returns = returns[0];
      b.body = generateCode(returns[1]);
      generateParameters(fb,b);
    });
    fb.body.add(method);
  }

  String getMethodName() => _context.name;

  generateCode(String resultClass) {
    Reference graphqlQuery =
        refer("GraphqlQuery", "package:graphql_fetch/graphql_fetch.dart");
    List<String> variables = _context.variableDefinitions.variableDefinitions
        .map((v) => '"${v.variable.name}": ${v.variable.name}').toList();
    String query = "'''${_context.span.text.replaceAll("\$", "\\\$")}'''";

    return new Code.scope((a) {
      return "return new ${a(graphqlQuery)}("
          "${query},"
          "{${variables.join(',')}},"
          "${resultClass}.fromMap);";
    });
  }

  upperCaseFirst(String s) {
    return s[0].toUpperCase() + s.substring(1);
  }
  generateFieldType(FileBuilder b, SelectionContext context,dynamic typeSchema) {
    switch(typeSchema.kind) {
      case "NON_NULL":
        return generateFieldType(b,context, typeSchema.ofType);
      case "LIST":
        Reference genericType = generateFieldType(b,context, typeSchema.ofType)[0];
        return [refer("List<${genericType.symbol}>", "dart:core"), genericType];
      case "OBJECT":
        String typeName = typeSchema.name;
        var className= generateClassForType(b, context, _schema.findObject(typeName));
        return [refer(className)];
      case "SCALAR":
        return [findDartType(typeSchema.name)];
      default:
        return [refer("dynamic","dart:core")];
    }
  }

  Reference findDartType(String graphqlType) {
    switch (graphqlType) {
      case "Int":
        return refer("int", "dart:core");
      case "ID":
        return refer("String","dart:core");
      case "String":
        return refer("String","dart:core");
      case "Float":
        return refer("double","dart:core");
      case "Boolean":
        return refer("bool","dart:core");
      case "DateTime":
        return refer("DatTime","dart:core");
      default :
        return refer("dynamic","dart:core");
    }
  }

  final baseModel = refer("MapObject", "package:graphql_fetch/graphql_fetch.dart");


  generateClassForType(FileBuilder b, SelectionContext context,dynamic objectSchema) {
    Class clazz = new Class((ClassBuilder cb) {
      cb.name = objectSchema.name;
     /* cb.annotations.add(new Annotation((AnnotationBuilder ab) =>
      ab.code=new Code.scope((a) => a(_serializable)) ));*/
      cb.extend = baseModel;
      context.field.selectionSet.selections.forEach((f) {
        var fieldName = f.field.fieldName.name;
        var fieldObject = objectSchema.fields.firstWhere((f) => f.name == fieldName);
        var returnType = generateFieldType(b, f, fieldObject.type);
        generateGetter(fieldName, returnType, cb);

      });
      generateCreator(cb);
    });
    b.body.add(clazz);
    return objectSchema.name;
  }

  void generateGetter(String fieldName, returnType, ClassBuilder cb) {
     MethodBuilder mb =new MethodBuilder()
      ..name = fieldName
      ..type = MethodType.getter
      ..lambda = true
      ..returns = returnType[0];
    if(returnType.length == 2) {
      mb.body = new Code.scope((a) => 'getProp("${fieldName}",${a(returnType[1])}.fromMap)');
    } else  if(returnType[0].url == "dart:core") {
      final identity = refer("Identity", "package:graphql_fetch/graphql_fetch.dart");
      mb.body = new Code.scope((a) => 'getProp("${fieldName}",${a(identity)})');
    }else {
      mb.body = new Code.scope((a) => 'getProp("${fieldName}",${a(returnType[0])}.fromMap)');
    }
    cb.methods.add(mb.build());
  }
  generateResultClass(FileBuilder b,SelectionContext context, dynamic schemaObject) {
    var className = "${upperCaseFirst(getMethodName())}Result";

    Class cls = new Class((ClassBuilder cb) {
      cb.name=className;
      /*cb.annotations.add(new Annotation((AnnotationBuilder ab) =>
      ab.code=new Code.scope((a) => a(_serializable)) ));*/
      cb.extend = baseModel;
      FieldBuilder fb=new FieldBuilder();

      generateGetter(schemaObject.name , this.generateFieldType(b,context,schemaObject.type), cb);
      generateCreator(cb);
    });
    b.body.add(cls);
    return className;
  }

  generateReturn(FileBuilder b) {
    for(SelectionContext sel in _context.selectionSet.selections){
      String field = sel.field.fieldName.name;
      var query = this._context.TYPE.text =="mutation"?
      _schema.findMutation(field): _schema.findQuery(field);
      var className = generateResultClass(b, sel, query);
      return [refer("GraphqlQuery<$className>", "package:graphql_fetch/graphql_fetch.dart"), className];
    }
  }

  void generateParameters(FileBuilder fb, MethodBuilder b) {
    if (_context.variableDefinitions != null) {
      for (VariableDefinitionContext variable
          in _context.variableDefinitions.variableDefinitions) {
        String name = variable.variable.name;
        String type = variable.type.typeName.name;
        var parameterBuilder = new ParameterBuilder()
          ..name = name
          ..named = true
          ..type = generateInputType(fb, this._schema.findObject(type));
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
  void generateCreator(ClassBuilder cb) {
    cb.methods.add(new Method((MethodBuilder mb){
      mb..static = true
          ..name = "fromMap"
          ..requiredParameters.add(new Parameter((pb) => pb..name = "map"))
          ..lambda = true
          ..body = new Code("new ${cb.name}()..mapObject = map")
          ..returns = refer(cb.name);
    }));
  }

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
    Class clazz = new Class((ClassBuilder cb) {
      cb.name = typeSchema.name;
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
    return typeSchema.name;
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
