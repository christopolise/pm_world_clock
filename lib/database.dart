import 'package:firebase_database/firebase_database.dart';
// import 'post.dart';

final databaseReference = FirebaseDatabase.instance.reference();

DatabaseReference savePost() {
  var id = databaseReference.child('posts/').push();
  print(databaseReference);
}
