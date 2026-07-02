import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/secure_storage_service.dart';
import '../../services/biometric_service.dart';
import '../../services/auth_service.dart';
import '../home/home_page.dart';
import 'login_page.dart';

class LockScreenPage extends StatefulWidget {
  const LockScreenPage({super.key});

  @override
  State<LockScreenPage> createState() => _LockScreenPageState();
}

class _LockScreenPageState extends State<LockScreenPage> with TickerProviderStateMixin {
  final _storage = SecureStorageService();
  final _biometric = BiometricService();
  final _authService = AuthService();

  String _pinInput = '';
  String _correctPin = '';
  bool _isNavigating = false;
  bool _isPinError = false;
  bool _isLoading = true;
  bool _isBiometricEnabled = false;
  int _failedAttempts = 0;
  static const int _maxAttempts = 3;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    );
    
    Future.delayed(const Duration(milliseconds: 300), _checkSessionAndAuth);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _checkSessionAndAuth() async {
    // Check if PIN exists
    final pin = await _storage.getPin();

    if (pin == null || pin.isEmpty) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    // Check session validity
    final hasToken = await _authService.isLoggedIn();
    
    if (!hasToken) {
      if (!mounted) return;
      _forceLogout();
      return;
    }

    // Store correct PIN for verification
    setState(() {
      _correctPin = pin;
      _isLoading = false;
    });

    // Check biometric availability
    _isBiometricEnabled = await _biometric.isBiometricEnabled();
    
    // Start animations
    _fadeController.forward();
    _scaleController.forward();
    
    // Try biometric auth first if enabled
    if (_isBiometricEnabled && mounted) {
      Future.delayed(const Duration(milliseconds: 500), _tryBiometricAuth);
    }
  }

  Future<void> _tryBiometricAuth() async {
    if (_isNavigating) return;

    try {
      final success = await _biometric.authenticate();
      if (success && mounted && !_isNavigating) {
        _goToHome();
      }
    } catch (e) {
      debugPrint('Biometric failed: $e');
    }
  }

  void _onPinInput(String number) {
    if (_pinInput.length >= 6) return;
    
    HapticFeedback.lightImpact();
    
    setState(() {
      _pinInput += number;
      _isPinError = false;
    });

    if (_pinInput.length == 6) {
      Future.delayed(const Duration(milliseconds: 200), _verifyPin);
    }
  }

  void _onPinDelete() {
    if (_pinInput.isEmpty) return;
    
    HapticFeedback.lightImpact();
    
    setState(() {
      _pinInput = _pinInput.substring(0, _pinInput.length - 1);
      _isPinError = false;
    });
  }

  Future<void> _verifyPin() async {
    final isValid = await _storage.verifyPin(_pinInput);
    
    if (isValid) {
      // Success animation
      _scaleController.reverse().then((_) {
        if (mounted) _goToHome();
      });
    } else {
      // Error handling
      setState(() {
        _isPinError = true;
        _failedAttempts++;
        _pinInput = '';
      });
      
      HapticFeedback.heavyImpact();
      _shakeController.forward().then((_) {
        _shakeController.reset();
      });
      
      if (_failedAttempts >= _maxAttempts) {
        _handleMaxRetries();
      } else {
        _showErrorSnackBar();
      }
    }
  }

  void _showErrorSnackBar() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PIN salah! Sisa percobaan: ${_maxAttempts - _failedAttempts}'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleMaxRetries() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Percobaan Habis'),
          ],
        ),
        content: const Text(
          'Anda telah salah memasukkan PIN sebanyak 3 kali. Silakan login ulang.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _forceLogout();
    }
  }

  Future<void> _handleLogout() async {
    if (_isNavigating) return;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Logout'),
          ],
        ),
        content: const Text(
          'Anda yakin ingin keluar dari aplikasi?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _forceLogout();
    }
  }

  Future<void> _forceLogout() async {
    setState(() => _isNavigating = true);
    await _authService.signOut();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _goToHome() {
    if (_isNavigating || !mounted) return;
    setState(() => _isNavigating = true);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;
    
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      primaryColor.withOpacity(0.3),
                      primaryColor.withOpacity(0.1),
                    ]
                  : [
                      primaryColor.withOpacity(0.9),
                      primaryColor,
                    ],
            ),
          ),
          child: SafeArea(
            child: _isLoading
                ? _buildLoadingScreen(theme)
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.95,
                        end: 1.0,
                      ).animate(_scaleAnimation),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const Spacer(flex: 1),
                            _buildHeader(theme),
                            const SizedBox(height: 40),
                            AnimatedBuilder(
                              animation: _shakeAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(_shakeAnimation.value, 0),
                                  child: _buildPinDots(theme),
                                );
                              },
                            ),
                            if (_isPinError) _buildErrorText(theme),
                            const Spacer(flex: 2),
                            _buildPinKeyboard(theme),
                            const SizedBox(height: 24),
                            _buildFooterActions(theme),
                            const Spacer(flex: 1),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Pintar X',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.white;
    
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.lock_outline,
            size: 48,
            color: textColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Pintar X',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Masukkan PIN untuk melanjutkan',
          style: TextStyle(
            fontSize: 16,
            color: textColor.withOpacity(0.9),
          ),
        ),
        if (_failedAttempts > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Percobaan: $_failedAttempts/$_maxAttempts',
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPinDots(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: index < _pinInput.length ? 20 : 16,
          height: index < _pinInput.length ? 20 : 16,
          decoration: BoxDecoration(
            color: _isPinError
                ? Colors.red.shade300
                : (index < _pinInput.length 
                    ? Colors.white 
                    : Colors.white.withOpacity(0.3)),
            shape: BoxShape.circle,
            boxShadow: index < _pinInput.length
                ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildErrorText(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: AnimatedOpacity(
        opacity: _isPinError ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'PIN salah, coba lagi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinKeyboard(ThemeData theme) {
    return Column(
      children: [
        _buildKeyboardRow(['1', '2', '3'], theme),
        const SizedBox(height: 16),
        _buildKeyboardRow(['4', '5', '6'], theme),
        const SizedBox(height: 16),
        _buildKeyboardRow(['7', '8', '9'], theme),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isBiometricEnabled ? _buildBiometricButton(theme) : const SizedBox(width: 72),
            const SizedBox(width: 16),
            _buildNumberButton('0', theme),
            const SizedBox(width: 16),
            _buildDeleteButton(theme),
          ],
        ),
      ],
    );
  }

  Widget _buildKeyboardRow(List<String> numbers, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: numbers.map((num) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _buildNumberButton(num, theme),
        );
      }).toList(),
    );
  }

  Widget _buildNumberButton(String number, ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onPinInput(number),
        borderRadius: BorderRadius.circular(36),
        splashColor: Colors.white.withOpacity(0.3),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pinInput.isNotEmpty ? _onPinDelete : null,
        borderRadius: BorderRadius.circular(36),
        splashColor: Colors.white.withOpacity(0.3),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _pinInput.isNotEmpty 
                  ? Colors.white.withOpacity(0.5)
                  : Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              size: 24,
              color: _pinInput.isNotEmpty
                  ? Colors.white
                  : Colors.white.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricButton(ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _tryBiometricAuth,
        borderRadius: BorderRadius.circular(36),
        splashColor: Colors.white.withOpacity(0.3),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.fingerprint,
              size: 32,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterActions(ThemeData theme) {
    return TextButton(
      onPressed: _handleLogout,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: const Text(
        'Logout',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}