import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:bilbakalim/services/firebase_auth_services.dart';
import 'package:google_fonts/google_fonts.dart';

class DigerPage extends StatelessWidget {
  DigerPage({super.key});
  final FirebaseAuthService _auth = FirebaseAuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              const Color(0xFFF3F0FF),
              const Color(0xFFE8E3FF),
              const Color(0xFFDDD6FF),
            ],
            stops: const [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern AppBar
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B4EFF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xFF6B4EFF),
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Diğer',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
              ),

              // Ana İçerik
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hesap Bölümü
                      Text(
                        'Hesap',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              const Color(0xFFF0ECFF),
                              const Color(0xFFE9E3FF),
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6B4EFF).withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFFD4CBFF),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildMenuItem(
                              icon: Icons.stars_rounded,
                              iconColor: const Color(0xFFFFAB40),
                              title: 'Kaydettiklerim',
                              onTap: () {},
                            ),
                            _buildDivider(),
                            _buildMenuItem(
                              icon: Icons.person_rounded,
                              iconColor: const Color(0xFF6B4EFF),
                              title: 'Profil',
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Uygulama Bölümü
                      Text(
                        'Uygulama',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              const Color(0xFFF0ECFF),
                              const Color(0xFFE9E3FF),
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6B4EFF).withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFFD4CBFF),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildMenuItem(
                              icon: Icons.favorite_rounded,
                              iconColor: const Color(0xFFFF5252),
                              title: "Bil Bakalım'ı Tavsiye Et",
                              onTap: () {},
                            ),
                            _buildDivider(),
                            _buildMenuItem(
                              icon: Icons.info_rounded,
                              iconColor: const Color(0xFF4CAF50),
                              title: 'Hakkımızda',
                              onTap: () {},
                            ),
                            _buildDivider(),
                            _buildMenuItem(
                              icon: Icons.privacy_tip_rounded,
                              iconColor: const Color(0xFF9C27B0),
                              title: 'Gizlilik Politikası',
                              onTap: () {
                                _showPrivacyPolicy(context);
                              },
                            ),
                            _buildDivider(),
                            _buildMenuItem(
                              icon: Icons.description_rounded,
                              iconColor: const Color(0xFF3F51B5),
                              title: 'Şartlar ve Koşullar',
                              onTap: () {
                                _showTermsAndConditions(context);
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Çıkış Yap Butonu
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              const Color(0xFFF0ECFF),
                              const Color(0xFFE9E3FF),
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6B4EFF).withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFFD4CBFF),
                            width: 1,
                          ),
                        ),
                        child: _buildMenuItem(
                          icon: Icons.exit_to_app_rounded,
                          iconColor: const Color(0xFFE53935),
                          title: 'Çıkış Yap',
                          onTap: () {
                            _auth.signOut();
                            context.replaceNamed('login');
                          },
                          showBorder: false,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Visa Logo
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          Divider(
                            color: const Color(0xFFD4CBFF),
                            thickness: 0.5,
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Container(
                              height: 40,
                              child: Image.asset(
                                'assets/images/visa_logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    bool showBorder = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: iconColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF1A1A2E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: const Color(0xFF6B4EFF),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        color: const Color(0xFFD4CBFF),
        height: 1,
        thickness: 0.5,
      ),
    );
  }
  
  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B4EFF).withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4CBFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9C27B0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.privacy_tip_rounded,
                      color: const Color(0xFF9C27B0),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Gizlilik Politikası',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    _buildPolicySection('Veri Toplama', 'Bil Bakalım uygulaması, kullanıcı deneyimini geliştirmek için bazı kişisel bilgileri toplar. Bu bilgiler arasında adınız, e-posta adresiniz ve kullanım istatistikleri bulunur.'),
                    
                    _buildPolicySection('Veri Kullanımı', 'Topladığımız verileri hizmetlerimizi geliştirmek, kullanıcı deneyimini kişiselleştirmek ve içerik önerilerimizi iyileştirmek için kullanırız.'),
                    
                    _buildPolicySection('Veri Güvenliği', 'Kullanıcı verilerinin güvenliği bizim için önemlidir. Verilerinizi korumak için endüstri standardı güvenlik önlemleri uyguluyoruz.'),
                    
                    _buildPolicySection('Çerezler', 'Kullanıcı deneyimini geliştirmek için çerezleri kullanırız. Bu çerezler tarayıcınız tarafından cihazınıza yerleştirilir ve kullanım alışkanlıklarınız hakkında bilgi toplar.'),
                    
                    _buildPolicySection('Üçüncü Taraf Hizmetleri', 'Uygulamamız içinde Google Analytics ve Firebase gibi üçüncü taraf hizmetlerini kullanabiliriz. Bu hizmetler kendi gizlilik politikalarına sahiptir.'),
                    
                    _buildPolicySection('Veri Paylaşımı', 'Kişisel verilerinizi yasal yükümlülüklerimiz gerektirdiğinde veya açık izniniz olduğunda üçüncü taraflarla paylaşabiliriz.'),
                    
                    _buildPolicySection('Kullanıcı Hakları', 'Kişisel verilerinize erişme, düzeltme, silme veya işlenmesini kısıtlama hakkına sahipsiniz. Bu hakları kullanmak için bizimle iletişime geçebilirsiniz.'),
                    
                    _buildPolicySection('Politika Değişiklikleri', 'Gizlilik politikamızı zaman zaman güncelleyebiliriz. Değişiklikler uygulama içinde duyurulacak ve yeni politika yayınlandığı tarihten itibaren geçerli olacaktır.'),
                    
                    _buildPolicySection('İletişim', 'Gizlilik politikamızla ilgili sorularınız için bilbakalim@destek.com adresinden bize ulaşabilirsiniz.'),
                    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showTermsAndConditions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B4EFF).withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4CBFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3F51B5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.description_rounded,
                      color: const Color(0xFF3F51B5),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Şartlar ve Koşullar',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    _buildPolicySection('Kullanım Şartları', 'Bu uygulamayı kullanarak, bu Şartlar ve Koşulları kabul etmiş olursunuz. Eğer bu Şartlar ve Koşulları kabul etmiyorsanız, lütfen uygulamayı kullanmayınız.'),
                    
                    _buildPolicySection('Hesap Oluşturma', 'Hizmetlerimizin bazı özelliklerini kullanabilmek için hesap oluşturmanız gerekebilir. Hesap bilgilerinizin gizliliğinden siz sorumlusunuz ve hesabınızla gerçekleştirilen her türlü etkinlikten sorumlu olursunuz.'),
                    
                    _buildPolicySection('Kullanıcı Davranışları', 'Uygulamayı kullanırken yasalara uygun davranmayı, başkalarının haklarına saygı göstermeyi ve hizmetlerimizi kötüye kullanmamayı kabul edersiniz.'),
                    
                    _buildPolicySection('Fikri Mülkiyet', 'Uygulama ve içeriği (logolar, tasarımlar, metinler, grafikler vb.) telif hakkı, ticari marka ve diğer fikri mülkiyet hakları ile korunmaktadır. Bu içeriklerin izinsiz kullanımı, kopyalanması veya dağıtılması yasaktır.'),
                    
                    _buildPolicySection('Abonelikler ve Ödeme', 'Premium özelliklere erişim için abonelik satın alabilirsiniz. Ödemeler, seçilen ödeme yöntemi üzerinden tahsil edilir ve abonelikler otomatik olarak yenilenir. Aboneliğinizi istediğiniz zaman hesap ayarlarınızdan iptal edebilirsiniz.'),
                    
                    _buildPolicySection('Sorumluluk Reddi', 'Uygulama "olduğu gibi" sunulmaktadır. Uygulamanın kesintisiz veya hatasız çalışacağını garanti etmiyoruz. Uygulamayı kullanımınızdan doğan riskler size aittir.'),
                    
                    _buildPolicySection('Hizmet Değişiklikleri', 'Bil Bakalım, hizmetleri üzerinde herhangi bir zamanda değişiklik yapma, özellikler ekleme veya kaldırma hakkını saklı tutar. Ayrıca, hizmetlerimizi geçici veya kalıcı olarak durdurma hakkına sahibiz.'),
                    
                    _buildPolicySection('Sınırlı Sorumluluk', 'Bil Bakalım ve bağlı şirketleri, uygulamayı kullanımınızdan kaynaklanan doğrudan, dolaylı, arızi, özel veya cezai zararlardan sorumlu tutulamaz.'),
                    
                    _buildPolicySection('Uygulanacak Hukuk', 'Bu Şartlar ve Koşullar, Türkiye Cumhuriyeti yasalarına tabidir ve bu yasalara göre yorumlanacaktır.'),
                    
                    _buildPolicySection('Değişiklikler', 'Bil Bakalım, bu Şartlar ve Koşulları herhangi bir zamanda değiştirme hakkını saklı tutar. Değişiklikler, yeni şartların uygulama içinde yayınlanmasının ardından geçerli olacaktır.'),
                    
                    _buildPolicySection('İletişim', 'Bu Şartlar ve Koşullarla ilgili sorularınız için bilbakalim@destek.com adresinden bize ulaşabilirsiniz.'),
                    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicySection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B4EFF),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF1A1A2E).withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
