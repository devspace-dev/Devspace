import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';

enum _AuthMode { signIn, signUp }

class LoginScreen extends StatefulWidget {
  final VoidCallback onSuccess;

  const LoginScreen({super.key, required this.onSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  _AuthMode _mode = _AuthMode.signIn;
  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;

  bool get _isSignUp => _mode == _AuthMode.signUp;

  @override
  void initState() {
    super.initState();
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
      widget.onSuccess();
      return;
    }

    setState(() {
      _loading = false;
      _error = result.error;
    });
  }

  void _switchMode(_AuthMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _error = null;
    });
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // ── Decorative background glows ──────────────────────────────
          Positioned(
            top: -80,
            left: -80,
            child: _GlowBlob(
              color: AppColors.primary,
              size: 280,
              opacity: 0.22,
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: _GlowBlob(
              color: AppColors.indigo,
              size: 320,
              opacity: 0.18,
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: size.height * 0.04,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Logo mark ──────────────────────────────────
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 24,
                                spreadRadius: -4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '✳',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 28,
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Headline ───────────────────────────────────
                        Text(
                          _isSignUp
                              ? 'Start your\nDev Journey'
                              : 'Welcome\nBack',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
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
                            color: AppColors.text3,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Mode toggle ────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.bg2,
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: AppColors.border, width: 1),
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

                        // ── Form card ──────────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.bg2,
                            borderRadius: BorderRadius.circular(28),
                            border:
                                Border.all(color: AppColors.border, width: 1),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Google button (top of card)
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
                                        widget.onSuccess();
                                      } else {
                                        setState(() => _error = res.error);
                                      }
                                    },
                                  ),
                                ),

                                // Divider OR
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 16),
                                  child: Row(
                                    children: [
                                      const Expanded(
                                          child:
                                              Divider(color: AppColors.border)),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: Text(
                                          'or continue with email',
                                          style: TextStyle(
                                              color: AppColors.text4,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      const Expanded(
                                          child:
                                              Divider(color: AppColors.border)),
                                    ],
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      20, 0, 20, 20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Name field (sign up only)
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
                                                  _FieldLabel('NAME'),
                                                  const SizedBox(height: 8),
                                                  TextFormField(
                                                    controller: _nameCtrl,
                                                    textInputAction:
                                                        TextInputAction.next,
                                                    style: const TextStyle(
                                                        color: AppColors.text,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                    decoration:
                                                        const InputDecoration(
                                                      hintText:
                                                          'Your full name',
                                                    ),
                                                    validator: (v) =>
                                                        (v == null ||
                                                                v.isEmpty)
                                                            ? 'Name is required'
                                                            : null,
                                                  ),
                                                  const SizedBox(height: 16),
                                                ],
                                              )
                                            : const SizedBox.shrink(),
                                      ),

                                      _FieldLabel('EMAIL'),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _emailCtrl,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        style: const TextStyle(
                                            color: AppColors.text,
                                            fontWeight: FontWeight.w600),
                                        decoration: const InputDecoration(
                                          hintText: 'you@example.com',
                                        ),
                                        validator: (v) {
                                          if (v == null || v.isEmpty)
                                            return 'Email is required';
                                          if (!v.contains('@'))
                                            return 'Invalid email format';
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),

                                      _FieldLabel('PASSWORD'),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _passwordCtrl,
                                        obscureText: _obscurePassword,
                                        onFieldSubmitted: (_) =>
                                            _submitEmailAuth(),
                                        style: const TextStyle(
                                            color: AppColors.text,
                                            fontWeight: FontWeight.w600),
                                        decoration: InputDecoration(
                                          hintText: _isSignUp
                                              ? 'Create a password'
                                              : 'Enter your password',
                                          suffixIcon: GestureDetector(
                                            onTap: () => setState(() =>
                                                _obscurePassword =
                                                    !_obscurePassword),
                                            child: Icon(
                                              _obscurePassword
                                                  ? Icons
                                                      .visibility_off_rounded
                                                  : Icons.visibility_rounded,
                                              color: AppColors.text4,
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

                                      // Error message
                                      if (_error != null) ...[
                                        const SizedBox(height: 16),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: Colors.red
                                                .withValues(alpha: 0.08),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                              color: Colors.red
                                                  .withValues(alpha: 0.25),
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

                                      // CTA — black pill button (reference style)
                                      SizedBox(
                                        width: double.infinity,
                                        height: 54,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.text,
                                            foregroundColor: AppColors.bg,
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
                                                    color: AppColors.bg,
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
                                color: AppColors.text3, fontSize: 13),
                          ),
                        ),
                        Center(
                          child: TextButton(
                            onPressed: () => _switchMode(
                                _isSignUp ? _AuthMode.signIn : _AuthMode.signUp),
                            child: Text(
                              _isSignUp ? 'Sign in' : 'Create account',
                              style: GoogleFonts.spaceGrotesk(
                                color: AppColors.primary,
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
        ],
      ),
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _GlowBlob({
    required this.color,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            Colors.transparent,
          ],
        ),
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
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.border2, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14),
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
                color: AppColors.text,
              ),
            ),
          ],
        ),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.text : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(
            color: active ? AppColors.bg : AppColors.text3,
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
        color: AppColors.text3,
        letterSpacing: 1.2,
      ),
    );
  }
}
