import 'dart:async';
import 'package:build_runner/build_runner.dart';
import 'package:graphql_fetch_generator/action.dart';

var action = createBuildAction(
    createSetting(
        schemaUrl: "http://localhost:60000/simple/v1/cj9v7fprz00140114ed9qw3lz"));


Future main() async {
  await build([action], deleteFilesByDefault: true);
}