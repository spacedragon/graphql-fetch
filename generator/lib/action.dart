
import 'package:build_runner/build_runner.dart';
import 'package:graphql_fetch_generator/graphql_fetch_generator.dart';
import 'package:graphql_fetch_generator/src/GraphqlSetting.dart';
export 'package:graphql_fetch_generator/src/GraphqlSetting.dart' show createSetting;

createBuildAction(GraphqlBuildSetting setting) {
  return new BuildAction(
    new GraphqlBuilder(setting),
    new PackageGraph.forThisPackage().root.name,
    inputs: const ['**/*.graphql'],
  );
}

