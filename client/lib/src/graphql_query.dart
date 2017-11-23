part of 'client.dart';

typedef T decoder<T>(String);

class JsonResponse {
  String _body;

  JsonResponse(this._body);

  T decode<T>(decoder) {
    return decoder(_body);
  }

  String get body => _body;
}

class GraphqlQuery<T> {
  String query;
  Map<String, dynamic> variables;

  GraphqlQuery(this.query, this.variables, this.constructorOfData);

  Function constructorOfData;
}

class GraphqlResponse<T> extends MapObject {
  GraphqlResponse(this.dataCreator, Map mapObject) {
    super.map = mapObject;
  }

  Function dataCreator;

  T get data => dataCreator(MapObject.get(this, "data"));

  List<GraphqlResponseError> get errors =>
      MapObject.get(this, "errors")?.map(GraphqlResponseError.fromMap);

  bool hasError() {
    return errors != null && errors.length > 0;
  }
}

class GraphqlResponseError extends MapObject {
  String get message => this["message"];

  String get requestId => this["requestId"];

  List<String> get path => this["path"];

  List get locations => this["path"];

  static GraphqlResponseError fromMap(Map map) {
    return new GraphqlResponseError()..map.addAll(map);
  }

  GraphqlResponseError copy({String message, String requestId}) {
    return new GraphqlResponseError()
      ..map.addAll(this.map)
      ..map["message"] = message
      ..map["requestId"] = requestId;
  }
}

class MapObject {
  @protected
  Map<String, dynamic> map = {};

  MapObject.fromMap(this.map) {
    compact();
  }

  MapObject();

  static get(dynamic obj, String key) {
    return obj[key];
  }

  compact() {
    List<String> keys = [];
    var values = [];
    map.forEach((key, value) {
      if (value != null) {
        keys.add(key);
        values.add(value);
      }
    });
    this.map = new Map.fromIterables(keys, values);
  }

  dynamic operator [](String key) => map[key];

  Map toJson() => map;

  @override
  String toString() {
    return map.toString();
  }
}

T Identity<T>(T t) => t;
