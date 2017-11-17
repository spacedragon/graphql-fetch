import 'dart:async';
import 'package:code_builder/code_builder.dart';

class GraphqlSchema {

  Future _schemaFuture;

  dynamic _schema;

  GraphqlSchema(this._schemaFuture);

  Future awaitForSchema() async {
    if(this._schema==null) {
      this._schema = await _schemaFuture;
    }
    return this._schema;
  }

  findQuery(String queryName) {
    String queryTypeName = _schema.queryType.name;
    var queryObject = _schema.types.firstWhere((d) => d.name==queryTypeName);
    return queryObject.fields.firstWhere((d) => d.name == queryName,orElse : ()=> null);
  }

  findObject(String typeName) {
    return _schema.types.firstWhere((d) => d.name==typeName, orElse: () => null);
  }

  findMutation(String mutationName) {
    String mutationTypeName = _schema.mutationType.name;
    var queryObject = _schema.types.firstWhere((d) => d.name==mutationTypeName);
    return queryObject.fields.firstWhere((d) => d.name == mutationName,orElse : ()=> null);
  }
}