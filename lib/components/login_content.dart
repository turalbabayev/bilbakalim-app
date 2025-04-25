import 'package:bilbakalim/styles/button_styles.dart';
import 'package:flutter/material.dart';
import '../services/firebase_auth_services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bilbakalim/styles/app_theme.dart';

class LoginContent extends StatefulWidget {
  final VoidCallback onLoginPressed;
  const LoginContent({super.key, required this.onLoginPressed});

  @override
  State<LoginContent> createState() => _LoginContentState();
}

class _LoginContentState extends State<LoginContent> {
  final _formKey = GlobalKey<FormState>();
  final _authService = FirebaseAuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isNavigating = false;

  void _login() async {
    if (_formKey.currentState!.validate()) {
      // Eğer zaten bir navigasyon işlemi yapılıyorsa yeni işlem başlatma
      if (_isNavigating || _isLoading) return;
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        await _authService.loginWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Giriş Başarılı!"),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigasyon başlıyor
        setState(() {
          _isNavigating = true;
        });
        
        // Widget.onLoginPressed fonksiyonunu kullan (daha güvenli)
        widget.onLoginPressed();
      } catch (e) {
        if (!mounted) return;
        
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth > 500 ? 450 : screenWidth * 0.9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Tekrar Hoşgeldiniz",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Bilgilerinizle giriş yapın",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              // Email field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.poppins(fontSize: 16),
                decoration: InputDecoration(
                  labelText: "E-Posta",
                  hintText: "email@example.com",
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey.withOpacity(0.5),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryColor, size: 22),
                  labelStyle: GoogleFonts.poppins(
                    color: AppTheme.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
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
                    borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFEFEBFF),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Lütfen e-posta adresinizi girin!";
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return "Geçerli bir e-posta adresi girin!";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Password field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: GoogleFonts.poppins(fontSize: 16),
                decoration: InputDecoration(
                  labelText: "Şifre",
                  prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryColor, size: 22),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppTheme.primaryColor,
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  labelStyle: GoogleFonts.poppins(
                    color: AppTheme.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
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
                    borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFEFEBFF),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Lütfen şifrenizi girin!";
                  }
                  if (value.length < 6) {
                    return "Şifre en az 6 karakter olmalıdır!";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              // Forgot password button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Şifre sıfırlama işlemi
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    "Şifremi Unuttum",
                    style: GoogleFonts.poppins(
                      color: AppTheme.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Login button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_isLoading || _isNavigating) ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
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
                          "Giriş Yap",
                          style: GoogleFonts.poppins(
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
    );
  }
}
