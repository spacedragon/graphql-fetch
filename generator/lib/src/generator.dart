import './GraphqlSchema.dart';
import 'package:graphql_parser/graphql_parser.dart';
import 'package:graphql_fetch/graphql_fetch.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;

part 'BaseTypes.dart';

part 'Fragment.dart';

part 'InputTypes.dart';

part 'QueryTypes.dart';

part 'Operation.dart';

class GraphqlParser {
  GraphqlSchema _schema;

  GraphqlParser(this._schema);

  Module parse(String query) {
    final parser = new Parser(scan(query));
    final document = parser.parseDocument();
    var fragments = document.definitions
        .where((d) => d is FragmentDefinitionContext)
        .map((c) => new Fragment(c, _schema));
    var operations = document.definitions
        .where((d) => d is OperationDefinitionContext)
        .map((c) => new Operation(c, _schema));
    return new Module(operations.toList(), fragments.toList());
  }

  registerFragment(String content, String file) {
    final parser = new Parser(scan(content));
    final document = parser.parseDocument();
    var fragments = document.definitions
        .where((d) => d is FragmentDefinitionContext)
        .map((c) => new Fragment(c, _schema));
    fragments.forEach((f)=> f.registerFragment(file));
  }
}

class Module {
  List<Operation> _operations;
  List<Fragment> _fragments;

  Module(this._operations, this._fragments);

  String generate(String path) {
    final library = new File((FileBuilder b) {
      _fragments.forEach((f) => f.generate(path, b));
      _operations.forEach((o) => o.generate(path, b));
    });
    final emitter = new DartEmitter(new Allocator());
    return new DartFormatter()
        .format('// GENERATED CODE - DO NOT MODIFY BY HAND\n\n'
            '${library.accept(emitter)}');
  }
}
