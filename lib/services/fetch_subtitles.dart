import 'package:firebase_database/firebase_database.dart';

FirebaseDatabase _database = FirebaseDatabase.instance;
final _ref = _database.ref();

Future<DataSnapshot> fetch_subtitles(int index) {
  return _ref.child("konular/$index/altkonular").get();
}
