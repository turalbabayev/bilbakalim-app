import 'package:bilbakalim/services/fetch_device_info.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String surname,
  }) async {
    try {
      String? id = await fetchDeviceID() as String?;

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': userCredential.user!.email,
          'name': name,
          'surname': surname,
          'device_id': id,
          'device_type': 'Android',
        });
        return userCredential.user;
      }
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception("Kayıt sırasında bir hata oluştu.");
    }
  }

  Future<User?> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      String? id = await fetchDeviceID() as String?;

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      if (userDoc.data()!['device_id'] == id) {
        return userCredential.user;
      } else {
        throw "Cihaz Kimlikleri Uyuşmuyor.";
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception("Giriş sırasında bir hata oluştu: $e");
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception("Çıkış yaparken bir sorun oluştu: $e");
    }
  }
}
