import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bilbakalim/styles/app_theme.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class RegisterContent extends StatefulWidget {
  final VoidCallback onRegisterPressed;
  const RegisterContent({super.key, required this.onRegisterPressed});

  @override
  State<RegisterContent> createState() => _RegisterContentState();
}

class _RegisterContentState extends State<RegisterContent> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _characterNameController = TextEditingController();
  
  late TabController _tabController;
  String _selectedCharacter = 'assets/animals/kedi.png';
  String _selectedExpertise = 'Servis Asistanı';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isNavigating = false;

  final Map<String, String> _characterNames = {
    'assets/animals/kedi.png': 'Kedi',
    'assets/animals/kartal.png': 'Kartal',
    'assets/animals/aslan.png': 'Aslan',
    'assets/animals/peri.png': 'Peri',
    'assets/animals/kurt.png': 'Kurt',
    'assets/animals/baykus.png': 'Baykuş',
    'assets/animals/panda.png': 'Panda',
  };

  final List<String> _expertiseAreas = [
    'Servis Asistanı',
    'Servis Görevlisi',
    'Servis Yetkilisi',
    'Yönetmen Yardımcısı',
    'Yönetmen',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _characterNameController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return {
        'device_id': iosInfo.identifierForVendor ?? 'unknown',
        'device_type': 'iOS',
        'model': iosInfo.model,
      };
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return {
        'device_id': androidInfo.id,
        'device_type': 'Android',
        'model': androidInfo.model,
      };
    }
    return {
      'device_id': 'unknown',
      'device_type': 'unknown',
      'model': 'unknown',
    };
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      if (_isNavigating || _isLoading) return;
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        final deviceInfo = await _getDeviceInfo();
        
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'name': _nameController.text,
          'surname': _surnameController.text,
          'email': _emailController.text.trim(),
          'expertise': _selectedExpertise,
          'character': {
            'image': _selectedCharacter,
            'systemName': _characterNames[_selectedCharacter],
            'customName': _characterNameController.text,
          },
          'device_id': deviceInfo['device_id'],
          'device_type': deviceInfo['device_type'],
          'device_model': deviceInfo['model'],
          'score': 0,
          'level': 1,
          'isPremium': false,
          'premiumStartDate': null,
          'createdAt': FieldValue.serverTimestamp(),
          'averageQuestionTime': 0,
          'bestTime': 0,
          'wrongAnswers': 0,
          'correctAnswers': 0,
          'totalQuestions': 0,
          'badges': [],
          'assignedExams': [],
          'examResults': [],
        });

        await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .collection('examResults')
          .doc('initial')
          .set({
            'createdAt': FieldValue.serverTimestamp(),
          });

        if (!mounted) return;
        
        setState(() {
          _isNavigating = true;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Kayıt Başarılı! "),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (!mounted) return;
        
        setState(() {
          _isLoading = false;
          _isNavigating = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted && !_isNavigating) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Widget _buildCharacterCard(String imagePath, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCharacter = imagePath;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFEBFF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                ? AppTheme.primaryColor.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          bool isActive = _tabController.index >= index;
          bool isCurrent = _tabController.index == index;
          return Row(
            children: [
              Container(
                width: isCurrent ? 40 : 36,
                height: isCurrent ? 40 : 36,
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primaryColor : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive ? Colors.transparent : AppTheme.primaryColor,
                    width: 2,
                  ),
                  boxShadow: isCurrent ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ] : null,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.poppins(
                      color: isActive ? Colors.white : AppTheme.primaryColor,
                      fontSize: isCurrent ? 18 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (index < 2)
                Container(
                  width: 32,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: isActive ? AppTheme.primaryColor : Colors.grey.shade300,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
    bool isConfirmPassword = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? (isConfirmPassword ? _obscureConfirmPassword : _obscurePassword) : false,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 22),
          suffixIcon: isPassword ? IconButton(
            icon: Icon(
              isConfirmPassword
                  ? (_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined)
                  : (_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              color: AppTheme.primaryColor,
              size: 22,
            ),
            onPressed: () {
              setState(() {
                if (isConfirmPassword) {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                } else {
                  _obscurePassword = !_obscurePassword;
                }
              });
            },
          ) : null,
          filled: true,
          fillColor: const Color(0xFFEFEBFF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          labelStyle: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildExpertiseDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEFEBFF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedExpertise,
            decoration: InputDecoration(
              labelText: 'Uzmanlık Alanı',
              prefixIcon: const Icon(Icons.work_outline, color: AppTheme.primaryColor, size: 22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              labelStyle: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            items: _expertiseAreas.map((String expertise) {
              return DropdownMenuItem<String>(
                value: expertise,
                child: Text(expertise),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedExpertise = newValue;
                });
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen bir uzmanlık alanı seçin';
              }
              return null;
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 16),
          child: Text(
            'Hangi Unvanda Yükselme Sınavına hazırlanıyorsunuz?',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildProgressIndicator(),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Kişisel Bilgiler
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kişisel Bilgiler',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hesabınızı oluşturmak için bilgilerinizi girin',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildInputField(
                        controller: _nameController,
                        label: 'Ad',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen adınızı girin';
                          }
                          return null;
                        },
                      ),
                      _buildInputField(
                        controller: _surnameController,
                        label: 'Soyad',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen soyadınızı girin';
                          }
                          return null;
                        },
                      ),
                      _buildExpertiseDropdown(),
                    ],
                  ),
                ),
                // Hesap Bilgileri
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hesap Bilgileri',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Giriş bilgilerinizi oluşturun',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildInputField(
                        controller: _emailController,
                        label: 'E-posta',
                        icon: Icons.email_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen e-posta adresinizi girin';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Geçerli bir e-posta adresi girin';
                          }
                          return null;
                        },
                      ),
                      _buildInputField(
                        controller: _passwordController,
                        label: 'Şifre',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen şifrenizi girin';
                          }
                          if (value.length < 6) {
                            return 'Şifre en az 6 karakter olmalıdır';
                          }
                          return null;
                        },
                      ),
                      _buildInputField(
                        controller: _confirmPasswordController,
                        label: 'Şifre Tekrar',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        isConfirmPassword: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen şifrenizi tekrar girin';
                          }
                          if (value != _passwordController.text) {
                            return 'Şifreler eşleşmiyor';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                // Karakter Seçimi
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Karakter Seçimi',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Size eşlik edecek karakteri seçin',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 3,
                          childAspectRatio: 1,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          children: _characterNames.keys.map((imagePath) {
                            return _buildCharacterCard(imagePath, imagePath == _selectedCharacter);
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: _characterNameController,
                        label: 'Karakterinize İsim Verin',
                        icon: Icons.edit,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen karakterinize bir isim verin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (_tabController.index > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _tabController.animateTo(_tabController.index - 1);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppTheme.primaryColor, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Geri',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                if (_tabController.index > 0)
                  const SizedBox(width: 16),
                Expanded(
                  flex: _tabController.index == 0 ? 1 : 2,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (_tabController.index < 2) {
                              _tabController.animateTo(_tabController.index + 1);
                            } else {
                              _register();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _tabController.index == 2 ? 'Kayıt Ol' : 'Devam Et',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
