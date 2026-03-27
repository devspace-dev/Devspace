import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'models/user_model.dart';
import 'providers/auth_provider.dart';
import 'providers/posts_provider.dart';
import 'providers/users_provider.dart';
import 'providers/aura_provider.dart';
import 'providers/notifications_provider.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  } else {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      await AuthService.instance.init();
    } catch (e) {
      bootstrapError = 'Supabase initialization failed: $e';
      debugPrint(bootstrapError);
    }
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PostsProvider()),
        ChangeNotifierProvider(create: (_) => UsersProvider()),
        ChangeNotifierProvider(create: (_) => AuraProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
      ],
      child: MaterialApp(
        title: 'DevSpace',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _Root(),
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
        backgroundColor: AppColors.bg2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border2,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Complete your profile',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Good profiles make discovery, follows, and collaboration much better. Add your year, branch, stack, and what you are building.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.text2,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(sheetContext, false),
                          child: const Text('Later'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(sheetContext, true),
                          child: const Text('Complete profile'),
                        ),
                      ),
                    ],
                  ),
                ],
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
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(animation),
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
          return LoginScreen(
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

class _SetupRequiredScreen extends StatelessWidget {
  final String error;

  const _SetupRequiredScreen({
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.bg2,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DevSpace setup required',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This build needs explicit Supabase runtime values before it can start.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.text2,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _SetupCodeBlock(
                      lines: [
                        'flutter run \\',
                        '  --dart-define=SUPABASE_URL=your-project-url \\',
                        '  --dart-define=SUPABASE_ANON_KEY=your-anon-key',
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Current error',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: AppColors.text3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.text,
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
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        lines.join('\n'),
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          height: 1.5,
          color: AppColors.text,
        ),
      ),
    );
  }
}
