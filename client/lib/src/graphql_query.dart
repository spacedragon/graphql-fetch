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
  GraphqlResponse(this.constructorOfData, Map mapObject) {
    super.mapObject = mapObject;
  }

  Function constructorOfData;

  T get data => MapObject.getProp(this,"data", constructorOfData) as T;

  set data(T data) => this["data"] = data;

  List<GraphqlResponseError> get errors =>
      MapObject.getProp(this,"errors", (d) => new GraphqlResponseError()..mapObject = d);

  bool hasError() {
    return errors != null && errors.length > 0;
  }
}

class GraphqlResponseError extends MapObject {
  String message;
  String requestId;
  List<String> path;
  List locations;
}

class MapObject extends Object{
  Map<String, dynamic> mapObject;

  MapObject();

   static getProp(dynamic obj, String key, Function(Map) f) {
    var value = obj[key];
    if (value is Map) {
      return f(value);
    } else if (value is List) {
      return value.map(f).toList();
    }
    return value;
  }

  dynamic operator [](String key) => mapObject[key];

  void operator []=(String key, dynamic value) {
    return mapObject[key] = value;
  }

  Map toJson() => this.mapObject;

  @override
  String toString() {
    return mapObject.toString();
  }

}

T Identity<T>(T t) => t;
