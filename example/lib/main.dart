import 'package:graphql_fetch/graphql_fetch.dart';
import './query.graphql.dart';



main() async{
  String endpoint = "http://localhost:60000/simple/v1/cj9v7fprz00140114ed9qw3lz";

  GraphqlClient client =new GraphqlClient(endpoint);
  GraphqlResponse<TestResult> result =await client.query(test(first: 5));
  TestResult data = result.data;
  print(data.allShows);

}