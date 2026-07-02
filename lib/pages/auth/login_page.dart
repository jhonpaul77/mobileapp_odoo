import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/secure_storage_service.dart';
import '../../config/theme.dart';
import 'setup_pin_page.dart';
import '../home/home_page.dart';
import 'intro_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _storage = SecureStorageService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _appVersion = '';
  
  // Animations untuk 4 circles (sesuai 4 brand colors)
  late AnimationController _circle1Controller; // Orange
  late AnimationController _circle2Controller; // Red
  late AnimationController _circle3Controller; // Green
  late AnimationController _circle4Controller; // Blue

  @override
  void initState() {
    super.initState();
    _getAppVersion();
    _setupAnimations();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _circle1Controller.dispose();
    _circle2Controller.dispose();
    _circle3Controller.dispose();
    _circle4Controller.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _circle1Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _circle2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _circle3Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    _circle4Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  Future<void> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'V ${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  Future<void> _handleBack() async {
    await _storage.setHasSeenIntro(false);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const IntroPage()),
    );
  }

  Future<void> _handleHelp() async {
    final whatsappUrl = Uri.parse(
      'https://wa.me/6285183355230?text=${Uri.encodeComponent('Halo Pintar, saya butuh bantuan')}',
    );
    
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka WhatsApp')),
      );
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _authService.signIn(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (response.success) {
        final isFirstLogin = await _storage.isFirstLogin();
        
        if (isFirstLogin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SetupPinPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        _showErrorSnackBar(response.message);
      }
    } catch (e) {
      _showErrorSnackBar('Terjadi kesalahan: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDemoLogin() async {
    setState(() => _isLoading = true);

    try {
      await _storage.saveTokens('demo_access_token', 'demo_refresh_token');
      await _storage.saveUserData({
        'uuid': 'demo-user',
        'username': 'demo',
        'organization': 'Demo Organization',
        'roles': ['demo'],
      });
      ApiService().setAuthToken('demo_access_token');

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      _showErrorSnackBar('Demo login gagal: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Lupa Password?'),
        content: const Text(
          'Silakan hubungi administrator untuk reset password Anda.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ ANIMATED BACKGROUND dengan 4 brand colors
          _buildAnimatedBackground(),
          
          // ✅ CONTENT
          SafeArea(
            child: Column(
              children: [
                // ✅ TOP BAR
                _buildTopBar(),
                
                // ✅ MAIN CONTENT
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          
                          // ✅ WELCOME TEXT dengan logo
                          _buildWelcomeText(),
                          
                          const SizedBox(height: 40),
                          
                          // ✅ FORM FIELDS
                          _buildFormFields(),
                          
                          const SizedBox(height: 12),
                          
                          // ✅ FORGOT PASSWORD
                          _buildForgotPassword(),
                          
                          const SizedBox(height: 24),
                          
                          // ✅ LOGIN BUTTON
                          _buildLoginButton(),
                          const SizedBox(height: 16),
                          _buildDemoButton(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        // Background color
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.surfaceColor,
                AppTheme.primaryColor.withOpacity(0.02),
              ],
            ),
          ),
        ),
        
        // ✅ Circle 1 - Orange (Top Right - Large)
        AnimatedBuilder(
          animation: _circle1Controller,
          builder: (context, child) {
            return Positioned(
              right: -80 + (30 * _circle1Controller.value),
              top: 80 - (20 * _circle1Controller.value),
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.brandOrange.withOpacity(0.15),
                ),
              ),
            );
          },
        ),
        
        // ✅ Circle 2 - Red (Bottom Left - Medium)
        AnimatedBuilder(
          animation: _circle2Controller,
          builder: (context, child) {
            return Positioned(
              left: -60 + (40 * _circle2Controller.value),
              bottom: 200 - (30 * _circle2Controller.value),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.brandRed.withOpacity(0.12),
                ),
              ),
            );
          },
        ),
        
        // ✅ Circle 3 - Green (Bottom Right - Small)
        AnimatedBuilder(
          animation: _circle3Controller,
          builder: (context, child) {
            return Positioned(
              right: 20 - (25 * _circle3Controller.value),
              bottom: -40 + (15 * _circle3Controller.value),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.brandGreen.withOpacity(0.12),
                ),
              ),
            );
          },
        ),
        
        // ✅ Circle 4 - Blue (Center - Extra Small, logo symbol)
        AnimatedBuilder(
          animation: _circle4Controller,
          builder: (context, child) {
            return Positioned(
              left: 40 + (20 * _circle4Controller.value),
              top: MediaQuery.of(context).size.height * 0.35 - (15 * _circle4Controller.value),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.brandBlue.withOpacity(0.1),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ✅ BACK BUTTON (Kiri)
          IconButton(
            onPressed: _handleBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
            ),
          ),
          
          // ✅ HELP BUTTON (Kanan)
          IconButton(
            onPressed: _handleHelp,
            icon: const Icon(Icons.help_outline_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.brandGreen,
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ VERSION di atas "Halo"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.brandBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _appVersion.isEmpty ? 'V ...' : _appVersion,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.brandBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        // const SizedBox(height: 16),
        
        // ✅ "Halo"
        Text(
          'Selamat Datang!',
          style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                height: 1.2,
              ),
        ),
        
        // const SizedBox(height: 1),
        
        // ✅ Logo + App Name (sama besar dengan "Halo")
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             // Logo dengan ukuran sama tingginya dengan text
//             Container(
//   width: 200,
//   height: 50,
//   // decoration: BoxDecoration(
//   //   color: Colors.white,
//   //   borderRadius: BorderRadius.circular(10),
//   //   boxShadow: [
//   //     BoxShadow(
//   //       color: AppTheme.brandBlue.withOpacity(0.2),
//   //       blurRadius: 8,
//   //       offset: const Offset(0, 2),
//   //     ),
//   //   ],
//   // ),
  
//   child: ClipRRect(
//     // borderRadius: BorderRadius.circular(1),
//     child: Padding(
//       padding: const EdgeInsets.all(1),
//       child: Image.asset(
//         'assets/images/logologinpage.png',
//         fit: BoxFit.contain,
//       ),
//     ),
//   ),
// ),

//           ],
//         ),      
        const SizedBox(height: 1),
        
        // ✅ Description
        const Text(
          'Anyone can be productive. Work better\nwith your team and friends.\nNow, Tomorrow, Together.',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Username
          TextFormField(
            controller: _usernameController,
            enabled: !_isLoading,
            decoration: InputDecoration(
              hintText: 'Email or phone number',
              prefixIcon: const Icon(
                Icons.person_outline_rounded,
                color: AppTheme.textHint,
              ),
              filled: true,
              fillColor: AppTheme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Username tidak boleh kosong';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          
          const SizedBox(height: 16),
          
          // Password
          TextFormField(
            controller: _passwordController,
            enabled: !_isLoading,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Password',
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: AppTheme.textHint,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.textHint,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              filled: true,
              fillColor: AppTheme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password tidak boleh kosong';
              }
              return null;
            },
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _handleForgotPassword,
        child: const Text(
          'Lupa Password?',
          style: TextStyle(
            color: AppTheme.brandBlue,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.brandBlue, AppTheme.primaryLight],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandBlue.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Login',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildDemoButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: TextButton(
        onPressed: _isLoading ? null : _handleDemoLogin,
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.brandBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.brandBlue, width: 1.5),
          ),
        ),
        child: const Text(
          'Masuk Demo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}