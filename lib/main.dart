import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'models/user_model.dart';
import 'providers/auth_provider.dart';
import 'providers/posts_provider.dart';
import 'providers/questions_provider.dart';
import 'providers/users_provider.dart';
import 'providers/aura_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/engagement_provider.dart';
import 'providers/messages_provider.dart';
import 'providers/premium_provider.dart';
import 'providers/practice_provider.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_intro_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';
import 'utils/runtime_config.dart';
import 'utils/secure_local_storage.dart';
import 'package:safe_device/safe_device.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  ThemeMode bootThemeMode = ThemeMode.system;
  try {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString('theme_mode');
    if (modeStr != null) {
      bootThemeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == modeStr,
        orElse: () => ThemeMode.system,
      );
    }
  } catch (e) {
    debugPrint('Error preloading theme mode: $e');
  }

  runApp(AppBootstrapper(initialThemeMode: bootThemeMode));
}

class AppBootstrapper extends StatefulWidget {
  final ThemeMode initialThemeMode;
  const AppBootstrapper({super.key, required this.initialThemeMode});

  @override
  State<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<AppBootstrapper> {
  bool _initialized = false;
  String? _error;
  bool _isCompromised = false;
  late ThemeMode _bootThemeMode;

  @override
  void initState() {
    super.initState();
    _bootThemeMode = widget.initialThemeMode;
    _initApp();
  }

  bool get _isBootThemeDark {
    if (_bootThemeMode == ThemeMode.dark) return true;
    if (_bootThemeMode == ThemeMode.light) return false;
    return PlatformDispatcher.instance.platformBrightness == Brightness.dark;
  }

  Future<void> _initApp() async {
    bool firebaseInitialized = false;
    bool isCompromisedLocal = false;
    String? bootstrapErrorLocal;

    try {
      await Future.wait([
        // Task A: Firebase Initialization
        Firebase.initializeApp().timeout(const Duration(seconds: 5)).then((_) {
          firebaseInitialized = true;
          FlutterError.onError =
              FirebaseCrashlytics.instance.recordFlutterFatalError;
          PlatformDispatcher.instance.onError = (error, stack) {
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
            return true;
          };
        }).catchError((e) {
          if (kDebugMode) debugPrint('Firebase initialization failed: $e');
        }),

        // Task B: Security check for compromised device
        Future(() async {
          try {
            final isJailBroken = await SafeDevice.isJailBroken;
            final isRealDevice = await SafeDevice.isRealDevice;
            if (kReleaseMode) {
              isCompromisedLocal = isJailBroken || !isRealDevice;
            } else {
              isCompromisedLocal = isJailBroken;
            }
          } catch (e) {
            debugPrint('Security check failed to run: $e');
          }
        }),

        // Task C: Runtime config & Supabase Initialization
        Future(() async {
          try {
            final runtimeConfig = await RuntimeConfig.load();
            final supabaseUrl = runtimeConfig.supabaseUrl;
            final supabaseAnonKey = runtimeConfig.supabaseAnonKey;

            if (supabaseUrl == null ||
                supabaseUrl.isEmpty ||
                supabaseAnonKey == null ||
                supabaseAnonKey.isEmpty) {
              bootstrapErrorLocal =
                  'Missing Supabase runtime config. Run with SUPABASE_URL and SUPABASE_ANON_KEY using --dart-define.';
            } else if (!supabaseUrl.startsWith('https://')) {
              bootstrapErrorLocal =
                  'Invalid Supabase runtime config. SUPABASE_URL must use HTTPS in production-ready builds.';
            } else {
              await Supabase.initialize(
                url: supabaseUrl,
                anonKey: supabaseAnonKey,
                authOptions: const FlutterAuthClientOptions(
                  authFlowType: AuthFlowType.pkce,
                  localStorage: SecureLocalStorage(),
                ),
              ).timeout(const Duration(seconds: 5));

              await AuthService.instance
                  .init()
                  .timeout(const Duration(seconds: 5));
            }
          } catch (e) {
            bootstrapErrorLocal = 'Supabase initialization failed: $e';
          }
        }),

        // Task D: Enforce minimum display time for splash logo/shimmer animations
        Future.delayed(const Duration(milliseconds: 1600)),
      ]);

      if (firebaseInitialized && bootstrapErrorLocal == null) {
        AnalyticsService.instance
            .logAppOpen()
            .timeout(const Duration(seconds: 3))
            .catchError((_) {});
      }
    } catch (e) {
      bootstrapErrorLocal ??= 'Initialization failed: $e';
    }

    if (mounted) {
      setState(() {
        _isCompromised = isCompromisedLocal;
        _error = bootstrapErrorLocal;
        _initialized = true;
      });
    }
  }

  void _retryInit() {
    setState(() {
      _initialized = false;
      _error = null;
    });
    _initApp();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: !_initialized
          ? MaterialApp(
              key: const ValueKey('splash'),
              debugShowCheckedModeBanner: false,
              theme: _isBootThemeDark ? AppTheme.dark : AppTheme.light,
              home: const SplashScreen(),
            )
          : (_error == null
              ? DevSpaceRoot(
                  key: const ValueKey('app'),
                  isCompromised: _isCompromised,
                  initialThemeMode: _bootThemeMode,
                )
              : DevSpaceSetupApp(
                  key: const ValueKey('setup'),
                  error: _error!,
                  onRetry: _retryInit,
                )),
    );
  }
}

