import 'dart:async';
import 'package:graphql_fetch_generator/graphql_fetch_generator.dart';
import 'package:build_runner/build_runner.dart';
import 'package:graphql_fetch_generator/src/GraqphqlSetting.dart';


final phases = [
  new BuildAction(
    new GraphqlBuilder(createGraphqlSetting(schemaUrl: "http://localhost:60000/simple/v1/cj9mldxkd008c017544mu2vhw")),
    new PackageGraph.forThisPackage().root.name,
    inputs: const ['**/*.graphql'],
  )
];

Future main() async {
  await build(phases, deleteFilesByDefault: true);
}