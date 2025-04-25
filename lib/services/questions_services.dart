import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;

Future<List<Map<String, dynamic>>> fetch_questions(String bolumId, String altKonuId) async {
  try {
    print('Sorular çekiliyor...');
    print('Bölüm ID: $bolumId');
    print('Alt Konu ID: $altKonuId');
    
    List<Map<String, dynamic>> tumSorular = [];

    // 1. Alt konunun sorular subcollection'ından soruları çekelim
    print('\n1. Alt konunun sorular subcollection\'ından soruları çekiyorum...');
    final altKonuSorularRef = _firestore.collection('konular')
                                      .doc(bolumId)
                                      .collection('altkonular')
                                      .doc(altKonuId)
                                      .collection('sorular');
    
    final altKonuSorularSnapshot = await altKonuSorularRef.get();
    
    if (altKonuSorularSnapshot.docs.isNotEmpty) {
      print('✓ Alt konunun sorular subcollection\'ında ${altKonuSorularSnapshot.docs.length} soru bulundu');
      final altKonuSorulari = altKonuSorularSnapshot.docs.map((doc) => {
        'id': doc.id,
        'soruNumarasi': doc.data()['soruNumarasi'] ?? 0,
        ...doc.data(),
      }).toList();
      
      tumSorular.addAll(altKonuSorulari);
    } else {
      print('× Alt konunun sorular subcollection\'ında hiç soru bulunamadı');
    }

    // 2. Alt dalların sorular subcollection'larından soruları çekelim
    print('\n2. Alt dalları kontrol ediyorum...');
    final altdallarRef = _firestore.collection('konular')
                                 .doc(bolumId)
                                 .collection('altkonular')
                                 .doc(altKonuId)
                                 .collection('altdallar');
    
    final altdallarSnapshot = await altdallarRef.get();

    if (altdallarSnapshot.docs.isEmpty) {
      print('× Hiç alt dal bulunamadı');
    } else {
      print('✓ ${altdallarSnapshot.docs.length} alt dal bulundu');
      
      // Her alt dalın sorularını çekelim
      for (var altdal in altdallarSnapshot.docs) {
        final altdalData = altdal.data();
        final altdalBaslik = altdalData['baslik'] as String? ?? 'Bilinmeyen Alt Dal';
        
        print('\nAlt Dal: $altdalBaslik (${altdal.id})');
        final altdalSorularRef = altdallarRef.doc(altdal.id).collection('sorular');
        final altdalSorularSnapshot = await altdalSorularRef.get();
        
        if (altdalSorularSnapshot.docs.isNotEmpty) {
          print('✓ ${altdalSorularSnapshot.docs.length} soru bulundu');
          final altdalSorulari = altdalSorularSnapshot.docs.map((doc) => {
            'id': doc.id,
            'soruNumarasi': doc.data()['soruNumarasi'] ?? 0,
            ...doc.data(),
          }).toList();
          
          tumSorular.addAll(altdalSorulari);
        } else {
          print('× Bu alt dalda hiç soru bulunamadı');
        }
      }
    }

    if (tumSorular.isEmpty) {
      print('\n❌ Hiç soru bulunamadı (ne alt konunun kendisinde ne de alt dallarda)');
      return [];
    }

    // Tüm soruları soru numarasına göre sıralayalım
    tumSorular.sort((a, b) => (a['soruNumarasi'] as int).compareTo(b['soruNumarasi'] as int));
    
    print('\n✅ Toplam ${tumSorular.length} soru bulundu ve sıralandı');
    
    return tumSorular;
    
  } catch (e) {
    print('\n❌ Sorular çekilirken hata: $e');
    return [];
  }
}

Future<List<Map<String, dynamic>>> fetch_subquestions(
    String bolumId, String altKonuId, String altDalId) async {
  try {
    final DocumentSnapshot<Map<String, dynamic>> snapshot = 
        await _firestore.collection('konular').doc(bolumId).get();
        
    if (!snapshot.exists) {
      return [];
    }
    
    final data = snapshot.data();
    if (data == null || !data.containsKey('altkonular')) {
      return [];
    }
    
    final altkonular = data['altkonular'] as Map<String, dynamic>;
    if (!altkonular.containsKey(altKonuId) || 
        !altkonular[altKonuId].containsKey('altdallar') ||
        !altkonular[altKonuId]['altdallar'].containsKey(altDalId) ||
        !altkonular[altKonuId]['altdallar'][altDalId].containsKey('sorular')) {
      return [];
    }
    
    final sorular = altkonular[altKonuId]['altdallar'][altDalId]['sorular'] as Map<String, dynamic>;
    return sorular.entries.map((e) => {
      'id': e.key,
      ...Map<String, dynamic>.from(e.value as Map),
    }).toList();
  } catch (e) {
    print('Alt dal soruları çekilirken hata: $e');
    return [];
  }
}

Future<void> likeOrUnlikeQuestions(String bolumId, String altKonuId,
    String questionId, bool isLiked) async {
  final which = isLiked ? "liked" : "unliked";
  
  try {
    // Transaction kullanarak güvenli bir şekilde güncelleme yapalım
    await _firestore.runTransaction((transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = 
          await transaction.get(_firestore.collection('konular').doc(bolumId));
          
      if (!snapshot.exists) return;
      
      final data = snapshot.data();
      if (data == null || !data.containsKey('altkonular')) return;
      
      final altkonular = data['altkonular'] as Map<String, dynamic>;
      if (!altkonular.containsKey(altKonuId) || 
          !altkonular[altKonuId].containsKey('sorular') ||
          !altkonular[altKonuId]['sorular'].containsKey(questionId)) return;
          
      final soru = altkonular[altKonuId]['sorular'][questionId] as Map<String, dynamic>;
      final int currentCount = soru[which] ?? 0;
      
      // Yeni değeri ayarla
      altkonular[altKonuId]['sorular'][questionId][which] = currentCount + 1;
      
      // Dokümanı güncelle
      transaction.update(_firestore.collection('konular').doc(bolumId), {
        'altkonular': altkonular,
      });
    });
    
    print('$which değeri güncellendi');
  } catch (e) {
    print('Beğeni güncellenirken hata: $e');
  }
}

Future<void> reportQuestion(String bolumId, String altKonuId, String questionId) async {
  try {
    // Transaction kullanarak güvenli bir şekilde güncelleme yapalım
    await _firestore.runTransaction((transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = 
          await transaction.get(_firestore.collection('konular').doc(bolumId));
          
      if (!snapshot.exists) return;
      
      final data = snapshot.data();
      if (data == null || !data.containsKey('altkonular')) return;
      
      final altkonular = data['altkonular'] as Map<String, dynamic>;
      if (!altkonular.containsKey(altKonuId) || 
          !altkonular[altKonuId].containsKey('sorular') ||
          !altkonular[altKonuId]['sorular'].containsKey(questionId)) return;
          
      final soru = altkonular[altKonuId]['sorular'][questionId] as Map<String, dynamic>;
      final int currentReports = soru['report'] ?? 0;
      
      // Yeni değeri ayarla
      altkonular[altKonuId]['sorular'][questionId]['report'] = currentReports + 1;
      
      // Dokümanı güncelle
      transaction.update(_firestore.collection('konular').doc(bolumId), {
        'altkonular': altkonular,
      });
    });
    
    print('Soru rapor edildi');
  } catch (e) {
    print('Soru raporlanırken hata: $e');
  }
}
