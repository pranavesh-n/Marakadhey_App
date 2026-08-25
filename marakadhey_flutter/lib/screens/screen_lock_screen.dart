import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../services/security_service.dart';
import '../services/auth_service.dart';

class ScreenLockScreen extends StatefulWidget {
  const ScreenLockScreen({super.key});

  @override
  State<ScreenLockScreen> createState() => _ScreenLockScreenState();
}

class _ScreenLockScreenState extends State<ScreenLockScreen> with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  String? _errorMessage;
  int _failedAttempts = 0;
  bool _showResetConfirmation = false;
  bool _isLockedOut = false;
  bool _isResetting = false;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyPress(String digit) {
    if (_isLockedOut || _showResetConfirmation || _isResetting) return;
    if (_enteredPin.length < 4) {
      HapticFeedback.lightImpact();
      setState(() {
        _enteredPin += digit;
        _errorMessage = null;
      });

      if (_enteredPin.length == 4) {
        Future.delayed(const Duration(milliseconds: 100), _validatePin);
      }
    }
  }

  void _onBackspace() {
    if (_isLockedOut || _showResetConfirmation || _isResetting) return;
    if (_enteredPin.isNotEmpty) {
      HapticFeedback.selectionClick();
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _handleResetAndLogout() async {
    setState(() => _isResetting = true);
    final security = context.read<SecurityService>();
    final auth = context.read<AuthService>();
    await security.disablePin();
    await auth.logout();
    if (mounted) {
      setState(() {
        _isResetting = false;
        _showResetConfirmation = false;
        _isLockedOut = false;
      });
    }
  }

  void _validatePin() {
    final security = context.read<SecurityService>();
    final isCorrect = security.verifyAndUnlock(_enteredPin);

    if (isCorrect) {
      HapticFeedback.mediumImpact();
      setState(() {
        _enteredPin = '';
        _errorMessage = null;
        _failedAttempts = 0;
      });
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0.0);
      final nextAttempts = _failedAttempts + 1;

      if (nextAttempts >= 4) {
        setState(() {
          _failedAttempts = nextAttempts;
          _isLockedOut = true;
          _enteredPin = '';
          _errorMessage = null;
        });
      } else {
        final remaining = 4 - nextAttempts;
        setState(() {
          _failedAttempts = nextAttempts;
          _errorMessage = 'Incorrect PIN ($remaining attempt${remaining == 1 ? '' : 's'} remaining)';
          _enteredPin = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Original Crisp Marakadhey Logo Badge (matching reference)
                        Container(
                          width: 72,
                          height: 72,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF334155),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Welcome Header
                        const Text(
                          'Welcome Back, Opportunity Seeker 👋',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Subtitle
                        const Text(
                          'Enter your 4-digit PIN to unlock Marakadhey',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 4-Digit PIN Indicators with Shake Animation
                        AnimatedBuilder(
                          animation: _shakeController,
                          builder: (context, child) {
                            final double offset = 12 * (1 - _shakeController.value) *
                                (1 - _shakeController.value) *
                                (_shakeController.value < 0.25 || (_shakeController.value > 0.5 && _shakeController.value < 0.75) ? 1 : -1);
                            return Transform.translate(
                              offset: Offset(offset, 0),
                              child: child,
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              final isFilled = index < _enteredPin.length;
                              final isError = _errorMessage != null;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.symmetric(horizontal: 10),
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isFilled
                                      ? (isError ? const Color(0xFFEF4444) : AppColors.primary)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isFilled
                                        ? (isError ? const Color(0xFFEF4444) : AppColors.primary)
                                        : const Color(0xFF334155),
                                    width: 2.2,
                                  ),
                                  boxShadow: isFilled
                                      ? [
                                          BoxShadow(
                                            color: (isError ? const Color(0xFFEF4444) : AppColors.primary).withValues(alpha: 0.55),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          )
                                        ]
                                      : [],
                                ),
                              );
                            }),
                          ),
                        ),

                        // Error message if any
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ] else
                          const SizedBox(height: 24),

                        // Numeric 3x4 Keypad with Circular Round Buttons
                        _buildKeypadRow(['1', '2', '3']),
                        const SizedBox(height: 14),
                        _buildKeypadRow(['4', '5', '6']),
                        const SizedBox(height: 14),
                        _buildKeypadRow(['7', '8', '9']),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildIconButton(
                              Icons.lock_outline_rounded,
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setState(() => _showResetConfirmation = true);
                              },
                            ),
                            _buildKeypadButton('0'),
                            _buildIconButton(
                              Icons.backspace_outlined,
                              onPressed: _onBackspace,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Forgot PIN / Reset Link with Opaque Tap Target
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _showResetConfirmation = true);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: const TextSpan(
                                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5),
                                  children: [
                                    TextSpan(text: 'Forgot PIN? Enter incorrectly 4 times or\n'),
                                    TextSpan(
                                      text: 'tap here to reset via sign-in',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
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
                  ),
                ),
              ),

              // Modal Dialog Overlay: Forgot PIN Confirmation
              if (_showResetConfirmation)
                _buildModalOverlay(
                  title: 'Reset PIN via Sign-In?',
                  icon: Icons.lock_reset_rounded,
                  iconColor: AppColors.primary,
                  message: 'To reset your 4-digit PIN, your active session will be signed out so you can sign in with your email or Google account.',
                  primaryButtonText: 'Reset via Sign-In',
                  onPrimaryPressed: _handleResetAndLogout,
                  secondaryButtonText: 'Cancel',
                  onSecondaryPressed: () => setState(() => _showResetConfirmation = false),
                ),

              // Modal Dialog Overlay: 4 Failed Attempts Lockout
              if (_isLockedOut)
                _buildModalOverlay(
                  title: 'PIN Lockout (4 Attempts)',
                  icon: Icons.shield_outlined,
                  iconColor: const Color(0xFFEF4444),
                  message: 'You have entered an incorrect PIN 4 times. For your security, your session has been signed out. Please sign in again to set a new PIN.',
                  primaryButtonText: 'Sign In to Reset PIN',
                  onPrimaryPressed: _handleResetAndLogout,
                ),

              // Loading indicator while resetting
              if (_isResetting)
                Container(
                  color: Colors.black.withValues(alpha: 0.6),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalOverlay({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String message,
    required String primaryButtonText,
    required VoidCallback onPrimaryPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
  }) {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF334155), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.15),
                ),
                child: Icon(icon, color: iconColor, size: 30),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (secondaryButtonText != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF94A3B8),
                          side: const BorderSide(color: Color(0xFF475569)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: onSecondaryPressed,
                        child: Text(secondaryButtonText),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: onPrimaryPressed,
                      child: Text(
                        primaryButtonText,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildKeypadButton(d)).toList(),
    );
  }

  Widget _buildKeypadButton(String digit) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onKeyPress(digit),
        borderRadius: BorderRadius.circular(36),
        splashColor: AppColors.primary.withValues(alpha: 0.35),
        highlightColor: AppColors.primary.withValues(alpha: 0.15),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1E293B),
            border: Border.all(color: const Color(0xFF334155), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, {required VoidCallback onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(36),
        splashColor: Colors.white24,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1E293B).withValues(alpha: 0.6),
            border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.6), width: 1.2),
          ),
          child: Center(
            child: Icon(icon, size: 22, color: const Color(0xFF94A3B8)),
          ),
        ),
      ),
    );
  }
}
