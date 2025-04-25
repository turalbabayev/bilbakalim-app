import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Cache için static değişken
class TitlesCache {
  static Map<String, String>? _cachedTitles;
  static DateTime? _lastFetchTime;
  
  // Cache'in geçerli olup olmadığını kontrol et (5 dakika)
  static bool get isValid {
    if (_cachedTitles == null || _lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < const Duration(minutes: 5);
  }
  
  // Cache'i güncelle
  static void update(Map<String, String> titles) {
    _cachedTitles = titles;
    _lastFetchTime = DateTime.now();
  }
  
  // Cache'i temizle
  static void clear() {
    _cachedTitles = null;
    _lastFetchTime = null;
  }
}

Future<Map<String, String>> fetchTitles() async {
  // Eğer cache geçerliyse, cache'den döndür
  if (TitlesCache.isValid && TitlesCache._cachedTitles != null) {
    debugPrint('Cache\'den başlıklar alındı');
    return TitlesCache._cachedTitles!;
  }

  debugPrint('1. Firestore\'dan başlıklar çekiliyor...');
  
  try {
    // Konular koleksiyonundan tüm dokümanları çek
    final QuerySnapshot<Map<String, dynamic>> snapshot = 
        await FirebaseFirestore.instance.collection('konular').get();
    
    if (snapshot.docs.isEmpty) {
      debugPrint('2. Veri bulunamadı');
      return {};
    }

    final Map<String, String> titles = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey('baslik')) {
        titles[doc.id] = data['baslik'].toString();
      }
    }

    // Cache'i güncelle
    TitlesCache.update(titles);
    debugPrint('3. ${titles.length} başlık alındı ve cache\'lendi');
    
    return titles;
  } catch (e) {
    debugPrint('Hata: $e');
    return {};
  }
}

// Alt konuları çekmek için yeni fonksiyon
Future<Map<String, dynamic>> fetchSubtitles(String konuId) async {
  try {
    final DocumentSnapshot<Map<String, dynamic>> snapshot = 
        await FirebaseFirestore.instance.collection('konular').doc(konuId).get();
        
    if (!snapshot.exists) {
      return {};
    }
    
    final data = snapshot.data();
    if (data == null || !data.containsKey('altkonular')) {
      return {};
    }
    
    return data['altkonular'] as Map<String, dynamic>;
  } catch (e) {
    debugPrint('Alt konular çekilirken hata: $e');
    return {};
  }
} 