class DevSpaceRoot extends StatelessWidget {
  final bool isCompromised;
  final ThemeMode initialThemeMode;
  const DevSpaceRoot({
    super.key,
    required this.isCompromised,
    required this.initialThemeMode,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => ThemeProvider(initialMode: initialThemeMode)),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PostsProvider()),
        ChangeNotifierProvider(create: (_) => QuestionsProvider()),
        ChangeNotifierProvider(create: (_) => UsersProvider()),
        ChangeNotifierProvider(create: (_) => AuraProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => EngagementProvider()),
        ChangeNotifierProvider(create: (_) => MessagesProvider()),
        ChangeNotifierProvider(create: (_) => PremiumProvider()),
        ChangeNotifierProvider(create: (_) => PracticeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'DevSpace',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            navigatorObservers: [AnalyticsService.instance.observer],
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: MediaQuery.of(context).textScaler.clamp(
                        minScaleFactor: 0.85,
                        maxScaleFactor: 1.15,
                      ),
                ),
                child: child!,
              );
            },
            home: _Root(isCompromised: isCompromised),
          );
        },
      ),
    );
  }
}

class DevSpaceSetupApp extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const DevSpaceSetupApp({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevSpace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      navigatorObservers: [AnalyticsService.instance.observer],
      home: _SetupRequiredScreen(error: error, onRetry: onRetry),
    );
  }
}

class _Root extends StatefulWidget {
  final bool isCompromised;
  const _Root({required this.isCompromised});
  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  String? _notificationsInitializedForUid;

  @override
  Widget build(BuildContext context) {
    return _buildCurrentScreen();
  }

  Widget _buildCurrentScreen() {
    return StreamBuilder<UserModel?>(
      key: const ValueKey('auth-gate'),
      stream: AuthService.instance.authStateChanges,
      initialData: AuthService.instance.currentUser,
      builder: (context, snap) {
        final user = snap.data ?? AuthService.instance.currentUser;

        if (widget.isCompromised) {
          return const _SecurityCompromisedScreen();
        }

        if (user == null) {
          return AuthIntroScreen(
            key: const ValueKey('login'),
            onSuccess: () {},
          );
        }

        if (_notificationsInitializedForUid != user.id) {
          _notificationsInitializedForUid = user.id;
          NotificationService.instance.init(user.id);
        }

        if (!user.profileCompleted) {
          return const ProfileSetupScreen(
            key: ValueKey('onboarding'),
            mode: ProfileSetupMode.onboarding,
          );
        }

        return const DevSpaceApp(key: ValueKey('app'));
      },
    );
  }
}

class _SetupRequiredScreen extends StatefulWidget {
  final String error;
  final VoidCallback onRetry;

  const _SetupRequiredScreen({
    required this.error,
    required this.onRetry,
  });

  @override
  State<_SetupRequiredScreen> createState() => _SetupRequiredScreenState();
}

class _SetupRequiredScreenState extends State<_SetupRequiredScreen> {
  bool _showDetails = false;

  bool get _isNetworkError {
    final err = widget.error.toLowerCase();
    if (err.contains('missing supabase') ||
        err.contains('invalid supabase') ||
        err.contains('--dart-define')) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isNetworkError) {
      return _buildNetworkErrorView(context);
    }
    return _buildSetupRequiredView(context);
  }

  Widget _buildNetworkErrorView(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.08),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 32,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    color: AppColors.primary,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Connection Failed',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "We couldn't connect to DevSpace. Please check your internet connection and try again.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: AppColors.text2Dark,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 280),
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: AppColors.premiumGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: widget.onRetry,
                    child: Text(
                      'Try Again',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showDetails = !_showDetails;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Technical details',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text3Dark,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _showDetails
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AppColors.text3Dark,
                      ),
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: _showDetails
                      ? Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF121214),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF1F1F22)),
                          ),
                          child: SelectableText(
                            widget.error,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              height: 1.4,
                              color: AppColors.text2Dark,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSetupRequiredView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.bg2For(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderFor(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DevSpace setup required',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textFor(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This build needs explicit Supabase runtime values before it can start.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.text2For(context),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _SetupCodeBlock(
                      lines: [
                        'flutter run ',
                        '  --dart-define=SUPABASE_URL=your-project-url ',
                        '  --dart-define=SUPABASE_ANON_KEY=your-anon-key',
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Current error',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: AppColors.text3For(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.error,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textFor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupCodeBlock extends StatelessWidget {
  final List<String> lines;

  const _SetupCodeBlock({
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Text(
        lines.join('\n'),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          height: 1.5,
          color: AppColors.textFor(context),
        ),
      ),
    );
  }
}

class _SecurityCompromisedScreen extends StatelessWidget {
  const _SecurityCompromisedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security_rounded,
                  color: Colors.redAccent, size: 64),
              const SizedBox(height: 24),
              const Text(
                'Security Check Failed',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'DevSpace cannot run on this device because it appears to be rooted, jailbroken, or running in an unsafe environment. This is to protect your developer identity and aura points.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
