import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'terms_and_conditions_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/devspace_logo.dart';

enum _AuthMode { signIn, signUp }

class LoginScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  final bool startInSignUp;
  final bool closeOnSuccess;

  const LoginScreen({
    super.key,
    required this.onSuccess,
    this.startInSignUp = false,
    this.closeOnSuccess = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  _AuthMode _mode = _AuthMode.signIn;
  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;
  bool _otpSent = false;

  bool get _isSignUp => _mode == _AuthMode.signUp;

  @override
  void initState() {
    super.initState();
    _mode = widget.startInSignUp ? _AuthMode.signUp : _AuthMode.signIn;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submitEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = _isSignUp
        ? await AuthService.instance.signUpWithEmail(
            name: name,
            email: email,
            password: password,
          )
        : await AuthService.instance.signInWithEmail(
            email: email,
            password: password,
          );

    if (!mounted) return;

    if (result.success) {
      if (widget.closeOnSuccess && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      widget.onSuccess();
      return;
    }

    setState(() {
      _loading = false;
      _error = result.error;
    });
  }

  Future<void> _sendPhoneOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty || !phone.startsWith('+')) {
      setState(() {
        _error = 'Enter phone number with country code, for example +919876543210.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await AuthService.instance.sendPhoneOtp(phone);
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result.error != null) {
        _error = result.error;
      } else {
        _otpSent = true;
      }
    });

    if (result.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'OTP sent.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _verifyPhoneOtp() async {
    final phone = _phoneCtrl.text.trim();
    final otp = _otpCtrl.text.trim();
    if (otp.length < 4) {
      setState(() => _error = 'Enter the OTP sent to your phone.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await AuthService.instance.verifyPhoneOtp(
      phone: phone,
      otp: otp,
    );
    if (!mounted) return;

    setState(() => _loading = false);

    if (result.success) {
      if (widget.closeOnSuccess && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      widget.onSuccess();
    } else {
      setState(() => _error = result.error);
    }
  }

  void _switchMode(_AuthMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _error = null;
      _otpSent = false;
      _otpCtrl.clear();
    });
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFFFCFBFA),
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    // Force a light theme context for the login screen to keep it consistent
    // with the light auth_intro_screen, regardless of the system theme.
    return Theme(
      data: AppTheme.light.copyWith(
        inputDecorationTheme: AppTheme.light.inputDecorationTheme.copyWith(
          fillColor: const Color(0xFFF8FAFC), // Slate-50
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFF5E00), width: 1.8),
          ),
          hintStyle: GoogleFonts.spaceGrotesk(
            color: const Color(0xFF94A3B8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFFFF5E00),
          selectionColor: Color(0x33FF5E00),
          selectionHandleColor: Color(0xFFFF5E00),
        ),
      ),
      child: Builder(
        builder: (context) {
          final size = MediaQuery.sizeOf(context);
          
          // Use the warm, premium onboarding palette
          const bg = Color(0xFFFCFBFA);
          const bg2 = Color(0xFFF1F5F9); // slate-100 for segmented control background
          const cardBg = Colors.white;
          const text = Color(0xFF1E293B);    // Slate-800
          const text3 = Color(0xFF475569);   // Slate-600
          const text4 = Color(0xFF64748B);   // Slate-500
          const border = Color(0xFFE2E8F0);  // Slate-200

          return Scaffold(
            backgroundColor: bg,
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.1),
                  radius: 1.2,
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFFCFBFA),
                    Color(0xFFFAF8F5),
                  ],
                  stops: [0.0, 0.7, 1.0],
                ),
              ),
              child: SafeArea(
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: size.height * 0.04,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const DevSpaceLogo(
                                    size: 70,
                                    color: Color(0xFFFF5E00),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'DevSpace',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            color: text,
                                            letterSpacing: -0.9,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Your campus builder identity starts here.',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 13,
                                            color: text3,
                                            fontWeight: FontWeight.w500,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              Text(
                                _isSignUp
                                    ? 'Start your\nDev Journey'
                                    : 'Welcome\nBack',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  color: text,
                                  letterSpacing: -1.5,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _isSignUp
                                    ? 'Post, build, and connect with student developers.'
                                    : 'Sign in and get back to building.',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 15,
                                  color: text3,
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: bg2,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: border, width: 1),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _ModeButton(
                                        label: 'Sign in',
                                        active: !_isSignUp,
                                        onTap: () => _switchMode(_AuthMode.signIn),
                                      ),
                                    ),
                                    Expanded(
                                      child: _ModeButton(
                                        label: 'Create account',
                                        active: _isSignUp,
                                        onTap: () => _switchMode(_AuthMode.signUp),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),
                              Container(
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: border,
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF5E00).withValues(alpha: 0.05),
                                      blurRadius: 24,
                                      offset: const Offset(0, 16),
                                    ),
                                  ],
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.fromLTRB(
                                          20,
                                          18,
                                          20,
                                          16,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: border,
                                            ),
                                          ),
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              const Color(0xFFFF5E00).withValues(alpha: 0.06),
                                              const Color(0xFFF97316).withValues(
                                                alpha: 0.02,
                                              ),
                                            ],
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const DevSpaceLogo(
                                              size: 42,
                                              elevated: false,
                                              color: Color(0xFFFF5E00),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _isSignUp
                                                        ? 'Create your builder account'
                                                        : 'Continue as a builder',
                                                    style: GoogleFonts.spaceGrotesk(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w800,
                                                      color: text,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    _isSignUp
                                                        ? 'Use Google or email to join your college dev community.'
                                                        : 'Pick up where your last build session stopped.',
                                                    style: GoogleFonts.spaceGrotesk(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                      color: text3,
                                                      height: 1.35,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                                        child: _GoogleButton(
                                          loading: _loading,
                                          onPressed: () async {
                                            setState(() {
                                              _loading = true;
                                              _error = null;
                                            });
                                            final res = await AuthService.instance
                                                .signInWithGoogle();
                                            if (!mounted) return;
                                            setState(() => _loading = false);
                                            if (res.success) {
                                              if (widget.closeOnSuccess &&
                                                  Navigator.of(context).canPop()) {
                                                Navigator.of(context).pop();
                                              }
                                              widget.onSuccess();
                                            } else {
                                              setState(() => _error = res.error);
                                            }
                                          },
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.fromLTRB(20, 14, 20, 0),
                                        child: _PhoneOtpBox(
                                          loading: _loading,
                                          otpSent: _otpSent,
                                          phoneController: _phoneCtrl,
                                          otpController: _otpCtrl,
                                          onSendOtp: _sendPhoneOtp,
                                          onVerifyOtp: _verifyPhoneOtp,
                                          onChangePhone: () {
                                            setState(() {
                                              _otpSent = false;
                                              _otpCtrl.clear();
                                              _error = null;
                                            });
                                          },
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 16,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Divider(color: border),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                              ),
                                              child: Text(
                                                'or continue with email',
                                                style: TextStyle(
                                                  color: text4,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Divider(color: border),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            AnimatedSwitcher(
                                              duration:
                                                  const Duration(milliseconds: 300),
                                              transitionBuilder: (child, animation) {
                                                return FadeTransition(
                                                  opacity: animation,
                                                  child: SizeTransition(
                                                    sizeFactor: animation,
                                                    axisAlignment: -1,
                                                    child: child,
                                                  ),
                                                );
                                              },
                                              child: _isSignUp
                                                  ? Column(
                                                      key: const ValueKey('name-field'),
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      children: [
                                                        const _FieldLabel('NAME'),
                                                        const SizedBox(height: 8),
                                                        TextFormField(
                                                          controller: _nameCtrl,
                                                          textInputAction:
                                                              TextInputAction.next,
                                                          style: const TextStyle(
                                                            color: text,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                          decoration:
                                                              const InputDecoration(
                                                            hintText: 'Your full name',
                                                          ),
                                                          validator: (v) =>
                                                              (v == null || v.isEmpty)
                                                                  ? 'Name is required'
                                                                  : null,
                                                        ),
                                                        const SizedBox(height: 16),
                                                      ],
                                                    )
                                                  : const SizedBox.shrink(),
                                            ),
                                            const _FieldLabel('EMAIL'),
                                            const SizedBox(height: 8),
                                            TextFormField(
                                              controller: _emailCtrl,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              textInputAction: TextInputAction.next,
                                              style: const TextStyle(
                                                color: text,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              decoration: const InputDecoration(
                                                hintText: 'you@example.com',
                                              ),
                                              validator: (v) {
                                                if (v == null || v.isEmpty) {
                                                  return 'Email is required';
                                                }
                                                if (!v.contains('@')) {
                                                  return 'Invalid email format';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 16),
                                            const _FieldLabel('PASSWORD'),
                                            const SizedBox(height: 8),
                                            TextFormField(
                                              controller: _passwordCtrl,
                                              obscureText: _obscurePassword,
                                              onFieldSubmitted: (_) =>
                                                  _submitEmailAuth(),
                                              style: const TextStyle(
                                                color: text,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              decoration: InputDecoration(
                                                hintText: _isSignUp
                                                    ? 'Create a password'
                                                    : 'Enter your password',
                                                suffixIcon: GestureDetector(
                                                  onTap: () => setState(
                                                    () => _obscurePassword =
                                                        !_obscurePassword,
                                                  ),
                                                  child: Icon(
                                                    _obscurePassword
                                                        ? Icons.visibility_off_rounded
                                                        : Icons.visibility_rounded,
                                                    color: text4,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                              validator: (v) {
                                                if (v == null || v.isEmpty) {
                                                  return 'Password is required';
                                                }
                                                if (_isSignUp && v.length < 6) {
                                                  return 'Must be at least 6 characters';
                                                }
                                                return null;
                                              },
                                            ),
                                            if (!_isSignUp)
                                              Align(
                                                alignment: Alignment.centerRight,
                                                child: TextButton(
                                                  onPressed: _loading
                                                      ? null
                                                      : () async {
                                                          final email =
                                                              _emailCtrl.text.trim();
                                                          if (email.isEmpty) {
                                                            setState(() => _error =
                                                                'Please enter your email to reset password.');
                                                            return;
                                                          }

                                                          setState(() {
                                                            _loading = true;
                                                            _error = null;
                                                          });

                                                          final result =
                                                              await AuthService
                                                                  .instance
                                                                  .sendPasswordResetEmail(
                                                                      email);

                                                          if (!mounted) return;

                                                          setState(() {
                                                            _loading = false;
                                                            if (result.error !=
                                                                null) {
                                                              _error = result.error;
                                                            } else {
                                                              // Show success message as a snackbar since _error is for errors
                                                              ScaffoldMessenger.of(
                                                                      context)
                                                                  .showSnackBar(
                                                                SnackBar(
                                                                  content: Text(result
                                                                          .message ??
                                                                      'Reset link sent.'),
                                                                  backgroundColor:
                                                                      const Color(0xFFFF5E00),
                                                                ),
                                                              );
                                                            }
                                                          });
                                                        },
                                                  style: TextButton.styleFrom(
                                                    padding: EdgeInsets.zero,
                                                    minimumSize: const Size(0, 30),
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                  ),
                                                  child: Text(
                                                    'Forgot Password?',
                                                    style: GoogleFonts.spaceGrotesk(
                                                      color: const Color(0xFFFF5E00),
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            if (_error != null) ...[
                                              const SizedBox(height: 16),
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(14),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withValues(
                                                    alpha: 0.08,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color: Colors.red.withValues(
                                                      alpha: 0.25,
                                                    ),
                                                  ),
                                                ),
                                                child: Text(
                                                  _error!,
                                                  style: const TextStyle(
                                                    color: Colors.redAccent,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 24),
                                            SizedBox(
                                              width: double.infinity,
                                              height: 54,
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFFFF5E00),
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(99),
                                                  ),
                                                ),
                                                onPressed:
                                                    _loading ? null : _submitEmailAuth,
                                                child: _loading
                                                    ? const SizedBox(
                                                        height: 20,
                                                        width: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2.5,
                                                          color: Colors.white,
                                                        ),
                                                      )
                                                    : Text(
                                                        _isSignUp
                                                            ? 'Get Started'
                                                            : 'Sign In',
                                                        style: GoogleFonts.spaceGrotesk(
                                                          fontWeight: FontWeight.w800,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            if (_isSignUp) ...[
                                              const SizedBox(height: 16),
                                              Center(
                                                child: GestureDetector(
                                                  onTap: () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            const TermsAndConditionsScreen(),
                                                      ),
                                                    );
                                                  },
                                                  child: RichText(
                                                    textAlign: TextAlign.center,
                                                    text: TextSpan(
                                                      style: GoogleFonts.spaceGrotesk(
                                                        fontSize: 12,
                                                        color: text4,
                                                        height: 1.4,
                                                      ),
                                                      children: [
                                                        const TextSpan(
                                                          text:
                                                              'By signing up, you agree to our ',
                                                        ),
                                                        const TextSpan(
                                                          text: 'Terms & Conditions',
                                                          style: TextStyle(
                                                            color: Color(0xFFFF5E00),
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Center(
                                child: Text(
                                  _isSignUp
                                      ? 'Already have an account? '
                                      : "Don't have an account? ",
                                  style: const TextStyle(
                                    color: text3,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Center(
                                child: TextButton(
                                  onPressed: () => _switchMode(
                                    _isSignUp ? _AuthMode.signIn : _AuthMode.signUp,
                                  ),
                                  child: Text(
                                    _isSignUp ? 'Sign in' : 'Create account',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: const Color(0xFFFF5E00),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
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
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


class _GoogleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;

  const _GoogleButton({required this.loading, this.onPressed});

  @override
  Widget build(BuildContext context) {
    const text = Color(0xFF1E293B);
    const border = Color(0xFFE2E8F0);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: const BorderSide(
            color: border,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
              height: 20,
              errorBuilder: (c, e, s) => const Text(
                'G',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4285F4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneOtpBox extends StatelessWidget {
  final bool loading;
  final bool otpSent;
  final TextEditingController phoneController;
  final TextEditingController otpController;
  final VoidCallback onSendOtp;
  final VoidCallback onVerifyOtp;
  final VoidCallback onChangePhone;

  const _PhoneOtpBox({
    required this.loading,
    required this.otpSent,
    required this.phoneController,
    required this.otpController,
    required this.onSendOtp,
    required this.onVerifyOtp,
    required this.onChangePhone,
  });

  @override
  Widget build(BuildContext context) {
    const text = Color(0xFF1E293B);
    const text3 = Color(0xFF475569);
    const border = Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.phone_iphone_rounded, color: text3, size: 18),
              const SizedBox(width: 8),
              Text(
                'Continue with phone OTP',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phoneController,
            enabled: !loading && !otpSent,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            style: const TextStyle(color: text, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              hintText: '+91 phone number',
            ),
          ),
          if (otpSent) ...[
            const SizedBox(height: 10),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onVerifyOtp(),
              style: const TextStyle(color: text, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                hintText: 'Enter OTP',
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      loading ? null : (otpSent ? onVerifyOtp : onSendOtp),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: text,
                    side: const BorderSide(color: border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.white,
                  ),
                  child: Text(
                    otpSent ? 'Verify OTP' : 'Send OTP',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              if (otpSent) ...[
                const SizedBox(width: 10),
                TextButton(
                  onPressed: loading ? null : onChangePhone,
                  child: const Text('Change'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const text = Color(0xFF1E293B);
    const bg = Colors.white;
    const text3 = Color(0xFF64748B);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? text : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(
            color: active ? bg : text3,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF475569),
        letterSpacing: 1.2,
      ),
    );
  }
}
