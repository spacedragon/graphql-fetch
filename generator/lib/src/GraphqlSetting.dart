import 'dart:async';
import 'package:graphql_fetch/src/client.dart';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:json_object/json_object.dart';

GraphqlBuildSetting createSetting(
    {String schemaUrl,
      String method: "post",
      bool postIntrospectionQuery: true,
      String schemaFile}) {
  return new GraphqlBuildSetting(
      schemaUrl, method, postIntrospectionQuery, schemaFile);
}

class GraphqlBuildSetting {
  final Logger log = new Logger('GraphqlSetting');

  String schemaUrl;
  String method;
  bool postIntrospectionQuery;

  String schemaFile;

  GraphqlBuildSetting(this.schemaUrl, this.method, this.postIntrospectionQuery,
      this.schemaFile);

  dynamic _schemaObject = null;

  Future getSchema() async {
    if (_schemaObject == null) {
      if (schemaFile != null) {
        log.info("reading schema from file:${schemaFile}");
        var fileContent = await new File(schemaFile).readAsString();
        _schemaObject = new JsonObject.fromJsonString(fileContent);
      } else if (schemaUrl != null) {
        var client = new RestClient(this.schemaUrl);
        log.info("fetching schema from url:${this.schemaUrl}");
        JsonResponse result;
        if (method == "post") {
          var query = {};
          if (postIntrospectionQuery) {
            query = {"query": IntrospectionQuery};
          }
          result = await client.postJson("", query);
        } else {
          result = await client.getJson("", {});
        }
        _schemaObject = result.decode((d) => new JsonObject.fromJsonString(d)).data.__schema;
      }
    }
    return _schemaObject;
  }

  static const String IntrospectionQuery = """
     query IntrospectionQuery {
    __schema {
      queryType { name }
      mutationType { name }
      subscriptionType { name }
      types {
        ...FullType
      }
      directives {
        name
        description
        locations
        args {
          ...InputValue
        }
      }
    }
  }

  fragment FullType on __Type {
    kind
    name
    description
    fields(includeDeprecated: true) {
      name
      description
      args {
        ...InputValue
      }
      type {
        ...TypeRef
      }
      isDeprecated
      deprecationReason
    }
    inputFields {
      ...InputValue
    }
    interfaces {
      ...TypeRef
    }
    enumValues(includeDeprecated: true) {
      name
      description
      isDeprecated
      deprecationReason
    }
    possibleTypes {
      ...TypeRef
    }
  }

  fragment InputValue on __InputValue {
    name
    description
    type { ...TypeRef }
    defaultValue
  }

  fragment TypeRef on __Type {
    kind
    name
    ofType {
      kind
      name
      ofType {
        kind
        name
        ofType {
          kind
          name
          ofType {
            kind
            name
            ofType {
              kind
              name
              ofType {
                kind
                name
                ofType {
                  kind
                  name
                }
              }
            }
          }
        }
      }
    }
  }
  """;
}
