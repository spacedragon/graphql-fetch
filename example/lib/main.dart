import 'package:graphql_fetch/graphql_fetch.dart';
import './query.graphql.dart';



main() async{
  String endpoint = "http://localhost:60000/simple/v1/cj9v7fprz00140114ed9qw3lz";

  GraphqlClient client =new GraphqlClient(endpoint);
  GraphqlResponse<SomeShowResult> ret1 = await client.query(someShow(first: 5));
  ret1.data?.allShows.forEach((s){
    print(s);
    print(s.createdAt.millisecondsSinceEpoch);
  });

  GraphqlResponse<FindShowResult> ret = await client.query(findShow(
    filter: new ShowFilter(aliases_some: new ShowAliasFilter(alias_contains: "Lethal Weapon"))
  ));
  print(ret.data?.allShows);
}