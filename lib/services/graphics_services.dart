import 'package:bilbakalim/services/firebase_auth_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseAuthService _authService = FirebaseAuthService();
final _firestore = FirebaseFirestore.instance;

Future<void> saveGraphic(
    int correct, int incorrect, String konuId, String altKonuId) async {
  try {
    final userId = _authService.fetchUserID();
    if (userId.isEmpty) throw "Kullanıcı girişi yapılmamış";

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('graphics')
        .doc('${konuId}_${altKonuId}')
        .set({
      'correct': correct,
      'incorrect': incorrect,
      'konuId': konuId,
      'altKonuId': altKonuId,
      'date': DateTime.now().toIso8601String(),
    });
  } catch (e) {
    throw "error: $e";
  }
}

Future<List<Map<String, dynamic>>> fetchGraphic(String konuId) async {
  try {
    final userId = _authService.fetchUserID();
    if (userId.isEmpty) throw "Kullanıcı girişi yapılmamış";

    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('graphics')
        .where('konuId', isEqualTo: konuId)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  } catch (e) {
    throw "error: $e";
  }
}
