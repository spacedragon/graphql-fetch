import 'package:graphql_fetch/graphql_fetch.dart';
import './query.graphql.dart';



main() async{
  String endpoint = "http://localhost:60000/simple/v1/cj9v7fprz00140114ed9qw3lz";

  GraphqlClient client =new GraphqlClient(endpoint);
  var result =await client.query(test(first: 5));
  var data = result.data;
  data.allShows.forEach((s) {
    print(s.id);
    print(s.episodes);
    s.episodes.forEach((e) => print(e.episode));
  });
  GraphqlResponse<CreateUserResult> ret = await client.query(createUser(name: "test", alias: "test"));
  print(ret.data.createUser.name);
}