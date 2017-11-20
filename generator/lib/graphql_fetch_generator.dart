library graphql_client_generator;

import 'dart:async';

import 'package:build/build.dart';
import './src/GraqphqlSetting.dart';
import './src/GraphqlSchema.dart';
import 'package:logging/logging.dart';
import './src/generator.dart';
import 'package:glob/glob.dart';

class GraphqlBuilder extends Builder {
  GraphqlSetting _setting;
  final Logger log = new Logger('GraphqlSetting');

  Resource<GraphqlSchema> _schemaResource;

  GraphqlBuilder(this._setting) {
    this._schemaResource =
    new Resource(() => new GraphqlSchema(_setting.getSchema()));
  }

  @override
  Map<String, List<String>> buildExtensions = const {
    '.graphql': const ['.graphql.dart']
  };

  @override
  Future build(BuildStep buildStep) async {
    GraphqlSchema schema = await buildStep.fetchResource(_schemaResource);
    await schema.awaitForSchema();
    var parser = new GraphqlParser(schema);
    if (!schema.fragmentsRegistered) {
      await for (AssetId aid in buildStep.findAssets(new Glob("**.graphql"))) {
        var content = await buildStep.readAsString(aid);
        parser.registerFragment(content, aid.addExtension(".dart").path);
      }
    }
    log.info("handling ${buildStep.inputId.path}");
    var output = buildStep.inputId.addExtension('.dart');
    String query = await buildStep.readAsString(buildStep.inputId);
    var module = parser.parse(query);
    var code = module.generate(output.path);
    log.info(code);
    buildStep.writeAsString(output, code);
    return new Future.value();
  }
}
