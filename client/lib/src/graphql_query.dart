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

  T get data => getProp("data", constructorOfData) as T;

  set data(T data) => this["data"] = data;

  List<GraphqlResponseError> get errors =>
      getProp("errors", (d) => new GraphqlResponseError()..mapObject = d);

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

class MapObject {
  Map<String, dynamic> mapObject;

  MapObject();

  dynamic getProp<T>(String key, Function(Map) f) {
    var value = this[key];
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
}

T Identity<T>(T t) => t;
