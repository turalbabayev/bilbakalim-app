import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bilbakalim/styles/app_theme.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({Key? key}) : super(key: key);

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  bool _isLoading = false;
  Package? _package;

  @override
  void initState() {
    super.initState();
    _initPlatformState();
  }

  Future<void> _initPlatformState() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Purchases.setLogLevel(LogLevel.verbose);
      debugPrint('RevenueCat log seviyesi ayarlandı');

      // Önce kullanıcı bilgisini al
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('Kullanıcı oturum açmamış');
        return;
      }
      debugPrint('Firebase Kullanıcı ID: ${user.uid}');

      // RevenueCat API anahtarını ayarla
      final configuration = PurchasesConfiguration('appl_eNhvVMIKTHRSaBhJlmeTQmsMNuJ');
      await Purchases.configure(configuration);
      debugPrint('RevenueCat yapılandırması tamamlandı');

      // Kullanıcı kimliğini ayarla
      try {
        final loginResult = await Purchases.logIn(user.uid);
        debugPrint('RevenueCat kullanıcı girişi yapıldı');
        debugPrint('Login sonucu - Kullanıcı ID: ${loginResult.customerInfo.originalAppUserId}');
      } catch (e) {
        debugPrint('RevenueCat login hatası: $e');
      }

      // Direkt ürün kontrolü
      try {
        debugPrint('Ürün listesi alınıyor...');
        final products = await Purchases.getProducts(
          ['bil_bakalim_pro'],
          productCategory: ProductCategory.nonSubscription
        );
        debugPrint('Bulunan ürün sayısı: ${products.length}');
        for (var product in products) {
          debugPrint('Ürün bilgisi:');
          debugPrint('- ID: ${product.identifier}');
          debugPrint('- Başlık: ${product.title}');
          debugPrint('- Açıklama: ${product.description}');
          debugPrint('- Fiyat: ${product.priceString}');
        }
      } catch (e) {
        debugPrint('Ürün listesi alınırken hata: $e');
      }

      // Mevcut kullanıcı durumunu kontrol et
      final customerInfo = await Purchases.getCustomerInfo();
      debugPrint('Müşteri bilgisi alındı: ${customerInfo.originalAppUserId}');
      debugPrint('Müşteri ID: ${customerInfo.originalAppUserId}');
      debugPrint('Aktif entitlementlar: ${customerInfo.entitlements.active.keys.join(", ")}');
      debugPrint('Tüm entitlementlar: ${customerInfo.entitlements.all.keys.join(", ")}');

      // Paketleri getir
      final offerings = await Purchases.getOfferings();
      debugPrint('Offerings yüklendi');
      debugPrint('Current offering: ${offerings.current?.identifier}');
      debugPrint('Tüm offering\'ler: ${offerings.all.keys.join(", ")}');
      
      if (offerings.current != null) {
        debugPrint('Mevcut offering bulundu: ${offerings.current!.identifier}');
        debugPrint('Paket sayısı: ${offerings.current!.availablePackages.length}');
        
        if (offerings.current!.availablePackages.isNotEmpty) {
          for (var package in offerings.current!.availablePackages) {
            debugPrint('Paket bilgisi:');
            debugPrint('- ID: ${package.identifier}');
            debugPrint('- Ürün ID: ${package.storeProduct.identifier}');
            debugPrint('- Fiyat: ${package.storeProduct.priceString}');
            debugPrint('- Açıklama: ${package.storeProduct.description}');
          }

          setState(() {
            _package = offerings.current!.availablePackages.first;
          });
        } else {
          debugPrint('Mevcut offering\'de paket bulunamadı');
          debugPrint('Lütfen App Store Connect\'te ürün yapılandırmasını kontrol edin');
          debugPrint('Ürün ID\'si: bil_bakalim_pro');
        }
      } else {
        debugPrint('Hiç offering bulunamadı');
        debugPrint('RevenueCat Dashboard\'da offering yapılandırmasını kontrol edin');
      }
    } catch (e) {
      debugPrint('Paketler yüklenirken hata: $e');
      if (e is PlatformException) {
        debugPrint('Hata kodu: ${e.code}');
        debugPrint('Hata mesajı: ${e.message}');
        debugPrint('Hata detayları: ${e.details}');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _purchasePremium() async {
    if (_package == null) {
      debugPrint('Paket bulunamadı');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Satın alma başlatılıyor: ${_package!.storeProduct.identifier}');
      
      // Satın alma işlemini başlat
      final purchaseResult = await Purchases.purchaseProduct(
        _package!.storeProduct.identifier,
        type: PurchaseType.inapp
      );
      
      debugPrint('Satın alma sonucu: ${purchaseResult.entitlements.active}');
      
      // Kullanıcı premium oldu mu kontrol et
      if (purchaseResult.entitlements.active.containsKey('bil_bakalim_pro')) {
        // Firestore'da kullanıcının premium durumunu güncelle
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
                'isPremium': true,
                'premiumEndDate': DateTime(2025, 12, 31).toIso8601String(),
                'purchaseDate': FieldValue.serverTimestamp(),
              });

          // Başarılı dialog göster
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Premium Üyelik Aktif!'),
                content: const Text('Premium üyeliğiniz başarıyla aktifleştirildi. Tüm özelliklere erişebilirsiniz.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Dialog'u kapat
                      Navigator.pop(context); // Premium sayfasını kapat
                    },
                    child: const Text('Tamam'),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Satın alma hatası: $e');
      // Hata durumunda kullanıcıya bilgi ver
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Geliştirme Aşamasında'),
            content: const Text('Uygulama şu anda geliştirme aşamasındadır. Satın alma özelliği yakında aktif olacaktır. App Store onay sürecinin tamamlanmasını bekliyoruz.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF2A2E7B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Ana içerik
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/dersResimleri/background.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 200), // Premium buton ve SafeArea için yeterli boşluk
              child: Column(
                children: [
                  // Premium başlık
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.95),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.workspace_premium_rounded,
                            size: 32,
                            color: Colors.amber[400],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '🎯 Premium Üyelik Avantajları',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '🔓 Kilidi Aç, Sınırları Kaldır!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Premium üyelikle birlikte uygulamanın tüm ayrıcalıklı içeriklerine anında erişim sağla!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Özellikler başlığı
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          '✨ Sunduğumuz Ayrıcalıklar:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Özellikler listesi
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildFeatureItem(
                          icon: Icons.library_books_rounded,
                          title: '📚 13.000+ Soruya Kolay Erişim',
                          description: 'Tüm konu başlıklarında detaylı soru havuzuna sınırsız erişim',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureItem(
                          icon: Icons.auto_awesome,
                          title: '🧠 Akıl Kartlarıyla Hızlı Öğrenme',
                          description: 'Konuları pekiştiren, görsel destekli ve eğlenceli öğrenme kartları',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureItem(
                          icon: Icons.sports_esports_rounded,
                          title: '🎮 Oyunlarla Öğren',
                          description: 'Bilgini pekiştirirken keyif alacağın zeka ve bilgi oyunları',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureItem(
                          icon: Icons.assignment_rounded,
                          title: '📝 Deneme Sınavlarına Katılım',
                          description: 'Gerçek sınav formatında hazırlanmış özel denemeler',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureItem(
                          icon: Icons.leaderboard_rounded,
                          title: '🏆 Liderlik Tablosunu Görüntüle',
                          description: 'Başarı sıralamanı takip et, zirveye oyna',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureItem(
                          icon: Icons.notifications_active_rounded,
                          title: '🔔 Güncel Bilgi Testleri',
                          description: 'Sınav yaklaştığında yayınlanacak özel güncel testlere katıl',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Son kullanma tarihi notu
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.amber[400]!.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber[400]!.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Colors.amber[700],
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '📅 Kullanım Süresi: Premium ayrıcalıklar 31.12.2025 tarihine kadar seninle!',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.amber[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sabit Premium Butonu
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Premium Üyelik',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2A2E7B),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _isLoading
                                ? const SizedBox(
                                    height: 14,
                                    width: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    '₺249.99',  // Geçici olarak sabit fiyat
                                    style: TextStyle(
                                      color: Color(0xFF2A2E7B),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _purchasePremium,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Premium\'a Yükselt',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2A2E7B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF2A2E7B).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Yıldızlı arkaplan efekti için CustomPainter
class StarFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final random = DateTime.now().millisecondsSinceEpoch;
    
    for (var i = 0; i < 100; i++) {
      final x = (random + i * 7) % size.width;
      final y = (random + i * 11) % size.height;
      final radius = ((random + i * 13) % 3) / 2;
      
      canvas.drawCircle(Offset(x, y), radius, paint..color = Colors.white.withOpacity(0.1 + (i % 9) / 10));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
} 