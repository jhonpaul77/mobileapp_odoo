import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/secure_storage_service.dart';
import '../../services/biometric_service.dart';
import '../home/home_page.dart';

class SetupPinPage extends StatefulWidget {
  const SetupPinPage({super.key});

  @override
  State<SetupPinPage> createState() => _SetupPinPageState();
}

class _SetupPinPageState extends State<SetupPinPage> with TickerProviderStateMixin {
  final _storage = SecureStorageService();
  final _biometric = BiometricService();
  
  String _pinInput = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _isPinError = false;
  bool _isBiometricAvailable = false;
  
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
    
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
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    final available = await _biometric.isBiometricAvailable();
    setState(() => _isBiometricAvailable = available);
  }

  void _onPinInput(String number) {
    HapticFeedback.lightImpact();
    
    if (_isConfirming) {
      if (_confirmPin.length >= 6) return;
      
      setState(() {
        _confirmPin += number;
        _isPinError = false;
      });

      if (_confirmPin.length == 6) {
        Future.delayed(const Duration(milliseconds: 200), () {
          _verifyPinMatch();
        });
      }
    } else {
      if (_pinInput.length >= 6) return;
      
      setState(() {
        _pinInput += number;
        _isPinError = false;
      });

      if (_pinInput.length == 6) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            setState(() {
              _isConfirming = true;
            });
            _fadeController.reset();
            _fadeController.forward();
          }
        });
      }
    }
  }

  void _onPinDelete() {
    HapticFeedback.lightImpact();
    
    if (_isConfirming) {
      if (_confirmPin.isEmpty) return;
      setState(() {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        _isPinError = false;
      });
    } else {
      if (_pinInput.isEmpty) return;
      setState(() {
        _pinInput = _pinInput.substring(0, _pinInput.length - 1);
        _isPinError = false;
      });
    }
  }

  Future<void> _verifyPinMatch() async {
    if (_pinInput == _confirmPin) {
      // Save PIN using your existing service
      await _storage.savePin(_pinInput);
      
      if (!mounted) return;
      
      if (_isBiometricAvailable) {
        _showBiometricDialog();
      } else {
        _goToHome();
      }
    } else {
      setState(() {
        _isPinError = true;
        _pinInput = '';
        _confirmPin = '';
        _isConfirming = false;
      });
      
      HapticFeedback.heavyImpact();
      _shakeController.forward().then((_) {
        _shakeController.reset();
      });
    }
  }

  void _showBiometricDialog() async {
    final biometricType = await _biometric.getBiometricTypeString();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.fingerprint,
              color: Theme.of(context).primaryColor,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aktifkan $biometricType?',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: Text(
          'Anda dapat menggunakan $biometricType untuk membuka aplikasi lebih cepat',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _goToHome();
            },
            child: const Text(
              'Tidak',
              style: TextStyle(fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _biometric.setBiometricEnabled(true);
              if (!mounted) return;
              Navigator.pop(context);
              _goToHome();
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Aktifkan',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _goToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  _buildHeader(theme),
                  const SizedBox(height: 48),
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
                  const Spacer(flex: 3),
                  _buildPinKeyboard(theme),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.white;
    
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Container(
            key: ValueKey(_isConfirming),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isConfirming ? Icons.check_circle_outline : Icons.lock_outline,
              size: 48,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _isConfirming ? 'Konfirmasi PIN' : 'Buat PIN Baru',
            key: ValueKey(_isConfirming),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _isConfirming
                ? 'Masukkan PIN lagi untuk konfirmasi'
                : 'Buat PIN 6 digit untuk keamanan aplikasi',
            key: ValueKey(_isConfirming),
            style: TextStyle(
              fontSize: 16,
              color: textColor.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildPinDots(ThemeData theme) {
    final currentLength = _isConfirming ? _confirmPin.length : _pinInput.length;
    final isDark = theme.brightness == Brightness.dark;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: index < currentLength ? 20 : 16,
          height: index < currentLength ? 20 : 16,
          decoration: BoxDecoration(
            color: _isPinError
                ? Colors.red.shade300
                : (index < currentLength 
                    ? Colors.white 
                    : Colors.white.withOpacity(0.3)),
            shape: BoxShape.circle,
            boxShadow: index < currentLength
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
            'PIN tidak cocok, coba lagi',
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
            const SizedBox(width: 72),
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
    final isDark = theme.brightness == Brightness.dark;
    
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
    final currentLength = _isConfirming ? _confirmPin.length : _pinInput.length;
    final isDark = theme.brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: currentLength > 0 ? _onPinDelete : null,
        borderRadius: BorderRadius.circular(36),
        splashColor: Colors.white.withOpacity(0.3),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: currentLength > 0 
                  ? Colors.white.withOpacity(0.5)
                  : Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              size: 24,
              color: currentLength > 0
                  ? Colors.white
                  : Colors.white.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }
}