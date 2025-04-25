import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class DenemeSinavi {
  final String id;
  final String baslik;
  final String aciklama;
  final int sureDakika;
  final int soruSayisi;
  final Map<String, int> konuDagilimi;
  final List<Map<String, dynamic>> sorular;
  final DateTime olusturulmaTarihi;

  DenemeSinavi({
    required this.id,
    required this.baslik,
    required this.aciklama,
    required this.sureDakika,
    required this.soruSayisi,
    required this.konuDagilimi,
    required this.sorular,
    required this.olusturulmaTarihi,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'baslik': baslik,
      'aciklama': aciklama,
      'sureDakika': sureDakika,
      'soruSayisi': soruSayisi,
      'konuDagilimi': konuDagilimi,
      'sorular': sorular,
      'olusturulmaTarihi': olusturulmaTarihi.toIso8601String(),
    };
  }
}

class DenemeSinaviOlusturucu {
  static final _firestore = FirebaseFirestore.instance;
  static final _random = Random();

  static Future<List<DenemeSinavi>> denemeleriOlustur() async {
    print('Deneme sınavları oluşturuluyor...');
    
    try {
      // Tüm konuları getir
      final konularSnapshot = await FirebaseFirestore.instance.collection('konular').get();
      
      if (konularSnapshot.docs.isEmpty) {
        print('Hiç konu bulunamadı');
        return [];
      }
      
      print('${konularSnapshot.docs.length} konu bulundu');
      List<DenemeSinavi> denemeler = [];
      int denemeNo = 1;
      
      // Her konu için
      for (var konuDoc in konularSnapshot.docs) {
        print('${konuDoc.id} konusu işleniyor...');
        
        // Alt konuları getir
        final altKonularSnapshot = await konuDoc.reference.collection('altkonular').get();
        
        if (altKonularSnapshot.docs.isEmpty) {
          print('${konuDoc.id} konusunda alt konu bulunamadı');
          continue;
        }
        
        List<Map<String, dynamic>> sorular = [];
        
        // Her alt konu için
        for (var altKonuDoc in altKonularSnapshot.docs) {
          // Soruları getir
          final sorularSnapshot = await altKonuDoc.reference.collection('sorular').get();
          
          if (sorularSnapshot.docs.isNotEmpty) {
            // En fazla 3 soru al
            final altKonuSorulari = sorularSnapshot.docs
                .map((doc) => doc.data())
                .take(3)
                .toList();
            
            sorular.addAll(altKonuSorulari);
          }
        }
        
        if (sorular.isEmpty) {
          print('${konuDoc.id} konusunda soru bulunamadı');
          continue;
        }
        
        // Soruları karıştır ve en fazla 10 soru al
        sorular.shuffle();
        if (sorular.length > 10) {
          sorular = sorular.sublist(0, 10);
        }
        
        // Deneme sınavı oluştur
        final deneme = DenemeSinavi(
          id: 'deneme_$denemeNo',
          baslik: '${konuDoc.data()['baslik']} - Deneme $denemeNo',
          aciklama: '${konuDoc.data()['baslik']} konusundan ${sorular.length} soruluk deneme sınavı',
          sureDakika: sorular.length * 2, // Her soru için 2 dakika
          soruSayisi: sorular.length,
          konuDagilimi: {'${konuDoc.data()['baslik']}': sorular.length},
          sorular: sorular,
          olusturulmaTarihi: DateTime.now(),
        );
        
        denemeler.add(deneme);
        denemeNo++;
        
        print('${konuDoc.id} konusu için deneme sınavı oluşturuldu (${sorular.length} soru)');
      }
      
      print('Toplam ${denemeler.length} deneme sınavı oluşturuldu');
      return denemeler;
      
    } catch (e) {
      print('Deneme sınavları oluşturulurken hata: $e');
      rethrow;
    }
  }
}

final List<DenemeSinavi> denemeSinavlari = [
  DenemeSinavi(
    id: 'deneme1',
    baslik: 'Ekonomi Deneme 1',
    aciklama: 'Temel ekonomi kavramları üzerine hazırlanmış kapsamlı bir deneme',
    sureDakika: 30,
    soruSayisi: 20,
    konuDagilimi: {
      'Ekonomi Nedir': 5,
      'Makro Ekonomi': 5,
      'Mikro Ekonomi': 5,
      'Para Politikası': 5,
    },
    sorular: [],
    olusturulmaTarihi: DateTime.now(),
  ),
  DenemeSinavi(
    id: 'deneme2',
    baslik: 'Finans Deneme 1',
    aciklama: 'Temel finans konularını içeren deneme sınavı',
    sureDakika: 45,
    soruSayisi: 25,
    konuDagilimi: {
      'Finansal Piyasalar': 7,
      'Yatırım Araçları': 6,
      'Risk Yönetimi': 6,
      'Portföy Yönetimi': 6,
    },
    sorular: [],
    olusturulmaTarihi: DateTime.now(),
  ),
  DenemeSinavi(
    id: 'deneme3',
    baslik: 'Bankacılık Deneme 1',
    aciklama: 'Bankacılık sistemini test eden kapsamlı deneme',
    sureDakika: 40,
    soruSayisi: 20,
    konuDagilimi: {
      'Merkez Bankası': 5,
      'Ticari Bankalar': 5,
      'Bankacılık İşlemleri': 5,
      'Kredi Sistemleri': 5,
    },
    sorular: [],
    olusturulmaTarihi: DateTime.now(),
  ),
  DenemeSinavi(
    id: 'deneme4',
    baslik: 'Para Politikası Deneme 1',
    aciklama: 'Para politikası ve enstrümanları hakkında deneme sınavı',
    sureDakika: 35,
    soruSayisi: 15,
    konuDagilimi: {
      'Para Politikası Araçları': 5,
      'Merkez Bankası Operasyonları': 5,
      'Finansal İstikrar': 5,
    },
    sorular: [],
    olusturulmaTarihi: DateTime.now(),
  ),
  DenemeSinavi(
    id: 'deneme5',
    baslik: 'Makro Ekonomi Deneme 1',
    aciklama: 'Makro ekonomik göstergeler ve analizler',
    sureDakika: 50,
    soruSayisi: 30,
    konuDagilimi: {
      'GSYH': 6,
      'Enflasyon': 6,
      'İşsizlik': 6,
      'Dış Ticaret': 6,
      'Ekonomik Büyüme': 6,
    },
    sorular: [],
    olusturulmaTarihi: DateTime.now(),
  ),
]; 