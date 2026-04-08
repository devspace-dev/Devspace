import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
import 'screens/profile_setup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_intro_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp();
    firebaseInitialized = true;
    
    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    
    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  String? bootstrapError;

  const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    bootstrapError =
        'Missing Supabase runtime config. Run with SUPABASE_URL and SUPABASE_ANON_KEY using --dart-define.';
  } else if (!supabaseUrl.startsWith('https://')) {
    bootstrapError =
        'Invalid Supabase runtime config. SUPABASE_URL must use HTTPS in production-ready builds.';
  } else {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      await AuthService.instance.init();
      if (firebaseInitialized) {
        await AnalyticsService.instance.logAppOpen();
      }
    } catch (e) {
      bootstrapError = 'Supabase initialization failed: $e';
      debugPrint(bootstrapError);
    }
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Set system UI overlay style for initial splash screen appearance
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    bootstrapError == null
        ? const DevSpaceRoot()
        : DevSpaceSetupApp(error: bootstrapError),
  );
}

class DevSpaceRoot extends StatelessWidget {
  const DevSpaceRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PostsProvider()),
        ChangeNotifierProvider(create: (_) => QuestionsProvider()),
        ChangeNotifierProvider(create: (_) => UsersProvider()),
        ChangeNotifierProvider(create: (_) => AuraProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => EngagementProvider()),
        ChangeNotifierProvider(create: (_) => MessagesProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'DevSpace',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            navigatorObservers: [AnalyticsService.instance.observer],
            home: const _Root(),
          );
        },
      ),
    );
  }
}

class DevSpaceSetupApp extends StatelessWidget {
  final String error;

  const DevSpaceSetupApp({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevSpace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      navigatorObservers: [AnalyticsService.instance.observer],
      home: _SetupRequiredScreen(error: error),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();
  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _showSplash = true;
  String? _notificationsInitializedForUid;
  String? _profilePromptShownForUid;
  bool _showingProfilePrompt = false;

  void _maybePromptProfileCompletion(UserModel user) {
    if (user.profileCompleted ||
        _profilePromptShownForUid == user.id ||
        _showingProfilePrompt) {
      return;
    }

    _profilePromptShownForUid = user.id;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _showingProfilePrompt = true;

      final openSetup = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheetContext) {
          final bgColor = AppColors.bg2For(sheetContext);
          final elevatedBgColor = AppColors.bg3For(sheetContext);
          final textColor = AppColors.textFor(sheetContext);
          final secondaryTextColor = AppColors.text2For(sheetContext);
          final tertiaryTextColor = AppColors.text3For(sheetContext);
          final borderColor = AppColors.borderFor(sheetContext);

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 18,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border2For(sheetContext),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: elevatedBgColor,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        '2 minute setup',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: tertiaryTextColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Complete your profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Make your account look real before you start posting. A clear profile helps people trust, follow, and reply to you faster.',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: elevatedBgColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: const [
                          _ProfilePromptPoint(
                            icon: Icons.person_outline_rounded,
                            title: 'Identity',
                            subtitle: 'Name, handle, year, and branch',
                          ),
                          SizedBox(height: 12),
                          _ProfilePromptPoint(
                            icon: Icons.handyman_outlined,
                            title: 'Builder stack',
                            subtitle: 'Skills and what you are building',
                          ),
                          SizedBox(height: 12),
                          _ProfilePromptPoint(
                            icon: Icons.verified_outlined,
                            title: 'Better discovery',
                            subtitle: 'Makes your profile easier to trust',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext, false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Later'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(sheetContext, true),
                            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                            label: const Text('Complete profile'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
        },
      );

      _showingProfilePrompt = false;

      if (!mounted || openSetup != true) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ProfileSetupScreen(
            mode: ProfileSetupMode.onboarding,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 1000),
      reverseDuration: const Duration(milliseconds: 800),
      switchInCurve: Curves.easeInOutQuart,
      switchOutCurve: Curves.easeInOutQuart,
      transitionBuilder: (child, animation) {
        final isApp = child is DevSpaceApp;
        
        // Premium zoom-in effect for the main app entry
        final scale = Tween<double>(
          begin: isApp ? 1.05 : 0.96,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutQuart,
        ));

        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: scale,
            child: child,
          ),
        );
      },
      child: _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    if (_showSplash) {
      return SplashScreen(
        key: const ValueKey('splash'),
        onDone: () {
          if (mounted) setState(() => _showSplash = false);
        },
      );
    }

    return StreamBuilder<UserModel?>(
      key: const ValueKey('auth-gate'),
      stream: AuthService.instance.authStateChanges,
      initialData: AuthService.instance.currentUser,
      builder: (context, snap) {
        final user = snap.data ?? AuthService.instance.currentUser;

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

        _maybePromptProfileCompletion(user);

        return const DevSpaceApp(key: ValueKey('app'));
      },
    );
  }
}

class _ProfilePromptPoint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ProfilePromptPoint({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textFor(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.text3For(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SetupRequiredScreen extends StatelessWidget {
  final String error;

  const _SetupRequiredScreen({
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
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
                      error,
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
