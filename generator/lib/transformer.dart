import './graphql_fetch_generator.dart';
import 'package:barback/barback.dart';
import 'package:build_barback/build_barback.dart';
import 'package:graphql_fetch_generator/src/GraphqlSetting.dart';


Map<Symbol, dynamic> _symbolizeKeys(Map<String, dynamic> map){
  final result = new Map<Symbol, dynamic>();
  map.forEach((String k,v) { result[new Symbol(k)] = v; });
  return result;
}

class GQLTransformer extends BuilderTransformer {
  GQLTransformer.asPlugin(BarbackSettings settings)
      : super(new GraphqlBuilder(
      Function.apply(createSetting, [], _symbolizeKeys(settings.configuration))));
}