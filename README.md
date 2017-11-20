# graphql-fetch


### How to use

1. Add dependencies to pubspec.yaml
```yaml
dependencies:
  graphql_fetch: any
  ...
dev_dependencies:
  graphql_fetch_generator: any
  ...
```

2. Create a program tool/build.dart: 
```dart
import 'dart:async';
import 'package:build_runner/build_runner.dart';
import 'package:graphql_fetch_generator/action.dart';

var action = createBuildAction(
    createSetting(
        schemaUrl: "$schemaUrl"));


Future main() async {
  await build([action], deleteFilesByDefault: true, writeToCache: false);
  // or you can watch file changes;
  // await watch([action]);
}
```
> change $schemaUrl to your graphql schema url address or specify a schema.json file

3. Put any `*.graphql` file in your source folder

4. Run `tool/build` to generate `*.graphql.dart` files

5. use generator code:

```dart
import 'package:graphql_fetch/graphql_fetch.dart';
import './query.graphql.dart';  // generated file 

main() {
  String endpoint = "...";

  GraphqlClient client =new GraphqlClient(endpoint);
  // use generated method
  GraphqlResponse<TestResult> result =await client.query(test(first: 5));
  TestResult data = result; // type-safe result
}
```

### [example](https://github.com/spacedragon/graphql-fetch/tree/master/example) 