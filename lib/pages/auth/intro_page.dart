import 'package:flutter/material.dart';
import '../../services/secure_storage_service.dart';
import '../../config/theme.dart';
import 'login_page.dart';
import 'lock_screen_page.dart';
import '../../services/status_bar_service.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage>
    with SingleTickerProviderStateMixin {
  final _storage = SecureStorageService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  bool _showIntro = true;

  @override
  void initState() {
    super.initState();

    // ✅ Set status bar untuk halaman intro (background putih → icon gelap)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StatusBarService.setLightStatusBar();
    });
    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();

    // ✅ Langsung cek auth tanpa delay
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    // ✅ Tanpa delay! Langsung cek

    // ✅ PRIORITY 1: Cek auth dulu (Returning user)
    final isPinSet = await _storage.isPinSet();
    final accessToken = await _storage.getAccessToken();

    if (!mounted) return;

    // Sudah login → Lock Screen (skip intro, langsung!)
    if (isPinSet && accessToken != null) {
      print('✅ [INTRO] User sudah login → Lock Screen');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LockScreenPage()),
      );
      return;
    }

    // ✅ PRIORITY 2: Cek intro (First time atau after logout)
    final hasSeenIntro = await _storage.getHasSeenIntro();

    if (!hasSeenIntro) {
      // First time → Show intro
      print('✅ [INTRO] First time → Show intro');
      setState(() => _showIntro = true);
      return;
    }

    // ✅ PRIORITY 3: Sudah lihat intro, belum login → Login
    print('✅ [INTRO] Skip intro → Login Page');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _onStartPressed() async {
    await _storage.setHasSeenIntro(true);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_showIntro) {
      return _buildSplashScreen();
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              AppTheme.primaryColor.withValues(alpha: 0.03),
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.paddingLarge,
                    vertical: AppTheme.paddingXLarge,
                  ),
                  child: Column(
                    children: [
                      const Spacer(flex: 1),

                      // ✅ LOGO SECTION (Animated)
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: _buildLogo(),
                      ),

                      const SizedBox(height: AppTheme.paddingXLarge),

                      // ✅ TITLE SECTION (Animated)
                      SlideTransition(
                        position: _slideAnimation,
                        child: _buildTitle(),
                      ),

                      const SizedBox(height: AppTheme.paddingMedium),

                      // ✅ DESCRIPTION (Animated)
                      SlideTransition(
                        position: _slideAnimation,
                        child: _buildDescription(),
                      ),

                      const SizedBox(height: AppTheme.paddingXLarge + 8),

                      // ✅ FEATURES (Animated)
                      SlideTransition(
                        position: _slideAnimation,
                        child: _buildFeatures(),
                      ),

                      const Spacer(flex: 2),

                      // ✅ BUTTON (Animated)
                      SlideTransition(
                        position: _slideAnimation,
                        child: _buildStartButton(),
                      ),

                      const SizedBox(height: AppTheme.paddingMedium),

                      // ✅ FOOTER
                      _buildFooter(),

                      const SizedBox(height: AppTheme.paddingSmall),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSplashScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            // colors: [AppTheme.primaryLight, AppTheme.primaryColor],
            colors: [AppTheme.kotakblue, AppTheme.kotakblue2],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Image.asset(
                      'assets/images/logointro2.png', // ✅ Ganti dengan logo
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.paddingLarge),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          //colors: [AppTheme.cardColor,AppTheme.cardColor,],
          colors: [AppTheme.kotakblue, AppTheme.kotakblue2],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(12), // Padding agar logo tidak mepet
          child: Image.asset(
            'assets/images/logointro2.png', // ✅ Path ke logo Anda
            fit: BoxFit.contain,
            // Jika logo Anda putih, tidak perlu color
            // Jika mau override warna:
            // color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'Next PSA',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                height: 1.2,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Made By nextnusantara.com',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        'Solusi pintar untuk pencatatan,\ntransaksi, dan laporan usahamu\nsecara real-time.',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.6,
              fontSize: 15,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFeatures() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _featureItem(
            Icons.speed_rounded,
            'Cepat & Efisien',
            'Proses transaksi lebih cepat',
          ),
          const SizedBox(height: AppTheme.paddingMedium + 4),
          _featureItem(
            Icons.security_rounded,
            'Aman & Terpercaya',
            'Data terenkripsi dengan aman',
          ),
          const SizedBox(height: AppTheme.paddingMedium + 4),
          _featureItem(
            Icons.analytics_rounded,
            'Laporan Real-time',
            'Pantau bisnis kapan saja',
          ),
        ],
      ),
    );
  }

  Widget _featureItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryLight.withValues(alpha: 0.15),
                AppTheme.primaryColor.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 22,
          ),
        ),
        const SizedBox(width: AppTheme.paddingMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primaryColor],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _onStartPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Mulai Sekarang',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Text(
      '© 2025 App Pintar • All Rights Reserved',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.textHint,
            fontSize: 11,
          ),
      textAlign: TextAlign.center,
    );
  }
}
