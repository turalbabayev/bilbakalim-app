import 'package:bilbakalim/services/fetch_device_info.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future<User?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String surname,
    required String animal,
  }) async {
    try {
      String? id = await fetchDeviceID();

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
          'animal': animal,
          'has_purchased': false,
          'purchase_date': null,
          'purchase_amount': null,
          'purchase_reference': null,
          'created_at': DateTime.now().toIso8601String(),
        });
        final prefs = await _prefs;
        await prefs.setString('animal', animal);
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
      String? id = await fetchDeviceID();

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      if (userDoc['device_id'] == null) {
        throw Exception("Kullanıcı belgesi veya device_id bulunamadı.");
      }
      if (userDoc.data()!['device_id'] == id) {
        final prefs = await _prefs;
        prefs.setString("animal", userDoc.data()!['animal']);
        return userCredential.user;
      } else {
        throw "Cihaz Kimlikleri Uyuşmuyor.";
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-credential':
          throw Exception("Kullanıcı adı veya şifre hatalı.");
        case 'too-many-requests':
          throw Exception(
              "Çok fazla giriş denemesi. Lütfen daha sonra tekrar deneyin.");
        default:
          throw Exception(
              "Giriş sırasında bir hata oluştu: ${e.message} ${e.code}");
      }
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      final prefs = await _prefs;
      prefs.clear();
    } catch (e) {
      throw Exception("Çıkış yaparken bir sorun oluştu: $e");
    }
  }

  String fetchUserID() {
    return _auth.currentUser?.uid ?? '';
  }

  Future<Map<String, dynamic>> checkPurchaseStatus() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .get();

      if (!userDoc.exists) {
        return {
          'has_purchased': false,
          'message': 'Kullanıcı bulunamadı'
        };
      }

      final data = userDoc.data()!;
      final bool hasPurchased = data['has_purchased'] == true;

      return {
        'has_purchased': hasPurchased,
        'message': hasPurchased ? 'Premium içeriğe erişiminiz var' : 'Premium içeriğe erişiminiz yok'
      };
    } catch (e) {
      print('Ödeme durumu kontrol edilirken hata oluştu: $e');
      return {
        'has_purchased': false,
        'message': 'Bir hata oluştu'
      };
    }
  }

  Future<void> updatePurchaseStatus({
    required bool status,
    double? amount,
    String? reference,
  }) async {
    try {
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser?.uid);

      final updateData = <String, dynamic>{
        'has_purchased': status ? true : false,
      };

      if (status && amount != null && reference != null) {
        updateData.addAll({
          'purchase_date': DateTime.now().toIso8601String(),
          'purchase_amount': amount,
          'purchase_reference': reference,
        });
      }

      await userDoc.update(updateData);
    } catch (e) {
      print('Ödeme durumu güncellenirken hata oluştu: $e');
      throw Exception('Ödeme durumu güncellenemedi: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserDetails() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .get();

      if (!userDoc.exists) {
        return null;
      }

      return userDoc.data();
    } catch (e) {
      print('Kullanıcı bilgileri alınırken hata oluştu: $e');
      return null;
    }
  }

  Future<bool> isUserLoggedIn() async {
    try {
      User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        return false;
      }
      
      // Firestore'da kullanıcının var olup olmadığını kontrol et
      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
          
      return userDoc.exists;
    } catch (e) {
      print('Kullanıcı giriş durumu kontrol edilirken hata: $e');
      return false;
    }
  }
}
