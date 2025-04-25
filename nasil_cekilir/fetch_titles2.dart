import 'package:firebase_database/firebase_database.dart';

FirebaseDatabase _database = FirebaseDatabase.instance;
final _ref = _database.ref();

Future<DataSnapshot> fetchTitles() {
  print(_ref.child("konular"));
  return _ref.child("konular").get();
}
