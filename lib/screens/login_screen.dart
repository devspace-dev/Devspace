import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/colors.dart';
import '../core/theme/text.dart';
import '../core/widgets/ds_button.dart';
import '../core/widgets/ds_card.dart';
import '../core/widgets/glitch.dart';
import 'terms_and_conditions_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Ds.ink,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    const surfaceAlt = Color(0xFF1E2030);

    return Theme(
      data: AppTheme.dark.copyWith(
        scaffoldBackgroundColor: Ds.ink,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceAlt,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Ds.border, width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Ds.border, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Ds.aura, width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Ds.hot, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Ds.hot, width: 1.8),
          ),
          hintStyle: DsText.body.copyWith(
            color: Ds.muted,
            fontSize: 14,
          ),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Ds.aura,
          selectionColor: Color(0x33FFD23F),
          selectionHandleColor: Ds.aura,
        ),
      ),
      child: Scaffold(
        backgroundColor: Ds.ink,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Ds.ink,
            gradient: RadialGradient(
              center: Alignment(0.0, -0.3),
              radius: 1.3,
              colors: [
                Color(0xFF181A28),
                Ds.ink,
              ],
              stops: [0.0, 0.85],
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
                    vertical: MediaQuery.sizeOf(context).height * 0.03,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // App Wordmark Header
                          Row(
                            children: [
                              const Glitch(
                                mood: GlitchMood.idle,
                                size: 48,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'DEV',
                                          style: DsText.h2.copyWith(
                                            color: Ds.bone,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        Text(
                                          'SPACE',
                                          style: DsText.h2.copyWith(
                                            color: Ds.aura,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Your campus builder identity starts here.',
                                      style: DsText.caption.copyWith(
                                        color: Ds.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Screen Title
                          Text(
                            _isSignUp
                                ? 'Start your\nDev Journey'
                                : 'Welcome\nBack',
                            style: DsText.h1.copyWith(
                              fontSize: 38,
                              height: 1.05,
                              color: Ds.bone,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isSignUp
                                ? 'Post, build, and connect with student developers.'
                                : 'Sign in and get back to building.',
                            style: DsText.body.copyWith(
                              color: Ds.muted,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Mode Switcher (Sign in / Create account)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: surfaceAlt,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Ds.border, width: 1),
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
                          const SizedBox(height: 22),

                          // Main Auth Card
                          DsCard(
                            padding: EdgeInsets.zero,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Card Top Header
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 14,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: surfaceAlt,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        topRight: Radius.circular(10),
                                      ),
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Ds.border,
                                          width: 1.2,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Glitch(
                                          mood: GlitchMood.hype,
                                          size: 32,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _isSignUp
                                                    ? 'CREATE BUILDER ACCOUNT'
                                                    : 'CONTINUE AS BUILDER',
                                                style: DsText.label.copyWith(
                                                  color: Ds.bone,
                                                  fontSize: 12,
                                                  letterSpacing: 1.0,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _isSignUp
                                                    ? 'Use Google or email to join your campus devs.'
                                                    : 'Pick up where your last build session stopped.',
                                                style: DsText.caption.copyWith(
                                                  color: Ds.muted,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Google Button
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                                    child: _GoogleButton(
                                      loading: _loading,
                                      onPressed: () async {
                                        setState(() {
                                          _loading = true;
                                          _error = null;
                                        });
                                        final nav = Navigator.of(context);
                                        final res = await AuthService.instance
                                            .signInWithGoogle();
                                        if (!mounted) return;
                                        setState(() => _loading = false);
                                        if (res.success) {
                                          if (widget.closeOnSuccess &&
                                              nav.canPop()) {
                                            nav.pop();
                                          }
                                          widget.onSuccess();
                                        } else if (res.error != null &&
                                            !res.error!
                                                .toLowerCase()
                                                .contains('cancelled')) {
                                          setState(() => _error = res.error);
                                        }
                                      },
                                    ),
                                  ),

                                  // Divider
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        const Expanded(
                                          child: Divider(color: Ds.border),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Text(
                                            'OR CONTINUE WITH EMAIL',
                                            style: DsText.label.copyWith(
                                              color: Ds.muted,
                                              fontSize: 10,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ),
                                        const Expanded(
                                          child: Divider(color: Ds.border),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Form Fields
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 250),
                                          child: _isSignUp
                                              ? Column(
                                                  key: const ValueKey('name-field'),
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const _FieldLabel('NAME'),
                                                    const SizedBox(height: 6),
                                                    TextFormField(
                                                      controller: _nameCtrl,
                                                      textInputAction:
                                                          TextInputAction.next,
                                                      style: DsText.body.copyWith(
                                                        color: Ds.bone,
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
                                                    const SizedBox(height: 14),
                                                  ],
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                        const _FieldLabel('EMAIL'),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _emailCtrl,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          style: DsText.body.copyWith(
                                            color: Ds.bone,
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
                                        const SizedBox(height: 14),
                                        const _FieldLabel('PASSWORD'),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _passwordCtrl,
                                          obscureText: _obscurePassword,
                                          onFieldSubmitted: (_) =>
                                              _submitEmailAuth(),
                                          style: DsText.body.copyWith(
                                            color: Ds.bone,
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
                                                color: Ds.muted,
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
                                            child: Padding(
                                              padding: const EdgeInsets.only(top: 4),
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

                                                        final messenger =
                                                            ScaffoldMessenger.of(
                                                                context);
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
                                                            messenger.showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                    result.message ??
                                                                        'Reset link sent.',
                                                                    style: DsText
                                                                        .body
                                                                        .copyWith(
                                                                      color: Ds
                                                                          .onAura,
                                                                    )),
                                                                backgroundColor:
                                                                    Ds.aura,
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
                                                  style: DsText.caption.copyWith(
                                                    color: Ds.aura,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (_error != null) ...[
                                          const SizedBox(height: 14),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Ds.hot.withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Ds.hot.withValues(alpha: 0.4),
                                              ),
                                            ),
                                            child: Text(
                                              _error!,
                                              style: DsText.caption.copyWith(
                                                color: Ds.hot,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 20),
                                        DsButton(
                                          label: _isSignUp
                                              ? 'Get Started'
                                              : 'Sign In',
                                          kind: DsButtonKind.aura,
                                          loading: _loading,
                                          uppercase: false,
                                          onPressed: _loading
                                              ? null
                                              : _submitEmailAuth,
                                        ),
                                        if (_isSignUp) ...[
                                          const SizedBox(height: 14),
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
                                                  style: DsText.caption.copyWith(
                                                    color: Ds.muted,
                                                    height: 1.4,
                                                    fontSize: 12,
                                                  ),
                                                  children: const [
                                                    TextSpan(
                                                      text:
                                                          'By signing up, you agree to our ',
                                                    ),
                                                    TextSpan(
                                                      text: 'Terms & Conditions',
                                                      style: TextStyle(
                                                        color: Ds.aura,
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
                          const SizedBox(height: 22),

                          // Bottom Switcher
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  _isSignUp
                                      ? 'Already have an account? '
                                      : "Don't have an account? ",
                                  style: DsText.caption.copyWith(
                                    color: Ds.muted,
                                    fontSize: 13,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _switchMode(
                                    _isSignUp
                                        ? _AuthMode.signIn
                                        : _AuthMode.signUp,
                                  ),
                                  child: Text(
                                    _isSignUp ? 'Sign in' : 'Create account',
                                    style: DsText.caption.copyWith(
                                      color: Ds.aura,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
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
    const surfaceAlt = Color(0xFF1E2030);

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Ds.bone,
          side: const BorderSide(
            color: Ds.border,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: surfaceAlt,
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
              height: 18,
              errorBuilder: (c, e, s) => Text(
                'G',
                style: GoogleFonts.rubik(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Ds.aura,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Continue with Google',
              style: DsText.label.copyWith(
                color: Ds.bone,
                fontSize: 13,
                letterSpacing: 0.5,
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? Ds.aura : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: DsText.label.copyWith(
            color: active ? Ds.onAura : Ds.muted,
            fontSize: 12,
            letterSpacing: 0.8,
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
      style: DsText.label.copyWith(
        fontSize: 11,
        color: Ds.muted,
        letterSpacing: 1.2,
      ),
    );
  }
}
